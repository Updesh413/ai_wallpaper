import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SharedPreferences _prefs;

  BiometricService(this._prefs);

  Future<bool> isBiometricSupported() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      print("Can check biometrics: $canCheckBiometrics");
      print("Is device supported: $isDeviceSupported");
      return canCheckBiometrics || isDeviceSupported;
    } catch (e) {
      print("Biometric support check failed: $e");
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      print("Biometric authentication result: $authenticated");
      return authenticated;
    } catch (e) {
      print("Biometric authentication failed: $e");
      return false;
    }
  }

  Future<void> enableBiometric(bool enable) async {
    await _prefs.setBool('biometricEnabled', enable);
  }

  bool isBiometricEnabled() {
    return _prefs.getBool('biometricEnabled') ?? false;
  }
}
