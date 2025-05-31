import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColors = true;
  
  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColors => _useDynamicColors;
  
  ThemeService() {
    _loadPreferences();
  }
  
  // Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    
    _useDynamicColors = prefs.getBool('use_dynamic_colors') ?? true;
    
    notifyListeners();
  }
  
  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    
    notifyListeners();
  }
  
  // Set dynamic colors
  Future<void> setDynamicColors(bool value) async {
    _useDynamicColors = value;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_dynamic_colors', value);
    
    notifyListeners();
  }
  
  // Get light theme
  ThemeData getLightTheme(ColorScheme? dynamicLightColorScheme) {
    if (_useDynamicColors && dynamicLightColorScheme != null) {
      return ThemeData(
        colorScheme: dynamicLightColorScheme,
        useMaterial3: true,
      );
    }
    
    // Default light theme with blue primary color
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
  
  // Get dark theme
  ThemeData getDarkTheme(ColorScheme? dynamicDarkColorScheme) {
    if (_useDynamicColors && dynamicDarkColorScheme != null) {
      return ThemeData(
        colorScheme: dynamicDarkColorScheme,
        useMaterial3: true,
      );
    }
    
    // Default dark theme with blue primary color
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}