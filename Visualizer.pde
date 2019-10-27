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
    if (Runtime.visualizeBPMFinder()) { showBPM(); }
    if (Runtime.visualizeState())     { showState(); }
  }
  
  private void showSpectrum(FFT chunk) {
    // Draws 100Hz marks.
    strokeWeight(1);
    for (int frequency = 100; frequency < Runtime.maximumVisualFrequency(); frequency += 100) {
      if (frequency % 500 == 0) { stroke(100); } else { stroke(40); };
      int x = (int) map(frequency, 0, Runtime.maximumVisualFrequency(), 0, width);
      line(x, 0, x, height); 
    }
    
    int bandCount = (int) ((float) Runtime.maximumVisualFrequency() / chunk.getBandWidth());
    int bandLengthX = width / bandCount;

    // Draws the band intensities.
    for (int band = 0; band <= bandCount; band++) {
      float frequency = chunk.indexToFreq(band);
      float amplitude = chunk.getBand(band);
      
      maxAmplitude = max(maxAmplitude, amplitude);

      int bandStartX = (int) map(frequency, 0, Runtime.maximumVisualFrequency(), 0, width);
      int bandLengthY = (int) map(amplitude, 0, maxAmplitude, 0, height);

      stroke(0, 0, 0, 0);
      fill(255);
      rect(bandStartX, height - bandLengthY, bandLengthX, bandLengthY);
    }
  }
  
  private void showAnalyzer() {
    // Establishes relevant X and Y coordinates.
    int lowerFrequencyX =         (int) map(analyzer.lowerFrequencyBound,       0, Runtime.maximumVisualFrequency(), 0,      width);
    int upperFrequencyX =         (int) map(analyzer.upperFrequencyBound,       0, Runtime.maximumVisualFrequency(), 0,      width);
    int detectedFrequencyX =      (int) map(analyzer.frequencyFinderDetection,  0, Runtime.maximumVisualFrequency(), 0,      width);
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
    line(0, recordedLoudnessY, width, recordedLoudnessY);

    // Draws the average loudness in red.
    stroke(255, 0, 0, 100);
    line(0, averageLoudnessY, width, averageLoudnessY);

    // Draws the trigger loudness in green.
    stroke(0, 255, 0);
    line(0, triggerLoudnessY, width, triggerLoudnessY);
    
    // Draws the recent maximum loudness in grey.
    stroke(100);
    line(0, recentMaxLoudnessY, width, recentMaxLoudnessY);

    // Draws the minimum trigger loudness in blue.
    stroke(0, 0, 255, 100);
    line(0, minimumTriggerLoudnessY, width, minimumTriggerLoudnessY);
    
    // Draws the trigger pane.
    noStroke();
  
    Set<Integer> highLasers = lasers.lastOutput;
    
    int spacing = 5;
    int paneWidth = Math.round((width - spacing) / max(Runtime.laserPins().size(), 1));
      
    for (int laser = 0; laser < Runtime.laserPins().size(); laser++) {
      if (!highLasers.contains(laser)) { continue; }
      
      fill(lasers.timedOut ? #87712B : #FEE12B);
      rect((laser * paneWidth) + spacing, spacing, paneWidth - spacing, 35, 7);
    }
  }
  
  private void showBPM() {
    fill(255);
    text("Geschätzte BPM: " + (int) bpmFinder.estimatedBPM() +
         " (Δt = " + (int) bpmFinder.averageFiringDelay() +
         "ms) (MAD = " + (int) bpmFinder.meanAbsoluteDeviation() +
         "ms = " + String.format("%.2f", 100 * bpmFinder.relativeDeviation()) + "%)",
         10, 150);
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
