//-ON-OFF-BUTTON-----------------------------------------------------//


final class Button {
  private Arduino arduino;
  private Integer pin;
  private Boolean isOn;
  private Integer lastRead = 0;
  
  public Button(Boolean isOn, Integer pin, Arduino arduino) {
    this.arduino = arduino;
    this.pin = pin;
    this.isOn = isOn;
    
    if (arduino != null) { arduino.pinMode(pin, Arduino.INPUT); }
  }
  
  Boolean isOn() {
    if (arduino == null) { return true; }
    
    Integer buttonState = arduino.digitalRead(pin); 
    if (buttonState == 1 && lastRead == 0) { isOn = !isOn; }
    
    lastRead = buttonState;
    return isOn;
  }
}


//-LED-LIGHTER-------------------------------------------------------//


final class LEDLighter {
  
  public LEDLighter(Float transitionDuration, Integer[] pins, Arduino arduino) {
    if (pins.length != 3) {
       println("LEDLighter expects excatly 3 pins.");
       System.exit(4);
    }
    
    this.transitionDuration = transitionDuration;
    this.pins = pins;
    this.arduino = arduino;
    transitionStart = millis();
  }
  
  private Arduino arduino;
  private Integer[] pins;
  
  private Float transitionDuration;
  private Integer transitionStart;
  
  private Random randomNumberGenerator = new Random();
  
  private Integer[] currentColor = {0, 0, 0};
  private Integer[] nextColor = {0, 0, 0};
  private Integer[] colorDifference = {0, 0, 0};
  
  void step() {    
    if (arduino == null) { return; }
    
    Integer now = millis();
    Float timeSinceStart = (now - transitionStart) / 1000f;
    Float relativeProgress = timeSinceStart / transitionDuration;
    
    if (timeSinceStart > transitionDuration) {
      currentColor = Arrays.copyOf(nextColor, nextColor.length);
      transitionStart = now;
      relativeProgress = 0f;
      
      for (Integer component = 0; component < 3; component++) {
        Integer randomValue = randomNumberGenerator.nextInt(256);
        nextColor[component] = randomValue;
        colorDifference[component] = randomValue - currentColor[component];
      }
    }
    
    for (Integer component = 0; component < 3; component++) {
      Integer componentPin = pins[component];
      Integer componentValue = Math.round(currentColor[component] + (relativeProgress * colorDifference[component]));
      
      arduino.analogWrite(componentPin, componentValue);
    }
  }
}
