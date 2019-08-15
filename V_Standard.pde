final class V_Standard implements ServerVisualizer {

  public V_Standard(StandardServer server) {
    this.server = server;
  }

  private StandardServer server;
  private  Integer triggerPaneY = 50;

  void showServerProperties() {
    drawTriggerPane();
    
    Integer frequencyStartX =          (int) (map(server.lowerBound,                                            0,                MAX_FREQ,      0,        width));
    Integer frequencyEndX =            (int) (map(server.upperBound,                                            0,                MAX_FREQ,      0,        width));
    Integer recordedLoudnessY =        (int) (map(server.recordedLoudness,                                      0, server.totalMaxLoudness, height, triggerPaneY));
    Integer maxLoudnessY =             (int) (map(server.recentMaxLoudness,                                     0, server.totalMaxLoudness, height, triggerPaneY));
    Integer featureValueY =            (int) (map(server.featureValue,                                          0, server.totalMaxLoudness, height, triggerPaneY));
    Integer triggerThresholdY =        (int) (map(server.triggerTreshold() * server.featureValue,               0, server.totalMaxLoudness, height, triggerPaneY));
    Integer minimumTriggerThresholdY = (int) (map(server.minimalTriggerThreshold() * server.recentMaxLoudness,  0, server.totalMaxLoudness, height, triggerPaneY));
    
    // Draws the frequency range in magenta.
    fill(255, 0, 200, 80);
    rect(frequencyStartX, triggerPaneY, frequencyEndX - frequencyStartX, height - triggerPaneY);


    if (server.useFrequencyFinder()) {
      strokeWeight(3);
       
      Integer centerFrequencyX = (int) (map(server.frequencyFinderCenter, 0, MAX_FREQ, 0, width)); 
    
      // Draws the center frequency in purple.
      stroke(110, 20, 200);
      line(centerFrequencyX, triggerPaneY, centerFrequencyX, height); 
    }

    strokeWeight(5);

    // Draws the recorded loudness in white.
    stroke(255, 255, 255);
    line(0, recordedLoudnessY, width, recordedLoudnessY);

    // Draws the feature value in red.
    stroke(255, 0, 0, 100);
    line(0, featureValueY, width, featureValueY);

    // Draws the trigger threshold in green.
    stroke(0, 255, 0);
    line(0, triggerThresholdY, width, triggerThresholdY);
    
    // Draws the recent maximum loudness in grey.
    stroke(100);
    line(0, maxLoudnessY, width, maxLoudnessY);

    // Draws the minimum trigger threshold in blue.
    stroke(0, 0, 255, 100);
    line(0, minimumTriggerThresholdY, width, minimumTriggerThresholdY);
  }
  
  void drawTriggerPane() {
    noStroke();
    
    color baseColor = #323232;
    color triggerColor = server.showOutput ? #FFFF00 : #FF4000;
  
    // Draws the tigger pane.
    if (server.usePatterns()) {
      Map<Integer, Integer> pinStates = server.patterns.pinStates();
      List<Integer> pins = new ArrayList<Integer>(pinStates.keySet());
      Collections.sort(pins);
      
      Integer paneWidth = Math.round(width / pins.size()); 
      
      for (Integer pinIndex = 0; pinIndex < pins.size(); pinIndex++) {
        Integer state = pinStates.get(pins.get(pinIndex));
        if (state.equals(Arduino.HIGH)) { fill(triggerColor); } else { fill(baseColor); }
        rect(pinIndex * paneWidth, 0, paneWidth, triggerPaneY);
      }
    } else {
      if (server.didTrigger) { fill(triggerColor); } else { fill(baseColor); }
      rect(0, 0, width, triggerPaneY);
    }
  }
}
