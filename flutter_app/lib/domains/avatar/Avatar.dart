class UserAvatar {
  static String formatIconName(String icon) {
    icon = icon?.replaceAll(" ", "");
    return icon?.replaceAll("/", "");
  }

  static String getNPName(String icon) {
    if (icon == "/SailorCat.svg") {
      return "/Sailor Cat.svg";
    }
    return icon;
  }
}
