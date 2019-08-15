final class V_Manual implements ServerVisualizer {

  public V_Manual(Server server) {
    this.server = (S_Manual) server;
  }

  private S_Manual server;
  private  Integer triggerPaneY = 50;

  void showServerProperties() {
    drawTriggerPane();
  }
  
  void drawTriggerPane() {
    noStroke();
    
    color baseColor = #323232;
    color triggerColor = server.showOutput ? #FFFF00 : #FF4000;
  
    // Draws the tigger pane.
      Map<Integer, Integer> pinStates = patterns.pinStates();
      List<Integer> pins = new ArrayList<Integer>(pinStates.keySet());
      Collections.sort(pins);
      
      Integer paneWidth = Math.round(width / pins.size()); 
      
      for (Integer pinIndex = 0; pinIndex < pins.size(); pinIndex++) {
        Integer state = pinStates.get(pins.get(pinIndex));
        if (state.equals(Arduino.HIGH)) { fill(triggerColor); } else { fill(baseColor); }
        rect(pinIndex * paneWidth, 0, paneWidth, triggerPaneY);
      }
  }
}
