class AppAssets {
  static const String imagePath = "assets/images/";
  static const String dataPath = "assets/data/";
  static String getImage(String fileName) {
    return "$imagePath$fileName";
  }

  static String getDataUrl(String fileName) {
    return "$dataPath$fileName";
  }
}
