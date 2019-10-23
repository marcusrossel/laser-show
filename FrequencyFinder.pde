// TODO: Automatically detect the frequency range as well.

final class FrequencyFinder {
  
  TimedQueue history = new TimedQueue(0f);
  
  void processChunk(FFT fft) {
    history.retentionDuration = Runtime.frequencyFinderHistory();
    history.push(loudestFrequency(fft));
  }
  
  float detectedFrequency() {
    return history.average();  
  }
  
  private float loudestFrequency(FFT fft) {
    int loudestBand = 0;
    float loudestAmplitude = 0f;
    
    int bandCount = (int) (Runtime.frequencyFinderMaximum() / fft.getBandWidth());
    for (int band = 0; band <= bandCount; band++) {
      float amplitude = fft.getBand(band);
      
      if (amplitude > loudestAmplitude) {
         loudestBand = band; 
         loudestAmplitude = amplitude;
      }
    }
    
    return (loudestBand + 1) * fft.getBandWidth();
  }
  
  // For debugging.
  void printMemoryUsage() {
    print("history:\t");
    history.printMemoryUsage();
  }
}
