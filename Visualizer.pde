import java.awt.Point;

final class Visualizer {

  // Records the highest intensity of a frequency ever measured.
  float maxAmplitude = 0f;
  
  // Needed for analyzer history visualization.
  TimedQueue loudnessHistory = new TimedQueue(0f);
  TimedQueue averageHistory = new TimedQueue(0f);
  TimedQueue thresholdHistory = new TimedQueue(0f);
  TimedQueue recentMaxHistory = new TimedQueue(0f);
  TimedQueue thresholdMinHistory = new TimedQueue(0f);
  
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
  
  private List<TimedQueue> allHistories() {
    return Arrays.asList(loudnessHistory, averageHistory, thresholdHistory, recentMaxHistory, thresholdMinHistory);
  }
  
  private int adjustedWidth() {
    return Runtime.visualizeBPMFinder() ? int(0.95 * width) : width; 
  }
  
  private void showSpectrum(FFT chunk) {
    // Draws 200Hz marks.
    strokeWeight(1);
    for (int frequency = 200; frequency < Runtime.maximumVisualFrequency(); frequency += 200) {
      if (frequency % 1000 == 0) { stroke(100); } else { stroke(40); };
      int x = (int) map(frequency, 0, Runtime.maximumVisualFrequency(), 0, adjustedWidth());
      line(x, 0, x, height); 
    }
    
    int bandCount = int(float(Runtime.maximumVisualFrequency()) / chunk.getBandWidth());
    int bandLengthX = Math.round((float) adjustedWidth() / (float) bandCount);
    
    int lowerFrequencyFinderBand = Math.round(map(analyzer.lowerFrequencyBound, 0, Runtime.maximumVisualFrequency(), 0, bandCount));
    int upperFrequencyFinderBand = Math.round(map(analyzer.upperFrequencyBound, 0, Runtime.maximumVisualFrequency(), 0, bandCount));
    int detectedFrequencyFinderBand = Math.round(map(analyzer.frequencyFinderDetection, 0, Runtime.maximumVisualFrequency(), 0, bandCount));

    noStroke();

    // Draws the band intensities.
    for (int band = 0; band <= bandCount; band++) {
      int xOffset = Math.round((adjustedWidth() - bandLengthX) * band / (float) bandCount);
      
      float amplitude = chunk.getBand(band);
      maxAmplitude = max(maxAmplitude, amplitude);
      
      int bandLengthY = (int) map(amplitude, 0, maxAmplitude, 0, height);

      if (band == detectedFrequencyFinderBand) {
        fill(220, 100, 240);
      } else if (band >= lowerFrequencyFinderBand && band <= upperFrequencyFinderBand) {
        fill(220, 190, 240);
      } else {
        fill(100);  
      }
      
      rect(xOffset, height - bandLengthY, bandLengthX, bandLengthY);
    }
  }
  
  private void showAnalyzer() {    
    for (TimedQueue history : allHistories()) {
      history.retentionDuration = Runtime.visualizationHistory();
    }

    loudnessHistory.push(analyzer.recordedLoudness);
    averageHistory.push(analyzer.averageLoudness);
    thresholdHistory.push(analyzer.triggerLoudness);
    recentMaxHistory.push(analyzer.recentMaxLoudness);
    thresholdMinHistory.push(analyzer.minimumTriggerLoudness);
    
    List<List<Point>> historyLines = new ArrayList<List<Point>>();
    for (TimedQueue history : allHistories()) {
      historyLines.add(pointsForHistory(history));
    }
    
    color[] lineColors = {
      color(255, 255, 255),
      color(255, 165, 0, 150),
      color(0, 255, 0),
      color(100),
      color(0, 100, 255, 150)
    };

    strokeWeight(3);
    for (int historyIndex = 0; historyIndex < allHistories().size(); historyIndex++) {
      List<Point> line = pointsForHistory(allHistories().get(historyIndex));
      if (line.size() < 2) { break; }
      
      stroke(lineColors[historyIndex]);
      
      // Needed to connect NaN-points (meaning [y = -1]-points).
      Point lastGoodPoint = line.get(0);
      
      for (int pointIndex = 1; pointIndex < line.size(); pointIndex++) {
        // Point 1 is older than point 2.
        Point point1 = line.get(pointIndex - 1);
        Point point2 = line.get(pointIndex);
        
        // Draws segments that have a y-value of -1 as straight line between the enclosing "normal" points in a red color.
        // Y-values of -1 are produced by the pointsForHistory method, when a value is NaN.
        // A normal case when this occurs is when the trigger threshold is set to NaN as a result of bpm-limitation.
        
        if (point1.y != -1 && point2.y == -1) /*Transition from normal to NaN values.*/ {
          lastGoodPoint = point1;
        } else if (point1.y == -1 && point2.y == -1) /*Mid NaN values.*/ {
          // Draws a horizontal line if the mid-NaN passage is at the very end of the history (the newset thing happening).
          if (point2.x == 0) {
            stroke(200, 20, 30, 150);
            line(lastGoodPoint.x, lastGoodPoint.y, point2.x, lastGoodPoint.y);
            stroke(lineColors[historyIndex]);
          }
        } else if (point1.y == -1 && point2.y != -1) /*Transition from NaN to normal values.*/ {
          // Doesn't draw the transition if it's from a NaN-segement that's at the very beginning of the history (oldest thing), because then the lastGoodPoint is no help.
          // This state can be detected by checking if the lastGoodPoint has changed to something other that line-get(0) yet.
          // If not, we have not had a proper transition from normal values to NaN-values -> we are starting with a NaN-segment. 
          if (lastGoodPoint != line.get(0)) {
            stroke(200, 20, 30, 150);
            line(lastGoodPoint.x, lastGoodPoint.y, point2.x, point2.y);
            stroke(lineColors[historyIndex]);
          }
        } else /*Mid normal values.*/ {
          line(point1.x, point1.y, point2.x, point2.y);
        }
      }
    }
    
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
  
  // If any value is NaN the corresponding y-point will be -1.
  private List<Point> pointsForHistory(TimedQueue history) {
    List<Float> values = history.getValues();
    List<Integer> timeStamps = history.getTimeStamps();
    
    if (values.isEmpty()) { return new ArrayList<Point>(); }
    
    int historyDurationMillis = int(Runtime.visualizationHistory() * 1000);
    int timeStampOffset = timeStamps.get(timeStamps.size() - 1) - historyDurationMillis;
    
    List<Point> points = new ArrayList<Point>();
    
    for (int index = 0; index < timeStamps.size(); index++) {
      int y = values.get(index).isNaN() ? -1 : ((int) map(values.get(index), 0, analyzer.totalMaxLoudness, height, 0));        
      int x = Math.round(map(timeStamps.get(index) - timeStampOffset, 0, historyDurationMillis, adjustedWidth(), 0));
      
      points.add(new Point(x, y));
    }
    
    return points;
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
  
  // For debugging.
  void printMemoryUsage() {
    print("loudness history:\t");
    loudnessHistory.printMemoryUsage();
    print("average history:\t");
    averageHistory.printMemoryUsage();
    print("threshold history:\t");
    thresholdHistory.printMemoryUsage();
    print("recent max history:\t");
    recentMaxHistory.printMemoryUsage();
    print("threshold min history:\t");
    thresholdMinHistory.printMemoryUsage();
  }
}
