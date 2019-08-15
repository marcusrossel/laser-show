public final class V_Detector implements ServerVisualizer {

  public V_Detector(Server server) {
    this.server = (S_Detector) server;
  }

  private S_Detector server;

  void showServerProperties() {
    Integer triggerPaneY = 50;
  
    noStroke();
  
    // Draws the tigger pane.
    if (server.usePatterns()) {
      Map<Integer, Integer> pinStates = server.patterns.pinStates();
      List<Integer> pins = new ArrayList<Integer>(pinStates.keySet());
      Collections.sort(pins);
      
      Integer paneWidth = Math.round(width / pins.size()); 
      
      for (Integer pinIndex = 0; pinIndex < pins.size(); pinIndex++) {
        Integer state = pinStates.get(pins.get(pinIndex));
        if (state.equals(Arduino.HIGH)) { fill(255, 255, 0); } else { fill(50, 50, 50); }
        rect(pinIndex * paneWidth, 0, paneWidth, triggerPaneY);
      }
    } else {
      if (server.didTrigger) { fill(255, 255, 0); } else { fill(50, 50, 50); }
      rect(0, 0, width, triggerPaneY);
    }
  }
}
