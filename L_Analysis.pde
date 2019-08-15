//-FREQUENCY-FINDER---------------------------------------------------//


final class FrequencyFinder {
 
  FrequencyFinder(Float historyInterval, Float maxFrequency) {
     history = new TimedQueue(historyInterval);
     this.maxFrequency = maxFrequency;
  }
  
  void setHistoryInterval(Float newValue) {
      history.retentionDuration = newValue;
  }
  
  private TimedQueue history;
  Float maxFrequency;
  
  Float loudestFrequency(FFT fft) {
    Integer loudestBand = 0;
    Float loudestLoudness = 0f;
    
    Integer bandCount = (int) (maxFrequency / fft.getBandWidth());
    for (Integer band = 0; band <= bandCount; band++) {
      Float frequency = fft.indexToFreq(band);
      Float intensity = fft.getBand(band) * aWeightedFrequency(frequency);
      
      if (intensity > loudestLoudness) {
         loudestBand = band; 
         loudestLoudness = intensity;
      }
    }
    
    return (loudestBand + 1) * fft.getBandWidth();
  }
  
  Float pushChunk(FFT fft, Float threshold) {
    Float loudest = loudestFrequency(fft);
    Float loudness = fft.getFreq(loudest) * aWeightedFrequency(loudest);
    if (loudness >= threshold) { history.push(loudest); }
    
    return history.average();
  }
}


//-LOUDNESS-----------------------------------------------------------//


// https://en.wikipedia.org/wiki/A-weighting
// https://github.com/audiojs/a-weighting
Float aWeightedFrequency(Float frequency) {
  // #TEMP  
  if (true) { return 1f; }
  
  Float frequency2 = pow(frequency, 2);
  Float dividend = 1.2588966 * 148840000 * pow(frequency2, 2);
  Float root = sqrt(frequency2 + 11599.29) * (frequency2 + 544496.41);
  Float divisor = ((frequency2 + 424.36) * root * (frequency2 + 148840000));
  return dividend / divisor;
}

// Gets the chunk's loudness via A-weighting and root-mean-square, within the given frequency bounds.
private Float bandLoudnessForChunk(FFT fft, Float lowerBound, Float upperBound) {
  Integer lowestBand = Math.round(lowerBound / fft.getBandWidth());
  Integer highestBand = Math.round(upperBound / fft.getBandWidth());
  Integer bandCount = highestBand - lowestBand;

  if (bandCount < 1) { return 0f; }

  Float aWeightedSquareIntensitySum = 0f;
  for (Integer band = lowestBand; band <= highestBand; band++) {
    Float aWeightedFrequency = aWeightedFrequency(fft.indexToFreq(band));
    Float weightedIntensity = aWeightedFrequency * fft.getBand(band);
    aWeightedSquareIntensitySum += pow(weightedIntensity, 2);
  }

  Float aWeightedRootMeanSquare = sqrt(aWeightedSquareIntensitySum / bandCount);

  return aWeightedRootMeanSquare;
}
