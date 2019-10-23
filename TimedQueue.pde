final class TimedQueue {

  TimedQueue(float retentionDuration) {
    this.retentionDuration = retentionDuration;
  }

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

  void push(float value) {
    int now = millis();
 
    values.add(value);
    timeStamps.add(now);

    // Removes the values that are older than the retention duration.
    // Removal only happens once at least 500 values have accumulated. This is done to reduce the runtime cost of reallocating array memory. 
    if (values.size() > 500) {
      // Removes the values only if the oldest recorded value is at least (2 * retention duration) old.
      // The factor 1000 converts the rentation duration from seconds to milliseconds. 
      if (now - timeStamps.get(0) > (2 * retentionDuration * 1000)) {
        int startIndex = startOfRelevantHistory();
    
        if (startIndex < 0) {
          values = new ArrayList();
          timeStamps = new ArrayList();
        } else {
          values = values.subList(startIndex, values.size() - 1);
          timeStamps = timeStamps.subList(startIndex, timeStamps.size() - 1);
        }
      }
    }
  }
    
  float average() {
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
    int startIndex = startOfRelevantHistory();
    if (startIndex < 0) { return 0; }
    
    float max = 0f;
    for (int index = startIndex; index < values.size(); index++) {
      max = Math.max(max, values.get(index)); 
    }
    
    return max;
  }
  
  float averageMillisBetweenElements() {
    int startIndex = startOfRelevantHistory();
    if (startIndex < 0) { return 0; }
    
    int numberOfRelevantTimeStamps = timeStamps.size() - startIndex;
    if (numberOfRelevantTimeStamps < 2) { return 0; }
    
    int sum = 0;
    for (int index = startIndex + 1; index < timeStamps.size(); index++) {
      sum += (timeStamps.get(index) - timeStamps.get(index - 1));
    }
    
    return ((float) sum) / numberOfRelevantTimeStamps;
  }
  
  // For debugging.
  void printMemoryUsage() {
    println("values: ", values.size(), ",\ttime stamps: ", timeStamps.size());  
  }
}
