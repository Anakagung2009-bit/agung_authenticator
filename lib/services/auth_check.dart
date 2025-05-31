import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheck {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static bool _isAuthenticated = false;
  static DateTime? _lastAuthTime;
  static const int _authTimeoutMinutes = 1; // Set timeout to 1 minute for testing

  // Reset authentication state
  static void resetAuthentication() {
    _isAuthenticated = false;
    _lastAuthTime = null;
  }

  // Check if privacy screen is enabled in settings
  static Future<bool> checkPrivacyScreenEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('privacy_screen_enabled') ?? false;
  }

  // Check if device has security settings enabled
  static Future<bool> isDeviceSecure() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking device security: $e');
      return false;
    }
  }

  // Check if authentication is needed based on timeout
  static bool _isAuthNeeded() {
    if (!_isAuthenticated) return true;
    
    if (_lastAuthTime == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastAuthTime!);
    return difference.inMinutes >= _authTimeoutMinutes;
  }

  // Main authentication method
  static Future<bool> authenticate(BuildContext context) async {
    // If already authenticated and within timeout, skip authentication
    if (!_isAuthNeeded()) return true;

    // Check if privacy screen is enabled
    final privacyEnabled = await checkPrivacyScreenEnabled();
    if (!privacyEnabled) {
      _isAuthenticated = true;
      _lastAuthTime = DateTime.now();
      return true;
    }

    // Check if device has security settings
    final isSecure = await isDeviceSecure();
    if (!isSecure) {
      // If device is not secure, show warning dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Security Warning'),
            content: Text(
              'Privacy Screen requires device security settings (PIN, pattern, fingerprint, or facial recognition). '
              'Please enable it in your device settings.'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Allow access temporarily
                  _isAuthenticated = true;
                  _lastAuthTime = DateTime.now();
                },
                child: Text('Understand'),
              ),
            ],
          ),
        );
      }
      return true; // Allow access even if not secure
    }

    // Get the preferred authentication method
    final prefs = await SharedPreferences.getInstance();
    final authMethod = prefs.getString('auth_method') ?? 'biometric';
    
    try {
      bool authResult = false;
      
      // Use the appropriate authentication method
      if (authMethod == 'biometric') {
        // Try biometric first, fall back to device credentials if not available
        final canCheckBiometrics = await _localAuth.canCheckBiometrics;
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        final hasBiometrics = canCheckBiometrics && availableBiometrics.isNotEmpty;
        
        authResult = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access the app',
          options: AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: hasBiometrics, // Only use biometrics if available
          ),
        );
      } else {
        // Use device credentials (PIN/pattern/password)
        authResult = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access the app',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      }
      
      // Update authentication state
      _isAuthenticated = authResult;
      if (_isAuthenticated) {
        _lastAuthTime = DateTime.now();
      }
      
      return _isAuthenticated;
    } on PlatformException catch (e) {
      print('Authentication error: ${e.message}');
      
      // Jika terjadi error FragmentActivity, tampilkan dialog dan izinkan akses
      if (e.message?.contains('FragmentActivity') == true) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Authentication Error'),
              content: Text(
                'There was an error with the authentication system. Please update your app or contact support.'
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Allow access temporarily
                    _isAuthenticated = true;
                    _lastAuthTime = DateTime.now();
                  },
                  child: Text('Continue'),
                ),
              ],
            ),
          );
        }
        return true; // Allow access despite error
      }
      
      // Untuk error lainnya, jangan izinkan akses otomatis
      return false;
    }
  }
  
  // Method to show authentication method selection dialog
  static Future<void> showAuthMethodDialog(BuildContext context) async {
    String selectedMethod = 'biometric';
    final prefs = await SharedPreferences.getInstance();
    selectedMethod = prefs.getString('auth_method') ?? 'biometric';
    
    final availableBiometrics = await _localAuth.getAvailableBiometrics();
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Select Authentication Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(
                      availableBiometrics.contains(BiometricType.face) 
                          ? Icons.face 
                          : availableBiometrics.contains(BiometricType.fingerprint)
                              ? Icons.fingerprint
                              : Icons.screen_lock_portrait
                    ),
                    SizedBox(width: 12),
                    Text(_getBiometricTypeText(availableBiometrics)),
                  ],
                ),
                value: 'biometric',
                groupValue: selectedMethod,
                onChanged: canCheckBiometrics && availableBiometrics.isNotEmpty 
                    ? (value) {
                        setState(() {
                          selectedMethod = value!;
                        });
                      }
                    : null,
              ),
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.screen_lock_portrait),
                    SizedBox(width: 12),
                    Text('Screen Lock (PIN/Pattern/Password)'),
                  ],
                ),
                value: 'screen_lock',
                groupValue: selectedMethod,
                onChanged: (value) {
                  setState(() {
                    selectedMethod = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Save the selected authentication method
                prefs.setString('auth_method', selectedMethod);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to get biometric type text
  static String _getBiometricTypeText(List<BiometricType> availableBiometrics) {
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face Unlock';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else {
      return 'Screen Lock';
    }
  }
}