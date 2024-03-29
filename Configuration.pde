final class Configuration {

  private Map<String, Object> staticTraits;
  
  // This map is updated with new information from the configuration files whenever the time of the last refresh is over a certain threshold.
  private Map<String, Object> runtimeTraits;
  
  private Path configurationFile;
  
  // These properties are used to track whether the maps above need to be refreshed.
  private int timeOfLastRefresh;
  private int millisecondsToRefresh; // aka refresh interval

  Configuration(Path configurationFile) {
    this.configurationFile = configurationFile;
    timeOfLastRefresh = 0;
    millisecondsToRefresh = 0;

    // Creates the static trait map, which has to succeed or else the program has to abort.
    try { staticTraits = mapFromConfiguration(configurationFile); } catch (Exception e) {
      println("Internal error: class `Configuration` was unable to create static trait map");
      System.exit(3);
    }

    // Initializes the runtime trait map. This is allowed to fail, as `valueForTrait` will just use the static trait map in that case.
    updateRuntimeTraitConfiguration();
  }

  // Returns the value for the trait with a given name.
  Object valueForTrait(String trait) {    
    // Refreshes the runtime trait map if the refresh interval has been passed.
    if ((millis() - timeOfLastRefresh) > millisecondsToRefresh) {
      updateRuntimeTraitConfiguration();
    }

    // Uses the runtime trait map value if possible - or else falls back on the static trait map.
    // The static value might also be null, if the given trait name string was invalid.
    Object runtimeValue = runtimeTraits.get(trait);
    return (runtimeValue != null) ? runtimeValue : staticTraits.get(trait);
  }

  // Wraps `mapFromConfiguration` to be runtime configuration file specific.
  // It also swallows exceptions and makes sure the `timeOfLastRefresh` is set.
  private void updateRuntimeTraitConfiguration() {
    try { runtimeTraits = mapFromConfiguration(configurationFile); } catch (Exception e) { /* This is ok. */ }    
    timeOfLastRefresh = millis();
  }

  // Creates a map from a given file which is expected to be a sever configuration file of the form:
  // <trait 1 name>: <trait 1 value> // <optional comment>
  // <trait 2 name>: <trait 2 value> // <optional comment>
  // // <optional comment>
  // ...
  private Map<String, Object> mapFromConfiguration(Path path) throws Exception {
    Map<String, Object> map = new HashMap<String, Object>();
    Scanner configurationScanner = new Scanner(path);

    // Iterates over the lines in the given file.
    while (configurationScanner.hasNextLine()) {
      String configurationEntry = configurationScanner.nextLine();
      String[] entryComponents = configurationEntry.split(":");

      String traitIdentifier = entryComponents[0].trim();
      if (traitIdentifier.startsWith("//") || traitIdentifier.isEmpty()) { continue; }
      
      String traitValue = entryComponents[1].split("//")[0].trim();
      
      // Converts the value from a literal string to the specified type.
      Object value = valueFromString(traitValue);

      // "Configuration Read Cycle" is a reserved trait name which is used to change the refresh interval of a configuration object.
      if (traitIdentifier.equals("Configuration Read Cycle")) {
        millisecondsToRefresh = Math.round((float) value * 1000);
      } else {
        map.put(traitIdentifier, value);
      }
    }

    configurationScanner.close();
    return map;
  }

  // Converts a given string to a value following certain parsing rules. If this fails, null is returned.
  private Object valueFromString(String string) {
    if (string.contains("@")) {
      String[] dateAndTime = string.split("@");
      String[] dayAndMonth = dateAndTime[0].split("\\.");
      String[] hourAndMinute = dateAndTime[1].split("\\.");
      
      int day = Integer.parseInt(dayAndMonth[0].trim());
      int month = Integer.parseInt(dayAndMonth[1].trim());
      int hour = Integer.parseInt(hourAndMinute[0].trim());
      int minute = Integer.parseInt(hourAndMinute[1].trim());
      
      Calendar calendar = Calendar.getInstance();
      calendar.set(year(), month - 1, day, hour, minute, 0);
      
      return calendar.getTime();
      
    } else if (string.contains(".")) {
      return Float.parseFloat(string);
    
    } else if (string.contains("%")) {
      return ((float) Integer.parseInt(string.replace("%", ""))) / 100f;
    
    } else if (string.contains("[")) {
      List<Integer> intList = new ArrayList<Integer>();

      if (string.charAt(0) == 'i') { return intList; }

      String bareIntList = string.substring(1, string.length() - 1);
      String[] intElements = bareIntList.split(",");
      for (String element : intElements) { intList.add(Integer.parseInt(element.trim())); }
      return intList;

    } else if (string.equals("true") || string.equals("false")) { 
      return Boolean.parseBoolean(string);
      
    } else {
      return Integer.parseInt(string);
    }
  }
  
  // For debugging.
  void printMemoryUsage() {
    println("static traits:\t" + staticTraits.size());
    println("runtime traits:\t" + runtimeTraits.size());
  }
}
