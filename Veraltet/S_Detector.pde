public final class S_Detector implements Server {

  private Configuration configuration;
  private Arduino arduino;

  public S_Detector(Configuration configuration, Arduino arduino) {
    this.configuration = configuration;
    this.arduino = arduino;
  }
  
  private Integer sensitivity() { return (Integer) configuration.valueForTrait("Sensitivity"); }
  private List<Integer> outputPins() { return (List<Integer>) configuration.valueForTrait("Output Pins"); }
  Boolean usePatterns() { return (Boolean) configuration.valueForTrait("Use Patterns"); }
  
  Boolean didTrigger = false;
  private Boolean didTriggerOnLastChunk = false;
  
  private BeatDetect beatDetector = new BeatDetect(1024, 44100);
  
  Patterns patterns = new Patterns();

  void processChunk(AudioBuffer buffer, FFT fft) {
    beatDetector.setSensitivity(sensitivity());
    
    // Passes down whether or not the last chunk did trigger.
    didTriggerOnLastChunk = didTrigger;
    
    // Determines whether the current chunk triggers.
    beatDetector.detect(buffer);
    didTrigger = beatDetector.isKick();

    // Progresses the current pattern, if patterns are being used.
    if (didTrigger && !didTriggerOnLastChunk && usePatterns()) { patterns.step(); }

    // Updates the output pins' states if necessary.
    if (arduino != null) {
      // Outputs to the Arduino differently, depending on whether patterns should be used or not.  
      if (usePatterns()) {
        patterns.applyStateToArduino(arduino);
      } else if (didTrigger != didTriggerOnLastChunk) {  
        Integer newOutput = didTrigger ? Arduino.HIGH : Arduino.LOW;
        for (Integer pin : outputPins()) { arduino.digitalWrite(pin, newOutput); }
      }
    }
  }
}
