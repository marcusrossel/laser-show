final class S_Max extends StandardServer {
  
  public S_Max(Configuration configuration, Arduino arduino) { super(configuration, arduino); }
    
  // featureValue = recentAverageMaximum

  void processChunk(AudioBuffer buffer, FFT fft) {
    super.processChunk(buffer, fft);
    
    featureValue = featureHistory.averageOfMaxima();
    
    Float triggerLoudness = max(minimalTriggerThreshold() * recentMaxLoudness, triggerTreshold() * featureValue);
    
    frequencyFinderCenter = frequencyFinder.pushChunk(fft, triggerLoudness);
    
    didTrigger = (recordedLoudness > triggerLoudness);

    super.updateOutput(didTrigger);
  }
}
