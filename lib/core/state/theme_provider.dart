import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../theme/design_system.dart';
import '../../utils/storage/local_storage.dart';
import '../../database/repositories/user_preferences_repository.dart';

enum UIStyle { md3, cupertino }

enum DarkModeOption { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const _keyUIStyle = 'ui_style';
  static const _keyDarkMode = 'app_dark_mode';
  static const _keySeedColor = 'seed_color_id';

  final UserPreferencesRepository? _repository;
  UIStyle _uiStyle = UIStyle.md3;
  DarkModeOption _darkMode = DarkModeOption.system;
  String _seedColorId = ThemeColors.defaultOption.id;
  bool _useSQLite = false;

  UIStyle get uiStyle => _uiStyle;
  DarkModeOption get darkMode => _darkMode;
  String get seedColorId => _seedColorId;
  Color get seedColor => ThemeColors.findById(_seedColorId).color;
  Color get seedColorDark => ThemeColors.findById(_seedColorId).darkColor;
  ThemeColorOption get seedColorOption => ThemeColors.findById(_seedColorId);

  bool get isDarkMode {
    switch (_darkMode) {
      case DarkModeOption.light:
        return false;
      case DarkModeOption.dark:
        return true;
      case DarkModeOption.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  ThemeProvider({UserPreferencesRepository? repository}) : _repository = repository {
    _useSQLite = _repository != null;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_useSQLite && _repository != null) {
      final styleStr = await _repository!.getString(_keyUIStyle);
      final darkStr = await _repository!.getString(_keyDarkMode);
      final seedStr = await _repository!.getString(_keySeedColor);

      if (styleStr != null) {
        _uiStyle = styleStr == 'cupertino' ? UIStyle.cupertino : UIStyle.md3;
      }
      if (darkStr != null) {
        _darkMode = darkStr == 'dark'
            ? DarkModeOption.dark
            : darkStr == 'light'
                ? DarkModeOption.light
                : DarkModeOption.system;
      }
      if (seedStr != null && ThemeColors.options.any((o) => o.id == seedStr)) {
        _seedColorId = seedStr;
      }
    } else {
      final storage = LocalStorage.instance;
      final styleStr = storage.getString(_keyUIStyle);
      final darkStr = storage.getString(_keyDarkMode);
      final seedStr = storage.getString(_keySeedColor);

      if (styleStr != null) {
        _uiStyle = styleStr == 'cupertino' ? UIStyle.cupertino : UIStyle.md3;
      }
      if (darkStr != null) {
        _darkMode = darkStr == 'dark'
            ? DarkModeOption.dark
            : darkStr == 'light'
                ? DarkModeOption.light
                : DarkModeOption.system;
      }
      if (seedStr != null && ThemeColors.options.any((o) => o.id == seedStr)) {
        _seedColorId = seedStr;
      }
    }
    notifyListeners();
  }

  Future<void> setUIStyle(UIStyle style) async {
    _uiStyle = style;
    final value = style == UIStyle.cupertino ? 'cupertino' : 'md3';

    if (_useSQLite && _repository != null) {
      await _repository!.setString(_keyUIStyle, value);
    } else {
      await LocalStorage.instance.setString(_keyUIStyle, value);
    }
    notifyListeners();
  }

  Future<void> setDarkMode(DarkModeOption mode) async {
    _darkMode = mode;
    String modeStr;
    switch (mode) {
      case DarkModeOption.light: modeStr = 'light'; break;
      case DarkModeOption.dark: modeStr = 'dark'; break;
      case DarkModeOption.system: modeStr = 'system'; break;
    }

    if (_useSQLite && _repository != null) {
      await _repository!.setString(_keyDarkMode, modeStr);
    } else {
      await LocalStorage.instance.setString(_keyDarkMode, modeStr);
    }
    notifyListeners();
  }

  Future<void> setSeedColor(String colorId) async {
    if (!ThemeColors.options.any((o) => o.id == colorId)) return;
    _seedColorId = colorId;

    if (_useSQLite && _repository != null) {
      await _repository!.setString(_keySeedColor, colorId);
    } else {
      await LocalStorage.instance.setString(_keySeedColor, colorId);
    }
    notifyListeners();
  }

  ThemeData get lightTheme => AppTheme.md3Light(seedColor: seedColor);
  ThemeData get darkTheme => AppTheme.md3Dark(seedColor: seedColorDark);

  CupertinoThemeData get cupertinoLightTheme => AppTheme.cupertinoLight;
  CupertinoThemeData get cupertinoDarkTheme => AppTheme.cupertinoDark;
}

class AdaptiveTheme extends StatelessWidget {
  final ThemeProvider themeProvider;
  final Widget child;

  const AdaptiveTheme({
    super.key,
    required this.themeProvider,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        if (themeProvider.uiStyle == UIStyle.cupertino) {
          final brightness = themeProvider.isDarkMode ? Brightness.dark : Brightness.light;
          return CupertinoTheme(
            data: brightness == Brightness.dark
                ? AppTheme.cupertinoDark
                : AppTheme.cupertinoLight,
            child: child,
          );
        }
        return Theme(
          data: themeProvider.isDarkMode ? themeProvider.darkTheme : themeProvider.lightTheme,
          child: child,
        );
      },
    );
  }
}