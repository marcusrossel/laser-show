final class Patterns {
  
  private List<Integer[][]> allPatterns = Arrays.asList(
    new Integer[][] {{0, 1, 2, 3, 4}}, // Alle an
    new Integer[][] {{}}, // Alle aus
    new Integer[][] {{0, 1, 2, 3, 4}, {}, {0, 1, 2, 3, 4}, {}, {0, 1, 2, 3, 4}, {}, {0, 1, 2, 3, 4}, {}}, // 8x An aus
    
    new Integer[][] {{4}, {3}, {2}, {1}, {0}}, // Außen nach innen
    new Integer[][] {{0}, {1}, {2}, {3}, {4}}, // Innen nach außen 
    new Integer[][] {{0}, {1}, {2}, {3}, {4}, {3}, {2}, {1}, {0}, {1}, {2}, {3}, {4}}, // Innen außen innen außen
    new Integer[][] {{2}, {1, 3}, {0, 4}}, // Mitte nach außen
    new Integer[][] {{0, 4}, {1, 3}, {2}}, // Außen nach mitte
    new Integer[][] {{0, 4}, {1, 3}, {2}, {1, 3}, {0, 4}}, // Außen mitte außen
    new Integer[][] {{2}, {1, 3}, {0, 4}, {1, 3}, {2}}, // Mitte außen mitte
    
    new Integer[][] {{0}, {1}, {2}, {3}, {4}, {0}, {1}, {2}, {3}, {4}}, // Laufband vorwärts
    new Integer[][] {{4}, {3}, {2}, {1}, {0}, {4}, {3}, {2}, {1}, {0}}, // Laufband rückwärts
    
    new Integer[][] {{3}, {4}, {2}, {4}, {0}, {3}, {1}, {0}, {1}, {2}}, // 2x Alles Chaos
    
    new Integer[][] {{1}, {3}, {0}, {2}, {4}}, // Chaos #1.1
    new Integer[][] {{2}, {0}, {3}, {4}, {1}}, // Chaos #1.2
    new Integer[][] {{0}, {1, 3}, {2}, {3, 4}, {1}, {0, 1, 2, 3, 4}, {0, 4}, {1, 2}}, // Chaos #1.3
    new Integer[][] {{3, 4}, {2}, {1, 3}, {0}, {3}, {0, 4}, {0, 1, 2, 3, 4}, {1}}, // Chaos #1.4
    new Integer[][] {{0, 3}, {1, 4}, {2}, {0, 4}}, // Chaos #2.1
    new Integer[][] {{1, 4}, {0, 3}, {0, 4}, {2}}, // Chaos #2.2
    new Integer[][] {{0, 2, 4}, {1, 3}, {0, 1, 2}, {2, 3, 4}}, // Chaos #3.1
    new Integer[][] {{2, 3, 4}, {0, 1, 2}, {1, 3}, {0, 2, 4}} // Chaos #3.2
  );
  
  private List<Integer> laserPins = Arrays.asList(2, 3, 4, 5, 6); // [yellow, red, white, green, blue]
  
  // Indicates what the next iteration value will be. 
  private Integer nextIteration = 0;
  
  // Does not initialize the current pattern, as this will occur in `step`.
  private Integer currentPatternIndex = 0;
  
  private Random randomNumberGenerator = new Random();

  void step() {  
    nextIteration++;
    
    // Sets the next iteration back to 0 if the current pattern is complete.
    if (nextIteration == allPatterns.get(currentPatternIndex).length) {
      nextIteration = 0;
    }
    
    // Sets a new random pattern if no other is running.
    if (nextIteration == 0) {
      currentPatternIndex = randomNumberGenerator.nextInt(allPatterns.size());
    }
  }
  
  Map<Integer, Integer> pinStates() {
    // Initializes the pin state map to set every pin to LOW.
    Map<Integer, Integer> pinStates = new HashMap<Integer, Integer>();
    for (Integer pin: laserPins) { pinStates.put(pin, Arduino.LOW); }
    
    Integer[][] pinIndexOrder = allPatterns.get(currentPatternIndex);
    
    // Turns those pins on that are supposed to be on for the current iteration.
    for (Integer pinIndex: pinIndexOrder[nextIteration]) {
      Integer pin = laserPins.get(pinIndex);
      
      pinStates.put(pin, Arduino.HIGH);
    }
    
    return pinStates;
  }
  
  void applyStateToArduino(Arduino arduino, Boolean showOutput) {
    for (Map.Entry<Integer, Integer> pinStatePair: pinStates().entrySet()) {
      Integer value = showOutput ? pinStatePair.getValue() : Arduino.LOW;
      arduino.digitalWrite(pinStatePair.getKey(), value);
    }
  }
}
