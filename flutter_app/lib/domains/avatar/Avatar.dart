class UserAvatar {
  static String formatIconName(String icon) {
    icon = icon.replaceAll(" ", "");
    return icon.replaceAll("/", "");
  }
}