final class TimedQueue {

  TimedQueue(float retentionDuration) {
    this.retentionDuration = retentionDuration;
    noValues = false;
  }
  
  TimedQueue(float retentionDuration, boolean noValues) {
    this.retentionDuration = retentionDuration;
    this.noValues = noValues;
  }

  private boolean noValues;
  private List<Float> values = new ArrayList<Float>();
  private List<Integer> timeStamps = new ArrayList<Integer>();
  
  // This property is supposed to be setable.
  float retentionDuration; // in seconds

  private int startOfRelevantHistory() {
    if (timeStamps.isEmpty()) { return -1; }
    
    int now = millis();

    // Gets the index of the oldest time stamp not older than the retention duration. If there is none, -1 is returned.
    int index = 0;
    while (now - timeStamps.get(index) > retentionDuration * 1000) {
      index++;
      if (index == timeStamps.size()) { return -1; }
    }
    
    return index;
  }
  
  List<Integer> getTimeStamps() {
    int startIndex = startOfRelevantHistory();
    if (startIndex < 0) { return new ArrayList<Integer>(); }
    
    return timeStamps.subList(startIndex, timeStamps.size() - 1);
  }
  
  List<Float> getValues() {
    int startIndex = startOfRelevantHistory();
    if (startIndex < 0) { return new ArrayList<Float>(); }
    
    return values.subList(startIndex, values.size() - 1);
  }

  void push(float value) {
    int now = millis();
 
    if (!noValues) { values.add(value); }
    timeStamps.add(now);

    // Removes the values that are older than the retention duration.
    // Removal only happens once at least 500 values have accumulated. This is done to reduce the runtime cost of reallocating array memory. 
    if (timeStamps.size() > 500) {
      // Removes the values only if the oldest recorded value is at least (2 * retention duration) old.
      // The factor 1000 converts the rentation duration from seconds to milliseconds. 
      if (now - timeStamps.get(0) > (2 * retentionDuration * 1000)) {
        int startIndex = startOfRelevantHistory();
    
        if (startIndex < 0) {
          if (!noValues) { values = new ArrayList(); }
          timeStamps = new ArrayList();
        } else {
          if (!noValues) { values = values.subList(startIndex, values.size() - 1); }
          timeStamps = timeStamps.subList(startIndex, timeStamps.size() - 1);
        }
      }
    }
  }
    
  float average() {
    if (noValues) { return Float.NaN; }
    
    int startIndex = startOfRelevantHistory();
    if (startIndex < 0) { return 0; }
  
    int sizeOfRelevantHistory = values.size() - startIndex;

    float sum = 0f;
    for (int index = startIndex; index < values.size(); index++) {
      sum += values.get(index);
    }
    
    return sum / sizeOfRelevantHistory;
  }
  
  float max() {
    if (noValues) { return Float.NaN; }
    
    int startIndex = startOfRelevantHistory();
    if (startIndex < 0) { return 0; }
    
    float max = 0f;
    for (int index = startIndex; index < values.size(); index++) {
      max = Math.max(max, values.get(index)); 
    }
    
    return max;
  }
  
  // For debugging.
  void printMemoryUsage() {
    if (!noValues) { print("values: " + values.size() + "\t"); }
    println("time stamps: ", timeStamps.size());  
  }
}
