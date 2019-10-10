final class Analyzer {
  
  private boolean didTrigger = false;
  private boolean didTriggerOnLastChunk = false;
  private int timeOfLastTrigger = 0;
  
  private TimedQueue loudnessHistory = new TimedQueue(0f);
  private TimedQueue maxLoudnessHistory = new TimedQueue(0f);
  private FrequencyFinder frequencyFinder = new FrequencyFinder();
  
  float recordedLoudness = 0f;
  float triggerLoudness = 0f;
  float minimumTriggerLoudness = 0f;
  float averageLoudness = 0f;
  float recentMaxLoudness = 0f;
  float totalMaxLoudness = 0f;
  
  float lowerFrequencyBound = 0f;
  float upperFrequencyBound = 0f;
  float frequencyFinderDetection = 0f;
  
  boolean fired() { return didTrigger && !didTriggerOnLastChunk; }
  
  void processChunk(FFT fft) {
    // Updateso frequency bounds (and more).
    prepareProcessing(); 
    
    recordedLoudness = bandLoudnessForChunk(fft, lowerFrequencyBound, upperFrequencyBound);
    
    // Updates triggerLoudness (and more).
    updateLoudnessDependantVariables();
  
    float minimumDelay = (60000f / Runtime.maximumBPM()); 
    boolean maxBPMDurationWasPassed = (millis() - timeOfLastTrigger) > minimumDelay;
    didTrigger = (recordedLoudness > triggerLoudness) && maxBPMDurationWasPassed;
    
    updateTriggerDependantVariables();
  }
  
  private void prepareProcessing() {
    didTriggerOnLastChunk = didTrigger;
    
    loudnessHistory.retentionDuration = Runtime.averageHistory();
    maxLoudnessHistory.retentionDuration = Runtime.maximumLoudnessHistory();
    
    frequencyFinder.processChunk(fft);
    frequencyFinderDetection = frequencyFinder.detectedFrequency();
    
    int frequencyOffset = Runtime.frequencyRange() / 2;
    lowerFrequencyBound = max(frequencyFinderDetection - frequencyOffset, 0); 
    upperFrequencyBound = min(frequencyFinderDetection + frequencyOffset, 20000);
  }
  
  private void updateLoudnessDependantVariables() {    
    maxLoudnessHistory.push(recordedLoudness);
    recentMaxLoudness = maxLoudnessHistory.max();
    
    totalMaxLoudness = max(totalMaxLoudness, recordedLoudness);
    
    loudnessHistory.push(recordedLoudness);
    
    averageLoudness = loudnessHistory.average();
    
    minimumTriggerLoudness = Runtime.minimalTriggerThreshold() * recentMaxLoudness;
    
    triggerLoudness = max(minimumTriggerLoudness, Runtime.triggerThreshold() * averageLoudness);
  }
  
  private void updateTriggerDependantVariables() {
    if (didTrigger) { timeOfLastTrigger = millis(); }  
  }
  
  // Gets the chunk's loudness via root-mean-square, within the given frequency bounds.
  private float bandLoudnessForChunk(FFT fft, float lowerBound, float upperBound) {
    int lowestBand = Math.round(lowerBound / fft.getBandWidth());
    int highestBand = Math.round(upperBound / fft.getBandWidth());
    int bandCount = highestBand - lowestBand;

    if (bandCount < 1) { return 0f; }

    float squareIntensitySum = 0f;
    for (int band = lowestBand; band <= highestBand; band++) {
      float intensity = fft.indexToFreq(band) * fft.getBand(band);
      squareIntensitySum += pow(intensity, 2);
    }

    float rootMeanSquare = sqrt(squareIntensitySum / bandCount);

    return rootMeanSquare;
  }
  
  // For debugging.
  void printState() {
    println();
    println("Recorded Loudness:\t\t", (int) recordedLoudness);
    println("Trigger Loudness:\t\t", (int) triggerLoudness);
    println("Minimum Trigger Loudness:\t", (int) minimumTriggerLoudness);
    println("Average Loudness:\t\t", (int) averageLoudness);
    println("Recent Max Loudness:\t\t", (int) recentMaxLoudness);
    println("Total Max Loudness:\t\t", (int) totalMaxLoudness);
    println("Lower Frequency Bound:\t\t", (int) lowerFrequencyBound);
    println("Upper Frequency Bound:\t\t", (int) upperFrequencyBound);
    println("Frequency Finder Detection:\t", (int) frequencyFinderDetection);
    println("Did Trigger (On Last Chunk):\t", didTrigger, "(" + didTriggerOnLastChunk + ")");
    println("Fired:\t\t\t\t", fired());
  }
  
  // For debugging.
  void printMemoryUsage() {
    print("loudness history:\t");
    loudnessHistory.printMemoryUsage();
    print("max loudness history:\t");
    maxLoudnessHistory.printMemoryUsage();
    print("frequency finder:\t");
    frequencyFinder.printMemoryUsage();
  }
}
