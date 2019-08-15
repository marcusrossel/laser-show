public final class V_Old implements ServerVisualizer {

  public V_Old(Server server) {
    this.server = (S_Old) server;
  }

  private S_Old server;

  void showServerProperties() {
    Integer triggerPaneY =             50;
    Integer frequencyStartX =          (int) (map(server.lowerBound(),                               0,              20000,      0,        width));
    Integer frequencyEndX =            (int) (map(server.upperBound(),                               0,              20000,      0,        width));
    Integer lastLoudnessY =            (int) (map(server.loudnessOfLastFrame,                        0, server.maxLoudness, height, triggerPaneY));
    Integer recentMaxLoudnessY =       (int) (map(server.recentMaxLoudness,                          0, server.maxLoudness, height, triggerPaneY));
    Integer triggerThresholdY =        (int) (map(server.triggerTreshold * server.recentMaxLoudness, 0, server.maxLoudness, height, triggerPaneY));
    Integer minimumTriggerThresholdY = (int) (map(server.minimalTriggerThreshold(),                  0,                  1, height, triggerPaneY));
  
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
      if (server.lastFrameDidTrigger) { fill(255, 255, 0); } else { fill(50, 50, 50); }
      rect(0, 0, width, triggerPaneY);
    }
    
    
    
    // Draws the frequency range in magenta.
    fill(255, 0, 200, 50);
    rect(frequencyStartX, triggerPaneY, frequencyEndX - frequencyStartX, height - triggerPaneY);
    
    strokeWeight(5);

    // Draws the last loudness in white.
    stroke(255, 255, 255);
    line(0, lastLoudnessY, width, lastLoudnessY);

    // Draws the recent maximum loudness in red.
    stroke(255, 0, 0, 100);
    line(0, recentMaxLoudnessY, width, recentMaxLoudnessY);

    // Draws the trigger threshold in green.
    stroke(0, 255, 0);
    line(0, triggerThresholdY, width, triggerThresholdY);

    // Draws the minimum trigger threshold in blue.
    stroke(0, 0, 255, 100);
    line(0, minimumTriggerThresholdY, width, minimumTriggerThresholdY);
  }
}
