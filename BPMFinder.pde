final class BPMFinder {
  
  private boolean didSmoothDelay = false;
  
  private TimedQueue triggerHistory = new TimedQueue(0f, /*noValues*/ true);
  private TimedQueue deviationHistory = new TimedQueue(0f);
  
  void recordFiring() {
    triggerHistory.push(Float.NaN); 
    deviationHistory.push(relativeDeviation());
  }
  
  float averageFiringDelay() {
    triggerHistory.retentionDuration = Runtime.bpmFinderDelayHistory();
    deviationHistory.retentionDuration = Runtime.bpmFinderDeviationHistory();
    
    List<Integer> timeStamps = triggerHistory.getTimeStamps();
    if (timeStamps.size() < 2) { return 0; }
       
    int sum = 0;
    for (int index = 1; index < timeStamps.size(); index++) {
      sum += (timeStamps.get(index) - timeStamps.get(index - 1));
    }
    
    float averageDelay = float(sum)/ (timeStamps.size() - 1);
    
    // If this were not here, the average firing delay would only ever update with every new firing.
    // This way, there's a smooth transition between the values.
    int now = millis();
    int timeSinceLastFiring = now - timeStamps.get(timeStamps.size() - 1);
    if (timeSinceLastFiring > (Runtime.bpmFinderSmoothingDelay() * averageDelay)) {
      didSmoothDelay = true;
      
      sum += now;
      averageDelay = float(sum) / timeStamps.size();
    } else {
      didSmoothDelay = false;  
    }
    
    return averageDelay;
  }
  
  float estimatedBPM() {
    float averageDelay = averageFiringDelay();
    return (averageDelay != 0) ? (60000f / averageDelay) : Float.NaN;
  }
  
  // https://en.wikipedia.org/wiki/Average_absolute_deviation#Mean_absolute_deviation_around_a_central_point
  float meanAbsoluteDeviation() {
    List<Integer> timeStamps = triggerHistory.getTimeStamps();    
    if (timeStamps.size() < 2) { return 0; }
    
    final float mean = averageFiringDelay();
    if (mean == 0) { return 0; }
    
    float differenceSum = 0;
    
    for (int index = 1; index < timeStamps.size(); index++) {
      int delta = timeStamps.get(index) - timeStamps.get(index - 1);
      differenceSum += abs(delta - mean);
    }
    
    // This is to match the smoothing behaviour in averageFiringDelay().
    if (didSmoothDelay) {
      differenceSum += abs((millis() - timeStamps.get(timeStamps.size() - 1)) - mean);
    }
    
    float deviation = differenceSum / (timeStamps.size() - (didSmoothDelay ? 0 : 1));    
    return deviation;
  }
  
  float relativeDeviation() {
    float averageDelay = averageFiringDelay();
    return (averageDelay != 0) ? (meanAbsoluteDeviation() / averageDelay) : 1;   
  }
  
  float averageRelativeDeviation() {
    return deviationHistory.average();
  }
  
  // For debugging.
  void printMemoryUsage() {
    print("trigger history:\t");
    triggerHistory.printMemoryUsage();
    print("deviation history:\t");
    deviationHistory.printMemoryUsage();
  }
}
