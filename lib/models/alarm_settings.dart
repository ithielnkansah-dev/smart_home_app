class SpeakerAlarmSettings {
  String selectedSound;
  double volume;
  bool participatesInAlarm;

  SpeakerAlarmSettings({
    this.selectedSound = 'Siren Alert',
    this.volume = 0.8,
    this.participatesInAlarm = true,
  });
}

class RgbAlarmSettings {
  int colorHex; // integer color value
  String flashPattern; // e.g. 'Strobe', 'Pulse', 'Solid'
  bool participatesInAlarm;

  RgbAlarmSettings({
    this.colorHex = 0xFFFF0000, // Red by default
    this.flashPattern = 'Strobe',
    this.participatesInAlarm = true,
  });
}

class SmokeDetectorSettings {
  String currentStatus; // e.g. 'Clear', 'Testing', 'Offline'
  bool isIntegrationConfirmed;

  SmokeDetectorSettings({
    this.currentStatus = 'Clear',
    this.isIntegrationConfirmed = false,
  });
}
