// Running this program requires the following arguments:
// <Server Specification> = <Class Name>;<Config File Path>
// <Arduino Port>? or <-v>?
// <-v>? if Arduino Port was also given


//-IMPORTS-----------------------------------------------------------//


import java.util.*;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.lang.reflect.Constructor;
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.serial.*;
import cc.arduino.*;


//-STATE-------------------------------------------------------------//


enum InputState {
  automatic, 
  patternWheel
}

InputState INPUT_STATE = InputState.automatic;

enum ShowState {
  allOn,  
  input,
  allOff
}

ShowState SHOW_STATE = ShowState.input;

//-AUDIO-OBJECTS-----------------------------------------------------//


Minim minim;
AudioInput lineIn;
FFT fft;


//-FUNCTION-OBJECTS--------------------------------------------------//


Button button;
LEDLighter ledLighter;
Server server;


//-VISUALIZATION-OBJECTS---------------------------------------------//


Patterns patterns = new Patterns();
Visualizer visualizer = new Visualizer();
ServerVisualizer serverVisualizer;


//-RUNTIME-SPECIFIERS------------------------------------------------//


static final Integer MAX_FREQ = 10000;
static final Integer ON_OFF_BUTTON_PIN = -1;
static final Integer MANUAL_BUTTON_PIN = -1;
static final Integer[] LED_PINS = {2, 3, 4, 10, 11, 13};

Boolean shouldVisualize = false;
String arduinoPath;
String serverSpecification;


//-RUN-LOOP----------------------------------------------------------//


void draw() {
  ledLighter.step();
  
  // Gets the next audio chunk from the line-in and FFTs it.
  AudioBuffer chunk = lineIn.mix;
  fft.forward(chunk);

  // server.showOutput(button.isOn());
  server.processChunk(chunk, fft);

  if (serverVisualizer != null) {
    background(0);
    // visualizer.showWaveformForChunk(chunk);
    visualizer.showSpectrumForChunk(fft, true);
    serverVisualizer.showServerProperties(); 
  }
}


//-EVENT-HANDLERS----------------------------------------------------//


void mouseWheel(MouseEvent event) {
  if (INPUT_STATE != InputState.patternWheel) { return; }
  SHOW_STATE = ShowState.input;
  
  switch (event.getCount()) {
    case 1: patterns.step(); break;  
    case -1: patterns.back(); break;
  }
}

void mousePressed() {
  if (mouseButton == LEFT) {
    if (INPUT_STATE != InputState.patternWheel) { return; }
    SHOW_STATE = ShowState.allOn;
  } else if (mouseButton == RIGHT) {
    if (INPUT_STATE != InputState.patternWheel) { return; }
    SHOW_STATE = ShowState.allOff;
  } else {
    if (INPUT_STATE == InputState.patternWheel) {
      INPUT_STATE = InputState.automatic;
      SHOW_STATE = ShowState.input;
    } else {
      INPUT_STATE = InputState.patternWheel;
    }
  }
}


//-SETUP-------------------------------------------------------------//


void setup() {
  size(1080, 720); 
  bindRuntimeSpecifiers();
  instantiateAudioObjects();
  instantiateFunctionObjects();
  setupVisualizersIfNecessary();
}

Server serverFromSpecification(String specification, Arduino arduino) throws Exception {
  String[] components = specification.split(";");
  
  Class instanceClass = Class.forName("Lightshow$" + components[0]);
  Path configurationFile = Paths.get(components[1]);

  Configuration configuration = new Configuration(configurationFile, configurationFile);
  Constructor instanceConstructor = instanceClass.getConstructor(Lightshow.class, Configuration.class, Arduino.class);

  return (Server) instanceConstructor.newInstance(this, configuration, arduino);  
}

ServerVisualizer visualizerForServer(Server server) throws Exception {
  String serverClassName = server.getClass().getName();
  
  if (StandardServer.class.isAssignableFrom(server.getClass())) {
    serverClassName = "S_Standard";
  }
  
  Class visualizerClass = Class.forName("Lightshow$V" + serverClassName.substring(serverClassName.lastIndexOf("_")));
  Class serverClass = Server.class;
  
  if (StandardServer.class.isAssignableFrom(server.getClass())) {
    serverClass = StandardServer.class;
  }
  
  Constructor visualizerConstructor = visualizerClass.getConstructor(Lightshow.class, serverClass);
  
  return (ServerVisualizer) visualizerConstructor.newInstance(this, server);
}

void bindRuntimeSpecifiers() {
  // Binds the command line arguments to their variables, or aborts the program if that is not possible.
  if (args != null) {    
    switch (args.length) {
      case 3:
        shouldVisualize = true;
        // fallthrough
      case 2:
        if (args[1].equals("-v")) {
          shouldVisualize = true;   
        } else {
          arduinoPath = args[1];
        }
        // fallthrough
      case 1:
        serverSpecification = args[0];
        return;
    }
  }
  
  println("Internal error: `Lightshow.pde` didn't receive the correct number of command line arguments");
  System.exit(1);
}

void instantiateAudioObjects() {
  // Creates the objects required to capture audio.
  minim = new Minim(this);
  lineIn = minim.getLineIn();
  fft = new FFT(lineIn.bufferSize(), lineIn.sampleRate());
}

void instantiateFunctionObjects() {
  Arduino arduino = null;
  
  if (arduinoPath != null) { 
    try {
      arduino = new Arduino(this, arduinoPath, 57600);    
    } catch (Exception e) {
      println("Internal error: `Lightshow.pde` was unable to connect to Arduino: ", e);
      System.exit(2);     
    }
  }
  
  button = new Button(false, ON_OFF_BUTTON_PIN, arduino);
  ledLighter = new LEDLighter(LED_PINS, arduino);
  
  // Instantiates and captures the server instances or aborts if that operation fails.
  try {
    server = serverFromSpecification(serverSpecification, arduino);
    server.showOutput(true);
  } catch (Exception e) {
    println("Internal error: `Lightshow.pde` was unable to instantiate server: ", e);
    System.exit(3);
  }
}

void setupVisualizersIfNecessary() {
  if (shouldVisualize) {    
    try {
      serverVisualizer = visualizerForServer(server);
    } catch (Exception e) {
      println("Internal error: `Lightshow.pde` was unable to instantiate server visualizer: ", e);
      System.exit(4);
    }
  } else {
    surface.setVisible(false); 
  }
}


//-TEARDOWN----------------------------------------------------------//


void stop() {
  lineIn.close();
  minim.stop();
  super.stop();
}
