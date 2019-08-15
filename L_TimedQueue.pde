final class TimedQueue {

  TimedQueue(Float retentionDuration) {
    this.retentionDuration = retentionDuration;
  }

  private List<Float> values = new ArrayList<Float>();
  private List<Integer> timeStamps = new ArrayList<Integer>();
  
  // This property is supposed to be setable.
  Float retentionDuration; // in seconds

  private List<Float> relevantHistory() {
    if (timeStamps.isEmpty()) { return new ArrayList<Float>(); }
    
    Integer now = millis();

    // Gets the index of the oldest time stamp not older than the retention duration. If there is none, an empty array is returned.
    Integer index = 0;
    while (now - timeStamps.get(index) > retentionDuration * 1000) {
      index++;
      if (index == timeStamps.size()) { return new ArrayList<Float>(); }
    }

    return values.subList(index, values.size() - 1);
  }

  void push(Float value) {
    Integer now = millis();
 
    values.add(value);
    timeStamps.add(now);

    // Removes the values that are older than the retention duration.
    // Removal only happens once at least 500 values have accumulated. This is done to reduce the runtime cost of reallocating array memory. 
    if (values.size() > 500) {
      // Removes the values only if the oldest recorded value is at least (2 * retention duration) old.
      // The factor 1000 converts the rentation duration from seconds to milliseconds. 
      if (now - timeStamps.get(0) > (2 * retentionDuration * 1000)) {
        values = relevantHistory();
        timeStamps = timeStamps.subList(timeStamps.size() - values.size() - 1, timeStamps.size() - 1);
      }
    }
  }
    
  Float average() {
    List<Float> currentHistory = relevantHistory();
    if (currentHistory.isEmpty()) { return 0f; }

    Float sum = 0f;
    for (Float value: currentHistory) {
      sum += value;
    }
    
    return sum / currentHistory.size();
  }
  
  Float max() {
    List<Float> currentHistory = relevantHistory();
    if (currentHistory.isEmpty()) { return 0f; }
    
    Float max = 0f;
    for (Float value: currentHistory) {
      max = Math.max(max, value); 
    }
    
    return max;
  }
  
  Float averageAboveAverage() {
    List<Float> currentHistory = relevantHistory();
    if (currentHistory.isEmpty()) { return 0f; }

    Float sum = 0f; 
    for (Float value: currentHistory) { sum += value; }
    Float average = sum / currentHistory.size();
    
    Float sumAbove = 0f;
    Integer countAbove = 0;
    for (Float value: currentHistory) {
      if (value >= average) { sumAbove += value; countAbove++; }  
    }
    
    return sumAbove / countAbove;
  }
  
  Float averageOfMaxima() {
    List<Float> currentHistory = relevantHistory();
    if (currentHistory.isEmpty()) { return 0f; }
    
    Float sum = 0f;
    Integer count = 0;
    
    Float preLastValue = 0f;
    Float lastValue = 0f;
    
    for (Float value: currentHistory) {
      if (lastValue > preLastValue && lastValue > value) {
        sum += lastValue;
        count++;
      }
      
      preLastValue = lastValue;
      lastValue = value;
    }
    
    
    return sum / count;
  }
}
