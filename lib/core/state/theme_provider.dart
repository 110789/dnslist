import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../../utils/storage/local_storage.dart';

enum UIStyle { md3, cupertino }

enum DarkModeOption { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const _keyUIStyle = 'ui_style';
  static const _keyDarkMode = 'app_dark_mode';

  UIStyle _uiStyle = UIStyle.md3;
  DarkModeOption _darkMode = DarkModeOption.system;

  UIStyle get uiStyle => _uiStyle;
  DarkModeOption get darkMode => _darkMode;

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

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = LocalStorage.instance;
    final styleStr = storage.getString(_keyUIStyle);
    final darkStr = storage.getString(_keyDarkMode);

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
    notifyListeners();
  }

  Future<void> setUIStyle(UIStyle style) async {
    _uiStyle = style;
    await LocalStorage.instance.setString(_keyUIStyle, style == UIStyle.cupertino ? 'cupertino' : 'md3');
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
    await LocalStorage.instance.setString(_keyDarkMode, modeStr);
    notifyListeners();
  }

  ThemeData get lightTheme => _uiStyle == UIStyle.md3 ? AppTheme.md3Light : AppTheme.md3Light;
  ThemeData get darkTheme => _uiStyle == UIStyle.md3 ? AppTheme.md3Dark : AppTheme.md3Dark;

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