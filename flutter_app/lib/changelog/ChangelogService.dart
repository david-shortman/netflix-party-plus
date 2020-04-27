class ChangelogService {
  static String getLatestVersion() {
    return '1.2.0';
  }

  static String getCurrentChangelog() {
    return '''- Added skip 10 seconds forward/backward buttons
- Long pressing on chat avatar icons changes them to use initials instead
- Added haptic feedback''';
  }
}
