final class Lasers {
  
  private Patterns patterns = new Patterns();
  private int lastChange = millis();
  Set<Integer> lastOutput = new HashSet<Integer>();
  boolean timedOut = false; 
  
  void init() {
    for (int pin : Runtime.laserPins()) {
      arduino.pinMode(pin, Arduino.OUTPUT);  
    }  
  }
 
  private void applyPattern(Set<Integer> pattern) {
    applyPattern(pattern, true);
  }
 
  private void applyPattern(Set<Integer> pattern, boolean recordAsOutput) {
    List<Integer> laserPins = Runtime.laserPins();
    
    for (int index = 0; index < laserPins.size(); index++) {
      // The XOR implies that only the pins that have changed are updated.
      if (pattern.contains(index) ^ lastOutput.contains(index)) {
        int value = pattern.contains(index) ? Arduino.HIGH : Arduino.LOW;
        arduino.digitalWrite(laserPins.get(index), value); 
      }
    }
    
    if (recordAsOutput) { lastOutput = pattern; }
  }
 
  void processStep(int step) {    
    // Records the current time as the time of the last "real" (meaning non-zero) step, if the current step is non-zero.
    if (step != 0) {
      timedOut = false;
      lastChange = millis();
    
    // Turns off the lasers if they have been turned on for too long (this only applies if the input source is the analyzer). 
    } else {
      timedOut = (State.inputSource == InputSource.analyzer && ((millis() - lastChange) > (Runtime.maximumLaserOnDuration() * 1000)));
      
      // Due to how `timedOut` is defined, this can only every be true if the input source is the analyzer.
      // Hence the return at the end of this block is valid and needed.
      if (timedOut) { 
        applyPattern(patterns.allOff, /*recordAsOutput:*/ false);
        return;
      }
    }

    Set<Integer> pattern;

    // Overrides the determined pattern if the input source is the mouse in specific modes.
    if (State.inputSource == InputSource.mouse && State.mouseMode != MouseMode.wheel) {
      pattern = (State.mouseMode == MouseMode.allOff) ? patterns.allOff : patterns.allOn; 
    } else {
      pattern = (step > 0) ? patterns.nextPattern() : ((step < 0) ? patterns.previousPattern() : lastOutput);
    }
    
    applyPattern(pattern);
  }  
  
  // For debugging.
  void printMemoryUsage() {
    println("last output:\t", lastOutput.size());
    print("patterns:\t");
    patterns.printMemoryUsage();
  }
}
