// Running this program requires the following arguments:
// <Configuration File Path>
// <Arduino Port>


//-IMPORTS-----------------------------------------------------------//


import java.util.*;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.lang.reflect.Constructor;
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.serial.*;
import cc.arduino.*;


//-STATE-OBJECTS-----------------------------------------------------//

enum InputSource {
  none, analyzer, mouse
}

enum MouseMode {
  allOff, allOn, wheel
}

static final class State {
  static InputSource inputSource = InputSource.analyzer;
  static MouseMode mouseMode = MouseMode.wheel; 
}

static Configuration configuration;

static final class Runtime {
  static boolean useBuzzer() {                return (boolean)            configuration.valueForTrait("Use Buzzer")                   ; }
  static boolean useStartDate() {             return (boolean)            configuration.valueForTrait("Use Start Date")               ; }
  static boolean useEndDate() {               return (boolean)            configuration.valueForTrait("Use End Date")                 ; }
  static boolean useBPMFinder() {             return (boolean)            configuration.valueForTrait("Use BPM-Finder")               ; }
  static Date startDate() {                   return (Date)               configuration.valueForTrait("Start Date")                   ; }
  static Date endDate() {                     return (Date)               configuration.valueForTrait("End Date")                     ; }
  static int buzzerPin() {                    return (int)                configuration.valueForTrait("Buzzer Pin")                   ; }
  static int buzzerDuration() {               return (int)                configuration.valueForTrait("Buzzer Duration")              ; }
  static List<Integer> ledRedPins() {         return (ArrayList<Integer>) configuration.valueForTrait("LED Red Pins")                 ; }
  static List<Integer> ledGreenPins() {       return (ArrayList<Integer>) configuration.valueForTrait("LED Green Pins")               ; }
  static List<Integer> ledBluePins() {        return (ArrayList<Integer>) configuration.valueForTrait("LED Blue Pins")                ; }
  static List<Integer> laserPins() {          return (ArrayList<Integer>) configuration.valueForTrait("Laser Pins")                   ; }
  static float maximumLaserOnDuration() {     return (float)              configuration.valueForTrait("Maximum Laser On-Duration")    ; }
  static int patternHistory() {               return (int)                configuration.valueForTrait("Pattern History")              ; }
  static int maximumBPM() {                   return (int)                configuration.valueForTrait("Maximum BPM")                  ; }
  static float triggerThreshold() {           return (float)              configuration.valueForTrait("Trigger Threshold")            ; }
  static float averageHistory() {             return (float)              configuration.valueForTrait("Average History")              ; }
  static float maximumLoudnessHistory() {     return (float)              configuration.valueForTrait("Maximum Loudness History")     ; }
  static float minimalTriggerThreshold() {    return (float)              configuration.valueForTrait("Minimal Trigger Threshold")    ; }
  static int frequencyRange() {               return (int)                configuration.valueForTrait("Frequency Range")              ; }
  static int frequencyFinderMaximum() {       return (int)                configuration.valueForTrait("Frequency-Finder Maximum")     ; }
  static float frequencyFinderHistory() {     return (float)              configuration.valueForTrait("Frequency-Finder History")     ; }
  static float bpmFinderDelayHistory() {      return (float)              configuration.valueForTrait("BPM-Finder Delay History")     ; }
  static float bpmFinderDeviationHistory() {  return (float)              configuration.valueForTrait("BPM-Finder Deviation History") ; }
  static float bpmFinderSmoothingDelay() {    return (float)              configuration.valueForTrait("BPM-Finder Smoothing Delay")   ; }
  static float maximumBPMPatternMAD() {       return (float)              configuration.valueForTrait("Maximum BPM-Pattern MAD")      ; }
  static boolean visualizeSpectrum() {        return (boolean)            configuration.valueForTrait("Visualize Spectrum")           ; }
  static boolean visualizeState() {           return (boolean)            configuration.valueForTrait("Visualize State")              ; }
  static boolean visualizeAnalyzer() {        return (boolean)            configuration.valueForTrait("Visualize Analyzer")           ; }
  static boolean visualizeBPMFinder() {       return (boolean)            configuration.valueForTrait("Visualize BPM-Finder")         ; }
  static int maximumVisualFrequency() {       return (int)                configuration.valueForTrait("Highest Visualized Frequency") ; }
  static float visualizationHistory() {       return (float)              configuration.valueForTrait("Visualization History")        ; }
}


//-AUDIO-OBJECTS-----------------------------------------------------//


Minim minim;
AudioInput lineIn;
FFT fft;


//-PHYSICAL-OBJECTS--------------------------------------------------//


Arduino arduino;
Buzzer buzzer = new Buzzer();
LEDs leds = new LEDs();
Lasers lasers = new Lasers();


//-VIRUTAL-OBJECTS---------------------------------------------------//


Analyzer analyzer = new Analyzer();
BPMFinder bpmFinder = new BPMFinder();
Visualizer visualizer = new Visualizer();


//-RUN-LOOP----------------------------------------------------------//


void draw() {  
  // Start- and end-time gate-keepers.
  Date now = new Date();
  if (Runtime.useStartDate() && Runtime.startDate().after(now)) { return; }
  if (Runtime.useEndDate() && Runtime.endDate().before(now)) {
    // The semantics of `exit` are rather weird. It seems to run the
    // `exit` method (overriden below) and afterwards the `draw` method
    // for one last time before finally exiting.  
    exit(); 
    return;
  }
  
  // Updates the LEDs and the buzzer first, as they are audio-independant.
  leds.update();  
  if (Runtime.useBuzzer()) { buzzer.update(); }
  
  // Gets the next audio chunk from the line-in and FFTs it.
  fft.forward(lineIn.mix);
  
  // Updates the analyzer's state with the current audio chunk.
  analyzer.processChunk(fft);
  
  // Updates the bpm-finder and lasers according to the analyzer's state.
  if (Runtime.useBPMFinder() && analyzer.fired()) { bpmFinder.recordFiring(); }
  lasers.processStep((State.inputSource == InputSource.analyzer && analyzer.fired()) ? 1 : 0);
  
  // Updates the visualization according to all new state.
  visualizer.update(fft);
}


//-EVENT-HANDLERS----------------------------------------------------//


void mouseWheel(MouseEvent event) {
  if (State.inputSource != InputSource.mouse) { return; }
  State.mouseMode = MouseMode.wheel;
  
  lasers.processStep(event.getCount());
}

void mousePressed() {
  if (State.inputSource == InputSource.mouse) {
    switch (mouseButton) {
      case LEFT: State.mouseMode = MouseMode.allOn; lasers.processStep(0); break;
      case RIGHT: State.mouseMode = MouseMode.allOff; lasers.processStep(0); break;
      default: State.inputSource = Runtime.useBuzzer() ? InputSource.none : InputSource.analyzer; break;
    }
  } else if (mouseButton != LEFT && mouseButton != RIGHT) {
    State.inputSource = InputSource.mouse;
    State.mouseMode = MouseMode.wheel;
  }
}

// Simulates mouse interactions.
void keyPressed() {
  if (key == ' ') {
    mouseButton = CENTER;
    mousePressed();
  } else if (keyCode == LEFT) {
    mouseButton = LEFT;
    mousePressed(); 
  } else if (keyCode == RIGHT) {
    mouseButton = RIGHT;
    mousePressed();
  } else if (keyCode == UP) {
    MouseEvent event = new MouseEvent(null, millis(), MouseEvent.WHEEL, -1, 0, 0, 0, +1);
    mouseWheel(event);
  } else if (keyCode == DOWN) {
    MouseEvent event = new MouseEvent(null, millis(), MouseEvent.WHEEL, -1, 0, 0, 0, -1);
    mouseWheel(event);
  }
}


//-SETUP-------------------------------------------------------------//


void setup() {
  size(1080, 720);
  surface.setResizable(true);
  visualizer.init();
  
  // Creates the objects required to capture audio.
  minim = new Minim(this);
  lineIn = minim.getLineIn();
  fft = new FFT(lineIn.bufferSize(), lineIn.sampleRate());
  
  // Binds the command line arguments to their variables, or aborts the program if that is not possible.
  if (args != null && args.length == 2) {
    Path configurationFile = Paths.get(args[0]);
    configuration = new Configuration(configurationFile);
    
    try {
      arduino = new Arduino(this, args[1], 57600);    
    } catch (Exception e) {
      println("Internal error: `Lightshow.pde` was unable to connect to Arduino: ", e);
      System.exit(1);     
    }
  } else {
    println("Error: `Lightshow.pde` didn't receive the correct number of command line arguments");
    System.exit(1); 
  }
  
  buzzer.init();
  leds.init();
  lasers.init();
}


//-TEARDOWN----------------------------------------------------------//


void exit() {
  if (lineIn != null) { lineIn.close(); }
  if (minim != null) { minim.stop(); }
  
  if (arduino != null) { 
    for (int pin : Runtime.laserPins()) {
      arduino.digitalWrite(pin, Arduino.LOW);
    }
  }
  
  super.exit();
}


//-DEBUGGING---------------------------------------------------------//


void printMemoryUsage() {
  println("# Analyzer:");
  analyzer.printMemoryUsage();
  println("# Configuration:");
  configuration.printMemoryUsage();
  println("# Lasers:");
  lasers.printMemoryUsage();
  println("# BPM-Finder:");
  bpmFinder.printMemoryUsage();
  println();
}
