// TODO: Try hyper local BPM. 

final class BPMFinder {
  
  private final float someFloat = 0;
  
  private TimedQueue triggerHistory = new TimedQueue(0f);
  
  void recordFiring() {
    triggerHistory.retentionDuration = Runtime.bpmFinderHistory();
    triggerHistory.push(someFloat);  
  }
  
  float averageFiringDelay() {
    return triggerHistory.averageMillisBetweenElements(); 
  }
  
  float estimatedBPM() {
     return 60000f / averageFiringDelay();
  }
}
