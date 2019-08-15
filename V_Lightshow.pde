final class Visualizer {

  // Records the highest and lowest amplitudes the visualizer has ever displayed.
  Float maxAmplitude = 0f;
  Float minAmplitude = 0f;

  // Records the highest intensity of a frequency ever measured.
  Float maxIntensity = 0f;

  void showWaveformForChunk(AudioBuffer chunk) {
    Integer sampleCount = chunk.size();

    strokeWeight(1);
    stroke(255, 255, 255, 50);
    for (Integer sample = 0; sample < sampleCount; sample++) {
      Float amplitude = chunk.get(sample);

      maxAmplitude = max(maxAmplitude, amplitude);
      minAmplitude = min(minAmplitude, amplitude);

      float sampleOffset = map(sample, 0, sampleCount - 1, 0, width);
      float amplitudeOffset = map(amplitude, minAmplitude, maxAmplitude, height, 0);

      line(sampleOffset, height / 2, sampleOffset, amplitudeOffset);
    }
  }

  void showSpectrumForChunk(FFT chunk, Boolean withAWeighting) {
    strokeWeight(1);
    // Draws 100Hz marks.
    for (int f = 100; f < MAX_FREQ; f += 100) {
      if (f % 500 == 0) { stroke(100); } else { stroke(40); };
      Integer x = (int) map(f, 0, MAX_FREQ, 0, width);
      line(x, 0, x, height); 
    }
    
    Integer bandCount = (int) ((float)MAX_FREQ / chunk.getBandWidth());
    Integer bandLengthX = width / bandCount;

    // Draws the band intensities.
    for (Integer band = 0; band <= bandCount; band++) {
      Float frequency = chunk.indexToFreq(band);
      Float intensity = chunk.getBand(band) * (withAWeighting ? aWeightedFrequency(frequency) : 1);
      
      maxIntensity = max(maxIntensity, intensity);

      Integer bandStartX = (int) (map(frequency, 0, MAX_FREQ, 0, width));
      Integer bandLengthY = (int) (map(intensity, 0, maxIntensity, 0, height));

      stroke(0, 0, 0, 0); fill(255);
      rect(bandStartX, height - bandLengthY, bandLengthX, bandLengthY);
    }
  }
}
