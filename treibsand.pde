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
  static InputSource inputSource = InputSource.none;
  static MouseMode mouseMode = MouseMode.wheel; 
}

static Configuration configuration;

static final class Runtime {
  static int buzzerPin() {                 return (int)                configuration.valueForTrait("Buzzer Pin")                   ; }
  static int buzzerDuration() {            return (int)                configuration.valueForTrait("Buzzer Duration")              ; }
  static List<Integer> ledRedPins() {      return (ArrayList<Integer>) configuration.valueForTrait("LED Red Pins")                 ; }
  static List<Integer> ledGreenPins() {    return (ArrayList<Integer>) configuration.valueForTrait("LED Green Pins")               ; }
  static List<Integer> ledBluePins() {     return (ArrayList<Integer>) configuration.valueForTrait("LED Blue Pins")                ; }
  static List<Integer> laserPins() {       return (ArrayList<Integer>) configuration.valueForTrait("Laser Pins")                   ; }
  static int patternHistory() {            return (int)                configuration.valueForTrait("Pattern History")              ; }
  static int maximumBPM() {                return (int)                configuration.valueForTrait("Maximum BPM")                  ; }
  static float triggerThreshold() {        return (float)              configuration.valueForTrait("Trigger Threshold")            ; }
  static float averageHistory() {          return (float)              configuration.valueForTrait("Average History")              ; }
  static float maximumLoudnessHistory() {  return (float)              configuration.valueForTrait("Maximum Loudness History")     ; }
  static float minimalTriggerThreshold() { return (float)              configuration.valueForTrait("Minimal Trigger Threshold")    ; }
  static int frequencyRange() {            return (int)                configuration.valueForTrait("Frequency Range")              ; }
  static int frequencyFinderMaximum() {    return (int)                configuration.valueForTrait("Frequency Finder Maximum")     ; }
  static float frequencyFinderHistory() {  return (float)              configuration.valueForTrait("Frequency Finder History")     ; }
  static boolean visualizeSpectrum() {     return (boolean)            configuration.valueForTrait("Visualize Spectrum")           ; }
  static boolean visualizeState() {        return (boolean)            configuration.valueForTrait("Visualize State")              ; }
  static boolean visualizeAnalyzer() {     return (boolean)            configuration.valueForTrait("Visualize Analyzer")           ; }
  static int maximumVisualFrequency() {    return (int)                configuration.valueForTrait("Highest Visualized Frequency") ; }
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
Visualizer visualizer = new Visualizer();


//-RUN-LOOP----------------------------------------------------------//


void draw() {
  // Updates the LEDs and the buzzer first, as they are audio-independant.
  leds.update();
  buzzer.update();
  
  // Gets the next audio chunk from the line-in and FFTs it.
  fft.forward(lineIn.mix);
  
  // Updates the analyzer's state with the current audio chunk.
  analyzer.processChunk(fft);
  
  // Updates the lasers according to the analyzer's state.
  if (State.inputSource == InputSource.analyzer && analyzer.fired()) { lasers.processStep(1); }
  
  // Updates the visualization according to all new state.
  visualizer.update(fft);
}


//-EVENT-HANDLERS----------------------------------------------------//


void mouseWheel(MouseEvent event) {
  if (State.inputSource != InputSource.mouse) { return; }
  State.mouseMode = MouseMode.wheel;
  
  lasers.processStep(max(min(event.getCount(), 1), -1));
}

void mousePressed() {
  if (State.inputSource == InputSource.mouse) {
    switch (mouseButton) {
      case LEFT: State.mouseMode = MouseMode.allOn; lasers.processStep(0); break;
      case RIGHT: State.mouseMode = MouseMode.allOff; lasers.processStep(0); break;
      default: State.inputSource = InputSource.none; break;
    }
  } else if (mouseButton != LEFT && mouseButton != RIGHT) {
    State.inputSource = InputSource.mouse;
    State.mouseMode = MouseMode.wheel;
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
}


//-TEARDOWN----------------------------------------------------------//


void stop() {
  lineIn.close();
  minim.stop();
  super.stop();
  
  // Shuts off the lasers when the program quits.
  for (int pin : Runtime.laserPins()) {
    arduino.digitalWrite(pin, Arduino.LOW);
  }
}