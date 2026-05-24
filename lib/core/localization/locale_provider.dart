import 'package:flutter/material.dart';
import '../../utils/storage/local_storage.dart';

class LocaleProvider extends ChangeNotifier {
  static const _keyLocale = 'app_locale';

  Locale? _locale;
  bool _isLoaded = false;

  Locale? get locale => _locale;
  bool get isLoaded => _isLoaded;
  bool get isManual => _locale != null;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final storage = LocalStorage.instance;
    final saved = storage.getString(_keyLocale);
    if (saved != null && saved.isNotEmpty) {
      final parts = saved.split('_');
      if (parts.length >= 2 && parts[1].length == 4) {
        _locale = Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
      } else if (parts.length >= 2) {
        _locale = Locale(parts[0], parts[1]);
      } else {
        _locale = Locale(saved);
      }
    } else {
      _locale = null;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    final storage = LocalStorage.instance;
    if (locale == null) {
      await storage.remove(_keyLocale);
    } else if (locale.scriptCode != null) {
      await storage.setString(_keyLocale, '${locale.languageCode}_${locale.scriptCode}');
    } else {
      await storage.setString(_keyLocale, locale.languageCode);
    }
    notifyListeners();
  }

  bool get useSystemLocale => _locale == null;
}
