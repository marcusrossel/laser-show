final class S_Mix extends StandardServer {

  public S_Mix(Configuration configuration, Arduino arduino) { super(configuration, arduino); }
  
  // featureValue = recentAverageAboveAverage

  void processChunk(AudioBuffer buffer, FFT fft) {
    super.processChunk(buffer, fft);
    
    featureValue = featureHistory.averageAboveAverage();
    
    Float triggerLoudness = max(minimalTriggerThreshold() * recentMaxLoudness, triggerTreshold() * featureValue);
    
    frequencyFinderCenter = frequencyFinder.pushChunk(fft, triggerLoudness);

    didTrigger = (recordedLoudness > triggerLoudness);

    super.updateOutput(didTrigger);
  }
}
