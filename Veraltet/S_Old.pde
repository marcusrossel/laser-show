final class S_Old implements Server {

  private Configuration configuration;
  private Arduino arduino;

  public S_Old(Configuration configuration, Arduino arduino) {
    this.configuration = configuration;
    this.arduino = arduino;
  }

  Float lowerBound()                            { return (Float) configuration.valueForTrait("Lower Frequency Bound"); }
  Float upperBound()                            { return (Float) configuration.valueForTrait("Upper Frequency Bound"); }
  private Float loudnessRecalibrationDuration() { return (Float) configuration.valueForTrait("Loudness Recalibration Duration"); }
  Float minimalTriggerThreshold()               { return (Float) configuration.valueForTrait("Minimal Trigger Threshold"); }
  private List<Integer> outputPins()            { return (List<Integer>) configuration.valueForTrait("Output Pins"); }
  Boolean usePatterns()                         { return (Boolean) configuration.valueForTrait("Use Patterns"); }
  
  Float loudnessOfLastFrame = 0f;
  Boolean lastFrameDidTrigger = false;
  Integer previousOutput = Arduino.LOW;
  Float maxLoudness = 0f;
  Float recentMaxLoudness = 0f;
  Float triggerTreshold = 0.5; // relative to recentMaxLoudness
  Integer timeOfLastTrigger = 0; // relative to program-start; in milliseconds
  
  TimedQueue loudnessHistory = new TimedQueue(1f);
  Patterns patterns = new Patterns();

  void processChunk(AudioBuffer buffer, FFT fft) {
    // Gets the loudness of the band in the given frame spectrum.
    loudnessOfLastFrame = bandLoudnessForChunk(fft, lowerBound(), upperBound());

    // Resets the `recentMaxLoudness` if the `loudnessRecalibrationDuration` has been exceeded.
    // Else, sets the `recentMaxLoudness` if appropriate.
    if (millis() - timeOfLastTrigger > loudnessRecalibrationDuration() * 1000) {
      recentMaxLoudness = loudnessOfLastFrame;
    } else {
      // TODO: This should also be affected by the overall loudness, so not all bands will always be relevant for a given song-segment
      recentMaxLoudness = max(recentMaxLoudness, loudnessOfLastFrame);
    }

    // Causes a flickering of triggers on sustained notes.
    if (loudnessHistory.average() > triggerTreshold * recentMaxLoudness) {
      triggerTreshold = 0.55;
    } else {
      triggerTreshold = 0.5;
    }

    // Sets the overall max loudness if appropriate.
    maxLoudness = max(maxLoudness, loudnessOfLastFrame);

    // Determines whether the current frame requires triggering.
    Float triggerLoudness = max(minimalTriggerThreshold() * maxLoudness, triggerTreshold * recentMaxLoudness);
    lastFrameDidTrigger = (loudnessOfLastFrame > triggerLoudness);

    // Resets the `timeOfLastTrigger` if appropriate.
    if (lastFrameDidTrigger) {
      timeOfLastTrigger = millis();
    }

    // Progresses the current pattern, if patterns are being used.
    if (lastFrameDidTrigger && (previousOutput.equals(Arduino.LOW)) && usePatterns()) { patterns.step(); }

    // Updates the output pins' states if necessary.
    if (arduino != null) {
      // Outputs to the Arduino differently, depending on whether patterns should be used or not.  
      if (usePatterns()) {
        patterns.applyStateToArduino(arduino);
      } else {  
        Integer newOutput = lastFrameDidTrigger ? Arduino.HIGH : Arduino.LOW;
        if (newOutput != previousOutput) {
          previousOutput = newOutput;
          for (Integer pin : outputPins()) { arduino.digitalWrite(pin, newOutput); }
        }
      }
    }

    // Records the loudness of this frame.
    loudnessHistory.push(loudnessOfLastFrame);
  }
}
