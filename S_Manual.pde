final class S_Manual implements Server {

  private Arduino arduino;
  private Configuration configuration;
  
  public S_Manual(Configuration configuration, Arduino arduino) { 
    if (arduino == null) {
      println("User error: S_Manual does not make sense without Arduino");
      System.exit(5);
    }
    
    this.arduino = arduino;
    this.configuration = configuration;
    
    arduino.pinMode(MANUAL_BUTTON_PIN, Arduino.INPUT);
  }
  
  List<Integer> outputPins() { return (List<Integer>) configuration.valueForTrait("Output Pins"); }
  Boolean usePatterns()      { return (Boolean) configuration.valueForTrait("Use Patterns"); }
  Float sampleDuration()     { return (Float) configuration.valueForTrait("Sample Duration"); }
  Float multiplier()         { return (Float) configuration.valueForTrait("Multiplier"); }
  Float tolerance()          { return (Float) configuration.valueForTrait("Tolerance"); }
  
  Integer lastButtonState = 0;
  Integer lastPressTime = 0;
  Float averageGap = 0f;
  
  Boolean showOutput = true;
  Boolean lastDidTrigger = false;
  Boolean didTrigger = false;

  Patterns patterns = new Patterns();
  TimedQueue pressHistory = new TimedQueue(0f);

  void processChunk(AudioBuffer buffer, FFT fft) {
    Integer now = millis();
    
    pressHistory.retentionDuration = sampleDuration();
    processButtonPresses(now);

    didTrigger = ((float) (now - lastPressTime) % (averageGap * multiplier())) < (tolerance() * 1000); // depends on the current time
    updateOutput(didTrigger && !lastDidTrigger);
    lastDidTrigger = didTrigger;
  }
  
  void processButtonPresses(Integer now) {    
    Integer buttonState = arduino.digitalRead(MANUAL_BUTTON_PIN);
    
    if (buttonState == 1 && lastButtonState == 0) {
      Float timeBetweenPresses = (float) (now - lastPressTime);
      
      pressHistory.push(timeBetweenPresses);
      
      lastPressTime = now;
      averageGap = pressHistory.average();
    }
    
    lastButtonState = buttonState;
  }
  
  void updateOutput(Boolean trigger) {    
    // Outputs to the Arduino differently, depending on whether patterns should be used or not.  
    if (usePatterns()) {
      if (trigger) { patterns.step(); } 
      patterns.applyStateToArduino(arduino, showOutput);
    } else {   
      Integer newOutput = (showOutput && trigger) ? Arduino.HIGH : Arduino.LOW;
      for (Integer pin: outputPins()) { arduino.digitalWrite(pin, newOutput); }
    }
  }
  
  void showOutput(Boolean show) { showOutput = show; }
}
