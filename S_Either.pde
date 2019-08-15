// This server determines whether to trigger using two main heuristics:
// 1) Compared to the average loudness over the last N seconds, is the current chunk "significantly" louder?
// OR
// 2) Compared to the average loudness of local maxima over the last M seconds, is the current chunk "almost" as loud?
//
// The center of frequencies being analyzed is determined by a frequency finder.

final class S_Either implements Server {

  private Configuration configuration;
  private Arduino arduino;

  public S_Either(Configuration configuration, Arduino arduino) {
    this.configuration = configuration;
    this.arduino = arduino;
  }

  Float         frequencyRange()  { return (Float) configuration.valueForTrait("Frequency Range"); }
  Float         historyInterval() { return (Float) configuration.valueForTrait("History Interval"); }
  Float         averageTreshold() { return (Float) configuration.valueForTrait("Average Threshold"); }
  Float         maximaTreshold()  { return (Float) configuration.valueForTrait("Maxima Threshold"); }
  List<Integer> outputPins()      { return (List<Integer>) configuration.valueForTrait("Output Pins"); }
  Boolean       usePatterns()     { return (Boolean) configuration.valueForTrait("Use Patterns"); }

  Float recordedLoudness = 0f;
  Boolean didTrigger = false;
  Boolean didTriggerOnLastChunk = false;
  
  // These properties are for use by visualizers.
  Float recentAverageLoudness = 0f;
  Float recentMaximaLoudness = 0f;
  Float lowerBound = 0f;
  Float upperBound = 0f;
  Float centerFrequency = 0f;
  
  TimedQueue history = new TimedQueue(0f);
  Patterns patterns = new Patterns();

  void processChunk(AudioBuffer buffer, FFT fft) {
    // Passes down whether or not the last chunk did trigger.
    didTriggerOnLastChunk = didTrigger;
    // Updates the loudness history retention duration.
    history.retentionDuration = historyInterval();
    
    // Gets the loudness of the current chunk within the frequency bounds.
    recordedLoudness = bandLoudnessForChunk(fft, lowerBound, upperBound);
    // Records the loudness of this chunk.
    history.push(recordedLoudness);
    // Gets the average loudness of the last (history interval) seconds.
    recentAverageLoudness = history.average();
    
    Float triggerLoudness = averageTreshold() * recentAverageLoudness;
    // Determines whether the current chunk triggers.
    didTrigger = (recordedLoudness > triggerLoudness);

    // Progresses the current pattern, if patterns are being used.
    if (didTrigger && !didTriggerOnLastChunk && usePatterns()) { patterns.step(); }

    // Updates the output pins' states if necessary.
    if (arduino != null) {
      // Outputs to the Arduino differently, depending on whether patterns should be used or not.  
      if (usePatterns()) {
        patterns.applyStateToArduino(arduino, true);
      } else if (didTrigger != didTriggerOnLastChunk) {  
        Integer newOutput = didTrigger ? Arduino.HIGH : Arduino.LOW;
        for (Integer pin : outputPins()) { arduino.digitalWrite(pin, newOutput); }
      }
    }
  }
  
  void showOutput(Boolean show) { }
}
