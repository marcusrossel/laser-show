final class LEDs {
  
  private int[][] colorSpace = new int[][] {
    { 255, 0, 0 },
    { 0, 255, 0},
    { 0, 0, 255},
    { 254, 0, 60 },
    { 17, 239, 54 },
    { 0, 254, 230 },
    { 197, 248, 8 },
    { 0, 0, 0 },
    { 255, 255, 255 }
  };
  
  private Random rng = new Random();
  
  private int[] currentColor = {0, 0, 0};
  private int[] targetColor = {0, 0, 0};
  
  void init() {
    List<Integer> allOutputPins = new ArrayList();
    allOutputPins.addAll(Runtime.ledRedPins());
    allOutputPins.addAll(Runtime.ledGreenPins());
    allOutputPins.addAll(Runtime.ledBluePins()); 
    
    for (int pin : allOutputPins) {
      arduino.pinMode(pin, Arduino.OUTPUT);  
    }
  }
  
  void update() {    
    // Shows the color red when the input source is the mouse.
    if (State.inputSource == InputSource.mouse) {
      showColor(new int[] { 255, 0, 0 });
      return;
    }
    
    // Chooses a new random target color from the color space when the current color has meet its target.
    if (Arrays.equals(currentColor, targetColor)) {
      int nextColorIndex = rng.nextInt(colorSpace.length);
      targetColor = colorSpace[nextColorIndex];
    }
    
    // Updates the current color.    
    for (int component = 0; component < 3; component++) {
      int increment = ((Integer) targetColor[component]).compareTo(currentColor[component]);
      currentColor[component] += increment;
    }
    
    // TODO: Implement flickering: if (-||- && !serverDidTrigger) 
    if (State.inputSource == InputSource.analyzer) { 
      showColor(new int[] { 0, 0, 0 });
    } else {
      showColor(currentColor); 
    }
  }
   
  private void showColor(int[] target) {
    if (target.length != 3) {
      println("Internal error: `LEDs.pde`'s `void showColor(int[])` received malformed color-array");
      System.exit(1);
    }
    
    List<List<Integer>> componentPins = Arrays.asList(
      Runtime.ledRedPins(),
      Runtime.ledGreenPins(),
      Runtime.ledBluePins()
    );
    
    for (int component = 0; component < 3; component++) {
      int componentValue = target[component];
      
      for (int pin : componentPins.get(component)) {
        arduino.analogWrite(pin, componentValue);  
      }
    }
  }
}
