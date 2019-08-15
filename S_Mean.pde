final class S_Mean extends StandardServer {

  public S_Mean(Configuration configuration, Arduino arduino) { super(configuration, arduino); }

  // featureValue = recentAverageLoudness

  void processChunk(AudioBuffer buffer, FFT fft) {
    super.processChunk(buffer, fft);
    
    featureValue = featureHistory.average();
    
    Float triggerLoudness = max(minimalTriggerThreshold() * recentMaxLoudness, triggerTreshold() * featureValue);
    
    frequencyFinderCenter = frequencyFinder.pushChunk(fft, triggerLoudness);
  
    didTrigger = (recordedLoudness > triggerLoudness);

    super.updateOutput(didTrigger);
  }
}
