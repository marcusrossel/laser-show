final class Patterns {
  
  final Set<Integer> allOn = new HashSet<Integer>(Arrays.asList(0, 1, 2, 3, 4));
  final Set<Integer> allOff = new HashSet<Integer>();
  
  private int[][][] routines = {
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
  
  private LinkedList<Set<Integer>> history = new LinkedList<Set<Integer>>();
  
  private int historyIndex = 0; // is always pointing at an element that has not yet been used (like endIndex)
  private int routineIndex = 0; // is always pointing at the routine that is currently being used to generate new patterns
  private int patternIndex = 0; // is always pointing at an element that has not yet been used (like endIndex)
    
  private Random randomNumberGenerator = new Random();
  
  // TODO: Get this inline into the declaration of `history`.
  Patterns() {
    history.add(allOn);
  }
  
  private void generateNewPattern() {
    if (patternIndex >= routines[routineIndex].length) {
      routineIndex = randomNumberGenerator.nextInt(routines.length);
      patternIndex = 0;
    }
    
    int[] patternArray = routines[routineIndex][patternIndex];
    Set<Integer> pattern = new HashSet();
    for (int element : patternArray) { pattern.add(element); }

    history.add(pattern);
    patternIndex++;
    
    if (history.size() > Runtime.patternHistory()) {
      history.removeFirst();
      historyIndex--;
    }
  }
  
  Set<Integer> nextPattern() {    
    // The history index should theoretically never be greater than history.length, so generating one new pattern should always be enough.
    if (historyIndex >= history.size()) {
      generateNewPattern();
    }
    
    Set<Integer> pattern = history.get(historyIndex);
    historyIndex++;

    return pattern;
  }
  
  Set<Integer> previousPattern() {
    if (historyIndex == 0) { historyIndex = history.size(); }
    
    historyIndex--;
    Set<Integer> pattern = history.get(historyIndex);
    
    return pattern;
  }
  
  // For debugging.
  void printMemoryUsage() {
    println("history:\t", history.size());
  }
}
