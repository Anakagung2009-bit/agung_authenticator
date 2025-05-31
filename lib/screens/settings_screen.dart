import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_check.dart';
import '../services/theme_service.dart';
import '../services/totp_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _privacyScreenEnabled = false;
  bool _isDeviceSecure = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometrics();
    _checkDeviceSecurity();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _privacyScreenEnabled = prefs.getBool('privacy_screen_enabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_screen_enabled', _privacyScreenEnabled);
  }

  Future<void> _checkDeviceSecurity() async {
    final isSecure = await AuthCheck.isDeviceSecure();
    setState(() {
      _isDeviceSecure = isSecure;
    });
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } on PlatformException {
      canCheckBiometrics = false;
    }

    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });

    if (canCheckBiometrics) {
      try {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        if (!mounted) return;
        setState(() {
          _availableBiometrics = availableBiometrics;
        });
      } on PlatformException {
        setState(() {
          _availableBiometrics = [];
        });
      }
    }
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face Unlock';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else {
      return 'Screen Lock';
    }
  }
  
  // Add a new method to show authentication method selection dialog
  void _showAuthMethodDialog() {
    String selectedMethod = 'biometric';
    
    // Get the current preference or default to biometric
    SharedPreferences.getInstance().then((prefs) {
      selectedMethod = prefs.getString('auth_method') ?? 'biometric';
      
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
                      Icon(_availableBiometrics.contains(BiometricType.face) 
                          ? Icons.face 
                          : _availableBiometrics.contains(BiometricType.fingerprint)
                              ? Icons.fingerprint
                              : Icons.screen_lock_portrait),
                      SizedBox(width: 12),
                      Text(_getBiometricTypeText()),
                    ],
                  ),
                  value: 'biometric',
                  groupValue: selectedMethod,
                  onChanged: _availableBiometrics.isNotEmpty 
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
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setString('auth_method', selectedMethod);
                    Navigator.pop(context);
                    // Refresh the UI
                    this.setState(() {});
                  });
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showSecurityWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Security Settings Required'),
        content: Text(
          'To enable Privacy Screen, you need to set up device security first (PIN, pattern, fingerprint, or facial recognition).\n\n'
          'Please enable it in your device settings.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Ok'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Settings Section
          ListTile(
            title: Text('Screen Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // Theme Mode Setting
          ListTile(
            title: Text('Theme'),
            subtitle: Text(_getThemeModeText(themeService.themeMode)),
            leading: Icon(
              _getThemeModeIcon(themeService.themeMode),
            ),
            onTap: () => _showThemeModeDialog(themeService),
          ),
          
          // Material You Setting (Dynamic Colors)
          ListTile(
            title: Text('Material You'),
            subtitle: Text(themeService.useDynamicColors 
              ? 'Active - Color adjusts to device wallpaper' 
              : 'Disabled - Uses default colors'),
            leading: Icon(Icons.palette_outlined),
            trailing: Switch(
              value: themeService.useDynamicColors,
              onChanged: (value) {
                themeService.setDynamicColors(value);
              },
            ),
          ),
          
          Divider(),
          
          // Security Settings Section
          ListTile(
            title: Text('Security Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          ListTile(
            title: Text('Privacy Screen'),
            subtitle: Text(
              _isDeviceSecure 
                ? 'When enabled, the app will ask for authentication when reopened.'
                : 'Requires device security settings (PIN, pattern, etc.)',
            ),
            leading: Icon(Icons.security),
            trailing: Switch(
              value: _privacyScreenEnabled,
              onChanged: _isDeviceSecure 
                ? (value) {
                    setState(() {
                      _privacyScreenEnabled = value;
                    });
                    _saveSettings();
                  }
                : (value) {
                    if (value) {
                      _showSecurityWarning();
                    }
                  },
            ),
          ),
          if (_privacyScreenEnabled && _isDeviceSecure)
            ListTile(
              title: Text('Authentication Method'),
              subtitle: Text(_canCheckBiometrics
                  ? 'Use ${_getBiometricTypeText()}'
                  : 'Just use Screen Lock'),
              leading: Icon(
                _availableBiometrics.contains(BiometricType.face)
                    ? Icons.face
                    : _availableBiometrics.contains(BiometricType.fingerprint)
                        ? Icons.fingerprint
                        : Icons.screen_lock_portrait,
              ),
              onTap: () {
                // Use the AuthCheck method to show the dialog
                AuthCheck.showAuthMethodDialog(context);
              },
            ),
          if (!_isDeviceSecure)
            ListTile(
              title: Text('Enable Device Security'),
              subtitle: Text('Device security settings are required for Privacy Screen'),
              leading: Icon(Icons.security, color: Colors.orange),
              onTap: () {
                _showSecurityWarning();
              },
            ),
          Divider(),
          // Tambahkan di bagian build widget
          ListTile(
            title: Text('Sync TOTP Data'),
            subtitle: Text('Use this if TOTP data does not appear on this device'),
            trailing: Icon(Icons.sync),
            onTap: () async {
              final TOTPService totpService = TOTPService();
              
              // Tampilkan loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: Text('Syncing...'),
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Please wait...'),
                    ],
                  ),
                ),
              );
              
              try {
                final result = await totpService.syncEncryptionKey();
                Navigator.pop(context); // Tutup dialog loading
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result 
                      ? 'Sync successful! Restart the app to see the changes.' 
                      : 'Synchronization failed. Please try again later.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Tutup dialog loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          Divider(),
          ListTile(
            title: const Text('About the App'),
            subtitle: const Text('Agung Auth - Authenticator App'),
            leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationIcon: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 24,
                  child: Icon(Icons.lock_outline, size: 32, color: Colors.blueAccent),
                ),
                applicationName: 'Agung Auth',
                applicationLegalese: '© 2025 Agung Dev',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Agung Auth is a modern authenticator app that supports TOTP'
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

        ],
      ),
    );
  }
  
  // Helper method to get theme mode text
  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
      default:
        return 'System Default';
    }
  }
  
  // Helper method to get theme mode icon
  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
      default:
        return Icons.brightness_auto_outlined;
    }
  }
  
  // Show theme mode selection dialog
  void _showThemeModeDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Row(
                children: [
                  Icon(Icons.light_mode_outlined),
                  SizedBox(width: 12),
                  Text('Light Mode'),
                ],
              ),
              value: ThemeMode.light,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                Navigator.pop(context);
                themeService.setThemeMode(value!);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Row(
                children: [
                  Icon(Icons.dark_mode_outlined),
                  SizedBox(width: 12),
                  Text('Dark Mode'),
                ],
              ),
              value: ThemeMode.dark,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                Navigator.pop(context);
                themeService.setThemeMode(value!);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Row(
                children: [
                  Icon(Icons.brightness_auto_outlined),
                  SizedBox(width: 12),
                  Text('System Default'),
                ],
              ),
              value: ThemeMode.system,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                Navigator.pop(context);
                themeService.setThemeMode(value!);
              },
            ),
          ],
        ),
      ),
    );
  }
}