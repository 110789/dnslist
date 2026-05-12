import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credentials (
        id TEXT PRIMARY KEY,
        provider_id TEXT NOT NULL,
        provider_name TEXT NOT NULL,
        remark TEXT,
        credentials_json TEXT NOT NULL,
        is_selected INTEGER DEFAULT 0,
        order_index INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_validated_at INTEGER,
        is_valid INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_credentials_provider ON credentials(provider_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_credentials_selected ON credentials(is_selected)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_credentials_order ON credentials(order_index)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pref_key TEXT NOT NULL UNIQUE,
        pref_value TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_key TEXT NOT NULL UNIQUE,
        setting_value TEXT NOT NULL,
        setting_type TEXT DEFAULT 'string',
        is_hidden INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS domain_cache (
        id TEXT PRIMARY KEY,
        credential_id TEXT NOT NULL,
        domain_name TEXT NOT NULL,
        domain_data_json TEXT,
        cached_at INTEGER NOT NULL,
        expires_at INTEGER,
        FOREIGN KEY (credential_id) REFERENCES credentials(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_domain_cache_credential ON domain_cache(credential_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_domain_cache_name ON domain_cache(domain_name)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dns_record_cache (
        id TEXT PRIMARY KEY,
        domain_id TEXT NOT NULL,
        credential_id TEXT NOT NULL,
        record_data_json TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        expires_at INTEGER,
        FOREIGN KEY (domain_id) REFERENCES domain_cache(id) ON DELETE CASCADE,
        FOREIGN KEY (credential_id) REFERENCES credentials(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_dns_record_cache_domain ON dns_record_cache(domain_id)
    ''');
  }

  static Future<void> insertDefaultSettings(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('app_settings', {
      'setting_key': 'db_version',
      'setting_value': '1',
      'setting_type': 'int',
      'updated_at': now,
    });

    await db.insert('app_settings', {
      'setting_key': 'app_version',
      'setting_value': '1.0.0',
      'setting_type': 'string',
      'updated_at': now,
    });

    await db.insert('app_settings', {
      'setting_key': 'first_launch',
      'setting_value': 'true',
      'setting_type': 'bool',
      'updated_at': now,
    });
  }

  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      // Future migrations can be added here
    }
  }
}

class TableNames {
  static const String credentials = 'credentials';
  static const String userPreferences = 'user_preferences';
  static const String appSettings = 'app_settings';
  static const String domainCache = 'domain_cache';
  static const String dnsRecordCache = 'dns_record_cache';
}

class PrefKeys {
  static const String uiStyle = 'ui_style';
  static const String darkMode = 'dark_mode';
  static const String language = 'language';
  static const String autoRefreshInterval = 'auto_refresh_interval';
  static const String lastSelectedCredentialId = 'last_selected_credential_id';
}

class SettingKeys {
  static const String dbVersion = 'db_version';
  static const String appVersion = 'app_version';
  static const String firstLaunch = 'first_launch';
  static const String lastSyncTime = 'last_sync_time';
  static const String cachePolicy = 'cache_policy';
  static const String cipherSeed = 'cipher_seed';
}