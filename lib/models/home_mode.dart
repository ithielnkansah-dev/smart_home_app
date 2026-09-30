enum HomeMode { home, away, night, sleep, vacation }

extension HomeModeExtension on HomeMode {
  String get name {
    switch (this) {
      case HomeMode.home: return 'Home';
      case HomeMode.away: return 'Away';
      case HomeMode.night: return 'Night';
      case HomeMode.sleep: return 'Sleep';
      case HomeMode.vacation: return 'Vacation';
    }
  }
}
