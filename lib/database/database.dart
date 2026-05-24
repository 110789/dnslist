import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/storage/local_storage.dart';
import '../utils/log/log.dart';
import 'database_helper.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;
  static const String _dbName = 'dns_manager.db';
  static const int _dbVersion = 1;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final stopwatch = Stopwatch()..start();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    stopwatch.stop();

    LogService.instance.info(
      module: 'core',
      className: 'AppDatabase',
      methodName: '_initDatabase',
      action: '数据库初始化完成',
      data: {'path': path, 'version': _dbVersion},
      durationMs: stopwatch.elapsedMilliseconds,
      status: 'success',
    );
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    LogService.instance.info(
      module: 'core',
      className: 'AppDatabase',
      methodName: '_onCreate',
      action: '创建数据库表结构',
      data: {'version': version},
      status: 'success',
    );
    await DatabaseHelper.createTables(db);
    await DatabaseHelper.insertDefaultSettings(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    LogService.instance.info(
      module: 'core',
      className: 'AppDatabase',
      methodName: '_onUpgrade',
      action: '数据库版本升级',
      data: {'oldVersion': oldVersion, 'newVersion': newVersion},
      status: 'success',
    );
    await DatabaseHelper.migrate(db, oldVersion, newVersion);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}

class DatabaseInitService {
  static Future<void> initialize() async {
    await AppDatabase.instance.database;
  }

  static Future<bool> needsMigration() async {
    final storage = LocalStorage.instance;
    final dbVersion = storage.getInt('_db_version');
    return dbVersion == null;
  }

  static Future<void> runMigration() async {
    final storage = LocalStorage.instance;
    final oldCredentials = storage.getString('credentials_v2');
    final oldCipherSeed = storage.getString('credential_cipher_seed');
    final oldSelectedId = storage.getString('selected_credential_id');
    final oldUIStyle = storage.getString('ui_style');
    final oldDarkMode = storage.getString('app_dark_mode');

    final db = await AppDatabase.instance.database;

    await db.transaction((txn) async {
      if (oldCipherSeed != null) {
        await txn.insert('app_settings', {
          'setting_key': 'cipher_seed',
          'setting_value': oldCipherSeed,
          'setting_type': 'string',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      if (oldUIStyle != null) {
        await txn.insert('user_preferences', {
          'pref_key': 'ui_style',
          'pref_value': oldUIStyle,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      if (oldDarkMode != null) {
        await txn.insert('user_preferences', {
          'pref_key': 'dark_mode',
          'pref_value': oldDarkMode,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });

    if (oldCredentials != null && oldCredentials.isNotEmpty) {
      await _migrateCredentials(oldCredentials, oldSelectedId);
    }

    await storage.setInt('_db_version', 1);
  }

  static Future<void> _migrateCredentials(String encryptedData, String? selectedId) async {
    try {
      final storage = LocalStorage.instance;
      final cipherSeed = storage.getString('credential_cipher_seed') ?? '';

      final decrypted = _decryptData(encryptedData, cipherSeed);
      if (decrypted == null) return;

      final credentialList = jsonDecode(decrypted) as List;
      final db = await AppDatabase.instance.database;

      for (var i = 0; i < credentialList.length; i++) {
        final cred = credentialList[i] as Map<String, dynamic>;
        final credId = cred['id'] as String;
        final isSelected = selectedId != null && selectedId == credId;

        await db.insert('credentials', {
          'id': credId,
          'provider_id': cred['providerId'] ?? '',
          'provider_name': cred['providerName'] ?? '',
          'remark': cred['remark'],
          'credentials_json': cred['credentials'].toString(),
          'is_selected': isSelected ? 1 : 0,
          'order_index': cred['order'] ?? i,
          'created_at': _parseTimestamp(cred['createdAt']),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'is_valid': 1,
        });
      }
    } catch (e) {
      // migration failed, log and continue
    }
  }

  static String? _decryptData(String encrypted, String seed) {
    if (seed.isEmpty) return null;
    try {
      final parts = encrypted.split(':');
      if (parts.length != 2) return null;

      final seedBytes = seed.codeUnits;
      final key = List<int>.generate(32, (i) => seedBytes[i % seedBytes.length] ^ (i * 7 + 13));

      final encryptedBytes = _base64Decode(parts[1]);
      final result = <int>[];
      for (var i = 0; i < encryptedBytes.length; i++) {
        result.add(encryptedBytes[i] ^ key[i % key.length]);
      }

      return String.fromCharCodes(result);
    } catch (e) {
      return null;
    }
  }

  static List<int> _base64Decode(String input) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final output = <int>[];
    var buffer = 0;
    var bits = 0;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '=') break;
      final idx = chars.indexOf(char);
      if (idx == -1) continue;
      buffer = (buffer << 6) | idx;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        output.add((buffer >> bits) & 0xFF);
      }
    }
    return output;
  }

  static int _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is String) {
      try {
        return DateTime.parse(value).millisecondsSinceEpoch;
      } catch (_) {
        return DateTime.now().millisecondsSinceEpoch;
      }
    }
    return DateTime.now().millisecondsSinceEpoch;
  }
}