final class Visualizer {

  // Records the highest intensity of a frequency ever measured.
  float maxAmplitude = 0f;
  
  void init() {
    textFont(createFont("Helvetica Neue", 24, true));  
  }
  
  void update(FFT chunk) {
    background(0);
    if (Runtime.visualizeSpectrum())  { showSpectrum(chunk); }
    if (Runtime.visualizeAnalyzer())  { showAnalyzer(); }
    if (Runtime.visualizeBPMFinder()) { showBPMAnalysis(); }
    if (Runtime.visualizeState())     { showState(); }
  }
  
  private int adjustedWidth() {
    if (Runtime.useBPMFinder() && State.inputSource == InputSource.analyzer) {
      return (int) (0.95 * width);  
    } else {
      return width;  
    }
  }
  
  private void showSpectrum(FFT chunk) {
    // Draws 100Hz marks.
    strokeWeight(1);
    for (int frequency = 100; frequency < Runtime.maximumVisualFrequency(); frequency += 100) {
      if (frequency % 500 == 0) { stroke(100); } else { stroke(40); };
      int x = (int) map(frequency, 0, Runtime.maximumVisualFrequency(), 0, adjustedWidth());
      line(x, 0, x, height); 
    }
    
    int bandCount = (int) ((float) Runtime.maximumVisualFrequency() / chunk.getBandWidth());
    int bandLengthX = adjustedWidth() / bandCount;

    // Draws the band intensities.
    for (int band = 0; band <= bandCount; band++) {
      float frequency = chunk.indexToFreq(band);
      float amplitude = chunk.getBand(band);
      
      maxAmplitude = max(maxAmplitude, amplitude);

      int bandStartX = (int) map(frequency, 0, Runtime.maximumVisualFrequency(), 0, adjustedWidth());
      int bandLengthY = (int) map(amplitude, 0, maxAmplitude, 0, height);

      stroke(0, 0, 0, 0);
      fill(255);
      rect(bandStartX, height - bandLengthY, bandLengthX, bandLengthY);
    }
  }
  
  private void showAnalyzer() {
    // Establishes relevant X and Y coordinates.
    int lowerFrequencyX =         (int) map(analyzer.lowerFrequencyBound,       0, Runtime.maximumVisualFrequency(), 0,      adjustedWidth());
    int upperFrequencyX =         (int) map(analyzer.upperFrequencyBound,       0, Runtime.maximumVisualFrequency(), 0,      adjustedWidth());
    int detectedFrequencyX =      (int) map(analyzer.frequencyFinderDetection,  0, Runtime.maximumVisualFrequency(), 0,      adjustedWidth());
    int recordedLoudnessY =       (int) map(analyzer.recordedLoudness,          0, analyzer.totalMaxLoudness,        height, 0);
    int triggerLoudnessY =        (int) map(analyzer.triggerLoudness,           0, analyzer.totalMaxLoudness,        height, 0);
    int averageLoudnessY =        (int) map(analyzer.averageLoudness,           0, analyzer.totalMaxLoudness,        height, 0);
    int recentMaxLoudnessY =      (int) map(analyzer.recentMaxLoudness,         0, analyzer.totalMaxLoudness,        height, 0);
    int minimumTriggerLoudnessY = (int) map(analyzer.minimumTriggerLoudness,    0, analyzer.totalMaxLoudness,        height, 0);
    
    // Draws the frequency range in magenta.
    fill(255, 0, 200, 80);
    rect(lowerFrequencyX, 0, upperFrequencyX - lowerFrequencyX, height);

    // Draws the detected frequency in purple.
    strokeWeight(3);
    stroke(110, 20, 200);
    line(detectedFrequencyX, 0, detectedFrequencyX, height);

    // Draws the recorded loudness in white.
    strokeWeight(4);
    stroke(255, 255, 255);
    line(0, recordedLoudnessY, adjustedWidth(), recordedLoudnessY);

    // Draws the average loudness in red.
    stroke(255, 0, 0, 100);
    line(0, averageLoudnessY, adjustedWidth(), averageLoudnessY);

    // Draws the trigger loudness in green.
    stroke(0, 255, 0);
    line(0, triggerLoudnessY, adjustedWidth(), triggerLoudnessY);
    
    // Draws the recent maximum loudness in grey.
    stroke(100);
    line(0, recentMaxLoudnessY, adjustedWidth(), recentMaxLoudnessY);

    // Draws the minimum trigger loudness in blue.
    stroke(0, 0, 255, 100);
    line(0, minimumTriggerLoudnessY, adjustedWidth(), minimumTriggerLoudnessY);
    
    // Draws the trigger pane.
    noStroke();
  
    Set<Integer> highLasers = lasers.lastOutput;
    
    int spacing = 5;
    int paneWidth = Math.round((adjustedWidth() - spacing) / max(Runtime.laserPins().size(), 1));
      
    for (int laser = 0; laser < Runtime.laserPins().size(); laser++) {
      if (!highLasers.contains(laser)) { continue; }
      
      fill(lasers.timedOut ? #87712B : #FEE12B);
      rect((laser * paneWidth) + spacing, spacing, paneWidth - spacing, 35, 7);
    }
  }
  
  private void showBPMAnalysis() {
    // Establishes relevant X and Y coordinates.
    float averageDeviation = bpmFinder.averageRelativeDeviation();
    int averageDeviationY = (int) map(averageDeviation, 1, 0, height, 0);
    int deviationTargetY = (int) map(Runtime.maximumBPMPatternMAD(), 1, 0, height, 0);
          
    // Draws the target deviation zone.
    noStroke();
    fill(200);
    rect(adjustedWidth(), 0, width - adjustedWidth(), deviationTargetY);
    
    // Draws the average deviation in red to green.
    fill(255 * averageDeviation * 1.5, 255 * (1 - averageDeviation), 50 * (1 - averageDeviation), 200);
    rect(adjustedWidth(), averageDeviationY, width - adjustedWidth(), height - averageDeviationY);
    
    // Draws 10% marks.
    stroke(180);
    strokeWeight(2);
    for (float percentage = 10; percentage <= 90; percentage += 10) {
        int y = (int) ((percentage / 100f) * (float) height);
        line(adjustedWidth(), y, adjustedWidth() + 15, y);
    }
    
    // Draws the BPM-value.
    fill(255);
    text((int) bpmFinder.estimatedBPM(), adjustedWidth() + 8, height - 20);
         
    // Draws a seperator to the rest of the visualizations.
    stroke(255);
    strokeWeight(3);
    line(adjustedWidth(), 0, adjustedWidth(), height);
  }

  private void showState() {
    String stateString = "";
    switch (State.inputSource) {
      case none:     stateString = "Keine"; break;
      case analyzer: stateString = "Beat-Erkennung"; break;
      case mouse:    stateString = "Maus"; break;
    }
    
    fill(255);    
    text("Inputquelle: " + stateString, 10, 70);
    
    if (State.inputSource == InputSource.mouse) {     
      switch (State.mouseMode) {
        case allOff: stateString = "Alle Laser aus"; break;
        case allOn:  stateString = "Alle Laser an"; break;
        case wheel:  stateString = "Muster durch Mausrad"; break;
      }
      
      text("Maus Modus: " + stateString, 10, 100);  
    }
  }
}
