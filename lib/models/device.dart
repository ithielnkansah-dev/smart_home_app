class Device {
  final String id;
  final String name;
  final String type;
  final String houseId;
  final String floorId;
  final String roomId;
  final String? zoneId;

  bool isOnline;
  bool isOn;
  bool isFavorite;
  String status;

  // Image assets
  String? imagePath;
  String? imageUrl;

  // Granular control properties
  double brightness; // 0.0 to 1.0
  int? colorHex; // For RGBW
  double colorTemp; // 0.0 (Warm) to 1.0 (Cool) for Tunable White
  int kelvinTemp; // 2200K to 6500K
  double targetTemp;
  String fanSpeed; // Low, Medium, High, Auto
  bool isLocked;

  // Advanced Lighting System Configurations
  String lightingMode; // Standard, Circadian, PresenceSimulation, NightPath, FocusTask, Sync
  String powerOnState; // PreviousState, AlwaysOff, AlwaysOn
  double transitionSpeed; // 0.0 (Instant), 1.0s, 5.0s, 30.0s
  double minDimThreshold; // 0.0 to 0.20 (5% default)
  double maxDimThreshold; // 0.80 to 1.00 (100% default)
  bool motionAutoOff;
  bool doorSensorTrigger;
  bool ambientLuxSensor;

  // HVAC / Thermostat Extended Configurations
  String hvacMode; // Cool, Heat, Dry, Fan, Auto, Eco, Sleep
  double tempHysteresis; // 0.5°C to 2.0°C
  String remoteSensorPriority; // LivingRoom, Bedroom, Auto
  bool preHeatingCooling;

  // Smart Lock Extended Configurations
  String lockMode; // AutoLock, Lockdown, Party
  int autoLockDelay; // 30, 60, 180, 300 seconds
  bool proximityAutoUnlock;

  // Smart Plug Extended Configurations
  int autoOffTimerMinutes; // 0 (disabled) to 120 mins
  double overloadWattCutoff; // e.g. 2200.0 Watts
  String plugPowerLossRecovery; // RestorePrevious, AlwaysOff, AlwaysOn
  bool phantomDrainPrevention;

  // Smart Blinds & Window Extended Configurations
  String blindMode; // Manual, SolarTracking, Privacy
  bool silentAcousticMode;
  bool stormProtection;
  double openPercentage; // 0.0 to 1.0 (0% to 100%)
  int tiltAngle; // 0 to 180 degrees
  bool rainProtection;
  bool tempVentilation;

  // Camera & Doorbell Extended Configurations
  String cameraArmMode; // ArmedStay, ArmedAway, Snooze
  int snoozeMinutes; // 0, 30, 60, 120
  bool aiPersonDetection;
  bool aiPackageDetection;
  bool aiVehicleDetection;
  bool intruderDeterrent;

  // Water Management Extended Configurations
  double waterLevelPercentage; // 0.0 to 100.0%
  String pumpMode; // Auto, Manual, Scheduled
  bool isValveOpen;
  bool waterLeakDetected;

  // Energy, Solar, Battery & EV Charger Extended Configurations
  double pvPowerKw; // e.g. 8.42 kW
  double batterySocPercentage; // 0.0 to 100.0%
  double batteryVoltage; // e.g. 51.2 V
  double batteryDischargeKw; // e.g. 4.1 kW
  double evChargingPowerKw; // e.g. 7.2 kW
  double evBatteryPercentage; // e.g. 64.0%
  double totalEnergyDeliveredKwh; // e.g. 18.4 kWh

  // Environmental & Safety Sensors Extended Configurations
  int co2Ppm; // e.g. 450 ppm
  double pm25; // e.g. 12.0 ug/m3
  int aqi; // Air Quality Index
  double luxLevel; // e.g. 350.0 Lux
  double gasConcentrationPpm; // Gas/LPG level
  bool smokeDetected;
  bool gasDetected;

  // Smart Appliances & Entertainment Extended Configurations
  String applianceProgram; // Normal, Eco, Heavy, Quick, Bake, Roast
  int remainingMinutes;
  double freezerTemp; // e.g. -18.0 °C
  int volumeLevel; // 0 to 100
  String audioSource; // Spotify, Bluetooth, TV, Radio

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.houseId,
    required this.floorId,
    required this.roomId,
    this.zoneId,
    this.isOnline = true,
    this.isOn = false,
    this.isFavorite = false,
    this.status = 'OFF',
    this.imagePath,
    this.imageUrl,
    this.brightness = 1.0,
    this.colorHex,
    this.colorTemp = 0.5,
    this.kelvinTemp = 4000,
    this.targetTemp = 22.0,
    this.fanSpeed = 'Auto',
    this.isLocked = true,
    this.lightingMode = 'Standard',
    this.powerOnState = 'PreviousState',
    this.transitionSpeed = 1.0,
    this.minDimThreshold = 0.05,
    this.maxDimThreshold = 1.00,
    this.motionAutoOff = false,
    this.doorSensorTrigger = false,
    this.ambientLuxSensor = false,
    this.hvacMode = 'Cool',
    this.tempHysteresis = 1.0,
    this.remoteSensorPriority = 'Auto',
    this.preHeatingCooling = true,
    this.lockMode = 'AutoLock',
    this.autoLockDelay = 60,
    this.proximityAutoUnlock = true,
    this.autoOffTimerMinutes = 0,
    this.overloadWattCutoff = 2200.0,
    this.plugPowerLossRecovery = 'RestorePrevious',
    this.phantomDrainPrevention = true,
    this.blindMode = 'Manual',
    this.silentAcousticMode = false,
    this.stormProtection = true,
    this.openPercentage = 1.0,
    this.tiltAngle = 90,
    this.rainProtection = true,
    this.tempVentilation = false,
    this.cameraArmMode = 'ArmedAway',
    this.snoozeMinutes = 0,
    this.aiPersonDetection = true,
    this.aiPackageDetection = true,
    this.aiVehicleDetection = true,
    this.intruderDeterrent = true,
    this.waterLevelPercentage = 82.0,
    this.pumpMode = 'Auto',
    this.isValveOpen = true,
    this.waterLeakDetected = false,
    this.pvPowerKw = 8.42,
    this.batterySocPercentage = 78.0,
    this.batteryVoltage = 51.2,
    this.batteryDischargeKw = 4.1,
    this.evChargingPowerKw = 7.2,
    this.evBatteryPercentage = 64.0,
    this.totalEnergyDeliveredKwh = 18.4,
    this.co2Ppm = 420,
    this.pm25 = 12.0,
    this.aqi = 25,
    this.luxLevel = 450.0,
    this.gasConcentrationPpm = 0.0,
    this.smokeDetected = false,
    this.gasDetected = false,
    this.applianceProgram = 'Eco Normal',
    this.remainingMinutes = 0,
    this.freezerTemp = -18.0,
    this.volumeLevel = 50,
    this.audioSource = 'Living Room Audio',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'houseId': houseId,
    'floorId': floorId,
    'roomId': roomId,
    'zoneId': zoneId,
    'isOnline': isOnline,
    'isOn': isOn,
    'isFavorite': isFavorite,
    'status': status,
    'imagePath': imagePath,
    'imageUrl': imageUrl,
    'brightness': brightness,
    'colorHex': colorHex,
    'colorTemp': colorTemp,
    'kelvinTemp': kelvinTemp,
    'targetTemp': targetTemp,
    'fanSpeed': fanSpeed,
    'isLocked': isLocked,
    'lightingMode': lightingMode,
    'powerOnState': powerOnState,
    'transitionSpeed': transitionSpeed,
    'minDimThreshold': minDimThreshold,
    'maxDimThreshold': maxDimThreshold,
    'motionAutoOff': motionAutoOff,
    'doorSensorTrigger': doorSensorTrigger,
    'ambientLuxSensor': ambientLuxSensor,
    'hvacMode': hvacMode,
    'tempHysteresis': tempHysteresis,
    'remoteSensorPriority': remoteSensorPriority,
    'preHeatingCooling': preHeatingCooling,
    'lockMode': lockMode,
    'autoLockDelay': autoLockDelay,
    'proximityAutoUnlock': proximityAutoUnlock,
    'autoOffTimerMinutes': autoOffTimerMinutes,
    'overloadWattCutoff': overloadWattCutoff,
    'plugPowerLossRecovery': plugPowerLossRecovery,
    'phantomDrainPrevention': phantomDrainPrevention,
    'blindMode': blindMode,
    'silentAcousticMode': silentAcousticMode,
    'stormProtection': stormProtection,
    'openPercentage': openPercentage,
    'tiltAngle': tiltAngle,
    'rainProtection': rainProtection,
    'tempVentilation': tempVentilation,
    'cameraArmMode': cameraArmMode,
    'snoozeMinutes': snoozeMinutes,
    'aiPersonDetection': aiPersonDetection,
    'aiPackageDetection': aiPackageDetection,
    'aiVehicleDetection': aiVehicleDetection,
    'intruderDeterrent': intruderDeterrent,
    'waterLevelPercentage': waterLevelPercentage,
    'pumpMode': pumpMode,
    'isValveOpen': isValveOpen,
    'waterLeakDetected': waterLeakDetected,
    'pvPowerKw': pvPowerKw,
    'batterySocPercentage': batterySocPercentage,
    'batteryVoltage': batteryVoltage,
    'batteryDischargeKw': batteryDischargeKw,
    'evChargingPowerKw': evChargingPowerKw,
    'evBatteryPercentage': evBatteryPercentage,
    'totalEnergyDeliveredKwh': totalEnergyDeliveredKwh,
    'co2Ppm': co2Ppm,
    'pm25': pm25,
    'aqi': aqi,
    'luxLevel': luxLevel,
    'gasConcentrationPpm': gasConcentrationPpm,
    'smokeDetected': smokeDetected,
    'gasDetected': gasDetected,
    'applianceProgram': applianceProgram,
    'remainingMinutes': remainingMinutes,
    'freezerTemp': freezerTemp,
    'volumeLevel': volumeLevel,
    'audioSource': audioSource,
  };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    type: json['type'] ?? 'light',
    houseId: json['houseId'] ?? 'H001',
    floorId: json['floorId'] ?? 'F001',
    roomId: json['roomId'] ?? 'R001',
    zoneId: json['zoneId'],
    isOnline: json['isOnline'] ?? true,
    isOn: json['isOn'] ?? false,
    isFavorite: json['isFavorite'] ?? false,
    status: json['status'] ?? 'OFF',
    imagePath: json['imagePath'],
    imageUrl: json['imageUrl'],
    brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
    colorHex: json['colorHex'],
    colorTemp: (json['colorTemp'] as num?)?.toDouble() ?? 0.5,
    kelvinTemp: json['kelvinTemp'] ?? 4000,
    targetTemp: (json['targetTemp'] as num?)?.toDouble() ?? 22.0,
    fanSpeed: json['fanSpeed'] ?? 'Auto',
    isLocked: json['isLocked'] ?? true,
    lightingMode: json['lightingMode'] ?? 'Standard',
    powerOnState: json['powerOnState'] ?? 'PreviousState',
    transitionSpeed: (json['transitionSpeed'] as num?)?.toDouble() ?? 1.0,
    minDimThreshold: (json['minDimThreshold'] as num?)?.toDouble() ?? 0.05,
    maxDimThreshold: (json['maxDimThreshold'] as num?)?.toDouble() ?? 1.00,
    motionAutoOff: json['motionAutoOff'] ?? false,
    doorSensorTrigger: json['doorSensorTrigger'] ?? false,
    ambientLuxSensor: json['ambientLuxSensor'] ?? false,
    hvacMode: json['hvacMode'] ?? 'Cool',
    tempHysteresis: (json['tempHysteresis'] as num?)?.toDouble() ?? 1.0,
    remoteSensorPriority: json['remoteSensorPriority'] ?? 'Auto',
    preHeatingCooling: json['preHeatingCooling'] ?? true,
    lockMode: json['lockMode'] ?? 'AutoLock',
    autoLockDelay: json['autoLockDelay'] ?? 60,
    proximityAutoUnlock: json['proximityAutoUnlock'] ?? true,
    autoOffTimerMinutes: json['autoOffTimerMinutes'] ?? 0,
    overloadWattCutoff: (json['overloadWattCutoff'] as num?)?.toDouble() ?? 2200.0,
    plugPowerLossRecovery: json['plugPowerLossRecovery'] ?? 'RestorePrevious',
    phantomDrainPrevention: json['phantomDrainPrevention'] ?? true,
    blindMode: json['blindMode'] ?? 'Manual',
    silentAcousticMode: json['silentAcousticMode'] ?? false,
    stormProtection: json['stormProtection'] ?? true,
    openPercentage: (json['openPercentage'] as num?)?.toDouble() ?? 1.0,
    tiltAngle: json['tiltAngle'] ?? 90,
    rainProtection: json['rainProtection'] ?? true,
    tempVentilation: json['tempVentilation'] ?? false,
    cameraArmMode: json['cameraArmMode'] ?? 'ArmedAway',
    snoozeMinutes: json['snoozeMinutes'] ?? 0,
    aiPersonDetection: json['aiPersonDetection'] ?? true,
    aiPackageDetection: json['aiPackageDetection'] ?? true,
    aiVehicleDetection: json['aiVehicleDetection'] ?? true,
    intruderDeterrent: json['intruderDeterrent'] ?? true,
    waterLevelPercentage: (json['waterLevelPercentage'] as num?)?.toDouble() ?? 82.0,
    pumpMode: json['pumpMode'] ?? 'Auto',
    isValveOpen: json['isValveOpen'] ?? true,
    waterLeakDetected: json['waterLeakDetected'] ?? false,
    pvPowerKw: (json['pvPowerKw'] as num?)?.toDouble() ?? 8.42,
    batterySocPercentage: (json['batterySocPercentage'] as num?)?.toDouble() ?? 78.0,
    batteryVoltage: (json['batteryVoltage'] as num?)?.toDouble() ?? 51.2,
    batteryDischargeKw: (json['batteryDischargeKw'] as num?)?.toDouble() ?? 4.1,
    evChargingPowerKw: (json['evChargingPowerKw'] as num?)?.toDouble() ?? 7.2,
    evBatteryPercentage: (json['evBatteryPercentage'] as num?)?.toDouble() ?? 64.0,
    totalEnergyDeliveredKwh: (json['totalEnergyDeliveredKwh'] as num?)?.toDouble() ?? 18.4,
    co2Ppm: json['co2Ppm'] ?? 420,
    pm25: (json['pm25'] as num?)?.toDouble() ?? 12.0,
    aqi: json['aqi'] ?? 25,
    luxLevel: (json['luxLevel'] as num?)?.toDouble() ?? 450.0,
    gasConcentrationPpm: (json['gasConcentrationPpm'] as num?)?.toDouble() ?? 0.0,
    smokeDetected: json['smokeDetected'] ?? false,
    gasDetected: json['gasDetected'] ?? false,
    applianceProgram: json['applianceProgram'] ?? 'Eco Normal',
    remainingMinutes: json['remainingMinutes'] ?? 0,
    freezerTemp: (json['freezerTemp'] as num?)?.toDouble() ?? -18.0,
    volumeLevel: json['volumeLevel'] ?? 50,
    audioSource: json['audioSource'] ?? 'Living Room Audio',
  );
}
