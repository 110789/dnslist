import 'dart:convert';
import '../sqlite_service.dart';
import '../database_helper.dart';
import '../../models/credential_model.dart';

class CredentialRepository {
  final SQLiteService _service = SQLiteService();

  Future<List<CredentialModel>> loadAll() async {
    final results = await _service.query(
      TableNames.credentials,
      orderBy: 'order_index ASC',
    );
    return results.map((map) => _fromMap(map)).toList();
  }

  Future<void> saveAll(List<CredentialModel> credentials) async {
    await _service.transaction((txn) async {
      await txn.delete(TableNames.credentials);
      final batch = txn.batch();
      for (var i = 0; i < credentials.length; i++) {
        batch.insert(TableNames.credentials, _toMap(credentials[i], i));
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> add(CredentialModel credential) async {
    final maxOrder = await _getMaxOrder();
    final data = _toMap(credential, maxOrder + 1);
    await _service.insert(TableNames.credentials, data);
  }

  Future<void> remove(String id) async {
    await _service.delete(
      TableNames.credentials,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<CredentialModel?> getById(String id) async {
    final result = await _service.queryFirst(
      TableNames.credentials,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result != null ? _fromMap(result) : null;
  }

  Future<void> update(CredentialModel credential) async {
    await _service.update(
      TableNames.credentials,
      _toMap(credential, credential.order),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  Future<void> saveOrder(List<CredentialModel> credentials) async {
    await _service.transaction((txn) async {
      final batch = txn.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < credentials.length; i++) {
        batch.update(
          TableNames.credentials,
          {'order_index': i, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [credentials[i].id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> saveSelectedId(String? id) async {
    if (id == null) {
      await _service.rawExecute(
        'UPDATE ${TableNames.credentials} SET is_selected = 0',
      );
    } else {
      await _service.transaction((txn) async {
        await txn.rawUpdate(
          'UPDATE ${TableNames.credentials} SET is_selected = 0',
        );
        await txn.rawUpdate(
          'UPDATE ${TableNames.credentials} SET is_selected = 1 WHERE id = ?',
          [id],
        );
      });
    }
  }

  Future<String?> getSelectedId() async {
    final result = await _service.queryFirst(
      TableNames.credentials,
      where: 'is_selected = 1',
    );
    return result?['id'] as String?;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = await loadAll();
    if (oldIndex < 0 || oldIndex >= list.length || newIndex < 0 || newIndex >= list.length) {
      return;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    await saveOrder(list);
  }

  Future<int> _getMaxOrder() async {
    final result = await _service.rawQuery(
      'SELECT MAX(order_index) as max_order FROM ${TableNames.credentials}',
    );
    final maxOrder = result.first['max_order'];
    return maxOrder != null ? maxOrder as int : 0;
  }

  Map<String, dynamic> _toMap(CredentialModel cred, int order) {
    return {
      'id': cred.id,
      'provider_id': cred.providerId,
      'provider_name': cred.providerName,
      'remark': cred.remark,
      'credentials_json': jsonEncode(cred.credentials),
      'is_selected': 0,
      'order_index': order,
      'created_at': cred.createdAt.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'is_valid': 1,
    };
  }

  CredentialModel _fromMap(Map<String, dynamic> map) {
    final credentialsJson = map['credentials_json'] as String;
    Map<String, String> credentials;
    try {
      final decoded = jsonDecode(credentialsJson);
      credentials = (decoded as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      credentials = {};
    }

    return CredentialModel(
      id: map['id'] as String,
      providerId: map['provider_id'] as String,
      providerName: map['provider_name'] as String,
      remark: map['remark'] as String?,
      credentials: credentials,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      order: map['order_index'] as int? ?? 0,
    );
  }
}