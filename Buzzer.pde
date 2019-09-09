final class Buzzer {
  
  private int lastBuzz = 0;
  private int lastRead = 0;
  
  void update() {        
    updateMechanics();
    updateState();
  }
  
  // Updates the information obtained from the physical buzzer switch.
  private void updateMechanics() {
    int buttonState = arduino.digitalRead(Runtime.buzzerPin());
    
    if (buttonState == 1 && lastRead == 0) {
      lastBuzz = millis();
    }
    
    lastRead = buttonState;
  }
  
  // Updates global state information as a result of the buzzer's state.
  private void updateState() {
    if (State.inputSource == InputSource.mouse) {
      lastBuzz = 0;
    } else {
      State.inputSource = ((millis() - lastBuzz) <= (Runtime.buzzerDuration() * 1000)) ? InputSource.analyzer : InputSource.none;
    }
  }
}
