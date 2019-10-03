final class Lasers {
  
  private int[][][] patternSpace = new int[][][] {
    {{0, 1, 2, 3, 4}}, // Alle an
    {{}}, // Alle aus
    {{0, 1, 2, 3, 4}, {}, {0, 1, 2, 3, 4}, {}, {0, 1, 2, 3, 4}, {}, {0, 1, 2, 3, 4}, {}}, // 8x An aus
    
    {{4}, {3}, {2}, {1}, {0}}, // Außen nach innen
    {{0}, {1}, {2}, {3}, {4}}, // Innen nach außen 
    {{0}, {1}, {2}, {3}, {4}, {3}, {2}, {1}, {0}, {1}, {2}, {3}, {4}}, // Innen außen innen außen
    {{2}, {1, 3}, {0, 4}}, // Mitte nach außen
    {{0, 4}, {1, 3}, {2}}, // Außen nach mitte
    {{0, 4}, {1, 3}, {2}, {1, 3}, {0, 4}}, // Außen mitte außen
    {{2}, {1, 3}, {0, 4}, {1, 3}, {2}}, // Mitte außen mitte
    
    {{0}, {1}, {2}, {3}, {4}, {0}, {1}, {2}, {3}, {4}}, // Laufband vorwärts
    {{4}, {3}, {2}, {1}, {0}, {4}, {3}, {2}, {1}, {0}}, // Laufband rückwärts
    
    {{3}, {4}, {2}, {4}, {0}, {3}, {1}, {0}, {1}, {2}}, // 2x Alles Chaos
    
    {{1}, {3}, {0}, {2}, {4}}, // Chaos #1.1
    {{2}, {0}, {3}, {4}, {1}}, // Chaos #1.2
    {{0}, {1, 3}, {2}, {3, 4}, {1}, {0, 1, 2, 3, 4}, {0, 4}, {1, 2}}, // Chaos #1.3
    {{3, 4}, {2}, {1, 3}, {0}, {3}, {0, 4}, {0, 1, 2, 3, 4}, {1}}, // Chaos #1.4
    {{0, 3}, {1, 4}, {2}, {0, 4}}, // Chaos #2.1
    {{1, 4}, {0, 3}, {0, 4}, {2}}, // Chaos #2.2
    {{0, 2, 4}, {1, 3}, {0, 1, 2}, {2, 3, 4}}, // Chaos #3.1
    {{2, 3, 4}, {0, 1, 2}, {1, 3}, {0, 2, 4}}, // Chaos #3.2
    
    {{0, 1, 2, 3, 4}, {0, 4}, {0, 1, 2, 3, 4}, {1, 3}, {0, 1, 2, 3, 4}, {2}, {0, 1, 2, 3, 4}}, // Marcus #1
  };
  
  Map<Integer, Integer> lastOutput = new HashMap<Integer, Integer>();
  boolean timedOut = false; 
  
  private int timeOfLastRealStep = millis();
  
  private LinkedList<int[]> patternHistory = new LinkedList<int[]>(Arrays.asList(new int[] {}, new int[] {}));
  private int historyIndex = 0;
  
  // "generating pattern" aka "the pattern that is generating" 
  private int generatingPatternIndex = 0; 
  private int generatingPatternStep = 0;
  
  private Random randomNumberGenerator = new Random();

  void generateNextPattern() {    
    generatingPatternStep++;
    
    // Sets the next step back to 0 if the current pattern is complete.
    if (generatingPatternStep == patternSpace[generatingPatternIndex].length) {
      generatingPatternStep = 0;
    }
    
    // Sets a new random pattern if no other is running.
    if (generatingPatternStep == 0) {
      generatingPatternIndex = randomNumberGenerator.nextInt(patternSpace.length);
    }
    
    patternHistory.add(patternSpace[generatingPatternIndex][generatingPatternStep]);
    
    // Bounds the size of the pattern history to the runtime-specified value.
    if (historyIndex == Runtime.patternHistory()) { patternHistory.removeFirst(); historyIndex--; }
    
  }
  
  void processStep(int step) {
    if (abs(step) > 1) {
      println("Internal error: `Lasers.pde`'s `void processStep(int)` received value with |value| > 1");
      System.exit(1);
    }
    
    // Records the current time as the time of the last "real" (meaning non-zero) step, if the current step is non-zero.
    if (step != 0) {
      timedOut = false;
      timeOfLastRealStep = millis();
    
    // Turns off the lasers if they have been turned on for too long (this only applies if the input source is the analyzer). 
    } else  {
      timedOut = (State.inputSource == InputSource.analyzer && ((millis() - timeOfLastRealStep) > (Runtime.maximumLaserOnDuration() * 1000)));
      
      // Due to how `timedOut` is defined, this can only every be true if the input source is the analyzer.
      // Hence the return at the end of this block is valid and needed.
      if (timedOut) {
        for (int pin : Runtime.laserPins()) {
          arduino.digitalWrite(pin, Arduino.LOW);
        }
        
        return;
      }
    }
    
    // Updates the pattern history and its index according to the step taken.
    historyIndex = max(historyIndex + step, 0);
    if (historyIndex >= patternHistory.size()) { generateNextPattern(); }
    
    // Overrides the determined pattern if the input source is the mouse in specific modes.
    if (State.inputSource == InputSource.mouse && State.mouseMode != MouseMode.wheel) {
      int value = (State.mouseMode == MouseMode.allOff) ? Arduino.LOW : Arduino.HIGH;  
      for (int pin : Runtime.laserPins()) {
        arduino.digitalWrite(pin, value);
        lastOutput.put(pin, value);    
      }  
    } else {
      showCurrentPattern();
    }
  }
  
  private void showCurrentPattern() {
    // Initializes the pin state map to set every pin to LOW.
    for (int pin : Runtime.laserPins()) { lastOutput.put(pin, Arduino.LOW); }
    
    // Turns those pins on that are supposed to be on for the current iteration.
    for (int pinIndex : patternHistory.get(historyIndex)) {
      int pin = Runtime.laserPins().get(pinIndex);
      lastOutput.put(pin, Arduino.HIGH);
    }
    
    // Writes the pin states to the arduino.
    for (Map.Entry<Integer, Integer> pinStatePair: lastOutput.entrySet()) {      
      arduino.digitalWrite(pinStatePair.getKey(), pinStatePair.getValue());   
    }
  }
}
