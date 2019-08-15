//-ON-OFF-BUTTON-----------------------------------------------------//


final class Button {
  private Arduino arduino;
  private Integer pin;
  
  private Integer onDuration;
  private Integer lastBuzz;
  
  private Integer lastRead = 0;
  
  public Button(Integer onDuration, Integer pin, Arduino arduino) {
    this.arduino = arduino;
    this.pin = pin;
    this.onDuration = onDuration * 1000;
    this.lastBuzz = 0;
    
    if (arduino != null) { arduino.pinMode(pin, Arduino.INPUT); }
  }
  
  void update() {
    if (arduino == null) { return; }
    if (INPUT_STATE == InputState.patternWheel) { lastBuzz = -BUZZER_DURATION; }
    
    Integer buttonState = arduino.digitalRead(pin); 
    if (buttonState == 1 && lastRead == 0) {
      lastBuzz = millis();
    }
    
    lastRead = buttonState;
  }
  
  Boolean isOn() {
    return(millis() - lastBuzz) <= onDuration; 
  }
}


//-LED-LIGHTER-------------------------------------------------------//


final class LEDLighter {
  
  List<Integer[]> colors = Arrays.asList(
    new Integer[] { 255, 0, 0 }, // red must be first - is used in showRed()
    new Integer[] { 0, 255, 0},
    new Integer[] { 0, 0, 255},
    new Integer[] { 254, 0, 60 },
    new Integer[] { 17, 239, 54 },
    new Integer[] { 0, 254, 230 },
    new Integer[] { 197, 248, 8 },
    new Integer[] { 0, 0, 0 },
    new Integer[] { 255, 255, 255 }
  );
  
  public LEDLighter(Integer[] pins, Arduino arduino) {
    if (pins.length != 6) {
       println("LEDLighter expects exactly 6 pins.");
       System.exit(4);
    }
    
    this.pins = pins;
    this.arduino = arduino;
  }
  
  private Arduino arduino;
  private Integer[] pins;
  
  private Integer lastStep = millis();
  
  private Random randomNumberGenerator = new Random();
  
  private Integer[] currentColor = {0, 0, 0};
  private Integer[] nextColor = {0, 0, 0};
  
  void step() {
    if (arduino == null) { return; }
    
    if (INPUT_STATE == InputState.patternWheel) {     
      for (Integer component = 0; component < 3; component++) {
        Integer componentPin1 = pins[component];
        Integer componentPin2 = pins[component + 3];
      
        arduino.analogWrite(componentPin1, colors.get(0)[component]);
        arduino.analogWrite(componentPin2, colors.get(0)[component]);
      }
    
      return;
    }
    
    if (millis() - lastStep < 10) { return; }
    lastStep = millis();
    
    if (Arrays.equals(currentColor, nextColor)) {
      Integer nextColorIndex = randomNumberGenerator.nextInt(colors.size());
      nextColor = colors.get(nextColorIndex);
    }
    
    for (Integer component = 0; component < 3; component++) {
      Integer componentPin1 = pins[component];
      Integer componentPin2 = pins[component + 3];
      
      Integer increment = (currentColor[component] > nextColor[component]) ? -1 : 0;
      increment = (currentColor[component] < nextColor[component]) ? 1 : increment;
      
      currentColor[component] += increment;
      
      Integer flickeringValue = currentColor[component]; 
      if (buzzer.isOn() && (millis() % 500 > 250)) { flickeringValue = 0; }
      
      arduino.analogWrite(componentPin1, flickeringValue);
      arduino.analogWrite(componentPin2, flickeringValue);
    }
  }
  
  /*void step() {
    if (arduino == null) { return; }
    
    Integer now = millis();
    Float timeSinceStart = (now - transitionStart) / 1000f;
    Float relativeProgress = timeSinceStart / transitionDuration;
    
    if (timeSinceStart > transitionDuration) {
      currentColor = Arrays.copyOf(nextColor, nextColor.length);
      transitionStart = now;
      relativeProgress = 0f;
      
      Integer nextColorIndex = randomNumberGenerator.nextInt(colors.size());
      nextColor = colors.get(nextColorIndex);
      for (Integer component = 0; component < 3; component++) {
        Integer value = nextColor[component];
        colorDifference[component] = value - currentColor[component];
      }
    }
    
    for (Integer component = 0; component < 3; component++) {
      Integer componentPin1 = pins[component];
      Integer componentPin2 = pins[component + 3];
      Integer componentValue = Math.round(currentColor[component] + (relativeProgress * colorDifference[component]));
      
      arduino.analogWrite(componentPin1, componentValue);
      arduino.analogWrite(componentPin2, componentValue);
    }
  }*/
}
