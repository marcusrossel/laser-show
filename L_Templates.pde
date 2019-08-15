//-SERVER------------------------------------------------------------//


interface Server {
  
  // A buffer can be expected to contain 1024 samples. The fft object will already be forwarded. 
  void processChunk(AudioBuffer buffer, FFT fft);
  
  void showOutput(Boolean show);

  // Server(Configuration configuration, Arduino arduino);
}


//-SERVER-VISUALIZER-------------------------------------------------//


interface ServerVisualizer {
  
  void showServerProperties();
  
  // ServerVisualizer(Server server)
}


//-STANDARD-SERVER---------------------------------------------------//


class StandardServer implements Server {
  
  Configuration configuration;
  Arduino arduino;
  
  StandardServer(Configuration configuration, Arduino arduino) {
    this.configuration = configuration;
    this.arduino = arduino;
  }
  
  Boolean showOutput = true;
  
  Boolean didTrigger = false;
  Boolean didTriggerOnLastChunk = false;
  
  Float recordedLoudness = 0f;
  Float totalMaxLoudness = 0f;
  Float recentMaxLoudness = 0f;
  
  Float lowerBound = 0f;
  Float upperBound = 0f;
  
  Float featureValue = 0f;
  
  Float frequencyFinderCenter = 0f;
  
  TimedQueue featureHistory = new TimedQueue(0f);
  TimedQueue maxLoudnessHistory = new TimedQueue(0f);
  
  FrequencyFinder frequencyFinder = new FrequencyFinder(0f, 20000f);
  
  Float absoluteLowerBound()         { return (Float) configuration.valueForTrait("Lower Frequency Bound"); }
  Float absoluteUpperBound()         { return (Float) configuration.valueForTrait("Upper Frequency Bound"); }
  
  Float featureWindowSize()          { return (Float) configuration.valueForTrait("Feature Window Size"); }
  Float triggerTreshold()            { return (Float) configuration.valueForTrait("Trigger Threshold"); }
  
  Float maxLoudnessWindowSize()      { return (Float) configuration.valueForTrait("Maximum Loudness Window Size"); }
  Float minimalTriggerThreshold()    { return (Float) configuration.valueForTrait("Minimal Trigger Threshold"); }
  
  List<Integer> outputPins()         { return (List<Integer>) configuration.valueForTrait("Output Pins"); }
  
  Boolean useFrequencyFinder()       { return (Boolean) configuration.valueForTrait("Use Frequency Finder"); }
  Float frequencyFinderRange()       { return (Float) configuration.valueForTrait("Frequency Finder Range"); }
  Float frequencyFinderMax()         { return (Float) configuration.valueForTrait("Frequency Finder Maximum"); }
  Float frequencyFinderWindowSize()  { return (Float) configuration.valueForTrait("Frequency Finder Window Size"); }  
  
  void processChunk(AudioBuffer buffer, FFT fft) {
    // Passes down whether or not the last chunk did trigger.
    didTriggerOnLastChunk = didTrigger;
    
    featureHistory.retentionDuration = featureWindowSize();
    maxLoudnessHistory.retentionDuration = maxLoudnessWindowSize();
    
    if (useFrequencyFinder()) {
      frequencyFinder.setHistoryInterval(frequencyFinderWindowSize());
      frequencyFinder.maxFrequency = frequencyFinderMax();
      
      lowerBound = max(frequencyFinderCenter - (frequencyFinderRange() / 2), 0); 
      upperBound = min(frequencyFinderCenter + (frequencyFinderRange() / 2), 20000); 
    } else {
      lowerBound = absoluteLowerBound();
      upperBound = absoluteUpperBound();
    }
    
    recordedLoudness = bandLoudnessForChunk(fft, lowerBound, upperBound);
    featureHistory.push(recordedLoudness);
    
    maxLoudnessHistory.push(recordedLoudness);
    recentMaxLoudness = maxLoudnessHistory.max();
    
    totalMaxLoudness = max(totalMaxLoudness, recordedLoudness);
  }
  
  void updateOutput(Boolean trigger) {    
    // Progresses the current pattern, if patterns are being used.
    if (trigger && !didTriggerOnLastChunk && INPUT_STATE == InputState.automatic) { patterns.step(); }

    // Updates the output pins' states if necessary.
    if (arduino != null) {
      patterns.applyStateToArduino(arduino); 
    }
  }
  
  void showOutput(Boolean show) { showOutput = show; }
}
