import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Use Test ID for development. Replace with your real Ad Unit ID from AdMob.
      return 'ca-app-pub-1974061688406278/2467424119';
    } else if (Platform.isIOS) {
      // Use Test ID for development. Replace with your real Ad Unit ID from AdMob.
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
