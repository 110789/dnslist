import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../../utils/driver/driver_utils.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/design_system.dart';
import '../../core/ui/md3_widgets.dart';
import 'dnspod_signer.dart';

class DnspodDriver implements DriverInterface {
  static const String _providerId = 'dnspod';
  static const String _providerName = 'DNSPod';
  static const String _providerIcon = 'assets/icons/dnspod.svg';

  static const Map<String, String> _errorCodeMap = {
    'AuthFailure.SignatureFailure': '签名错误，请检查 SecretId 和 SecretKey 是否正确',
    'AuthFailure.SignatureExpire': '签名过期，请检查本地时间是否准确',
    'AuthFailure.InvalidSecretId': '密钥非法，请检查 SecretId 是否正确',
    'AuthFailure.SecretIdNotFound': '密钥不存在，请检查 SecretId 是否正确',
    'AuthFailure.UnauthorizedOperation': '未授权操作，请检查密钥权限',
    'FailedOperation.DomainExists': '域名已在列表中，无需重复添加',
    'FailedOperation.DomainOwnedByOtherUser': '域名被其他账号添加，可在域名列表中取回',
    'FailedOperation.DomainIsLocked': '域名已被锁定，请先解锁后再操作',
    'FailedOperation.DomainIsSpam': '域名已被封禁，无法操作',
    'FailedOperation.NotDomainOwner': '域名不在您的名下，请检查域名归属',
    'FailedOperation.DomainIsVip': 'VIP 域名不支持此操作',
    'FailedOperation.DomainNotInService': '域名未使用 DNSPod 服务',
    'FailedOperation.InsufficientBalance': '账户余额不足，请充值后重试',
    'FailedOperation.FrequencyLimit': '操作过于频繁，请稍后重试',
    'FailedOperation.DomainRecordExist': '记录已存在，无需重复添加',
    'InvalidParameter.DomainInvalid': '域名格式不正确，请输入主域名',
    'InvalidParameter.DomainIdInvalid': '域名编号不正确',
    'InvalidParameter.SubdomainInvalid': '子域名格式不正确',
    'InvalidParameter.RecordTypeInvalid': '记录类型不正确',
    'InvalidParameter.RecordLineInvalid': '解析线路不正确',
    'InvalidParameter.RecordValueInvalid': '记录值格式不正确',
    'InvalidParameter.MxInvalid': 'MX 优先级范围应为 0-65535',
    'InvalidParameter.InvalidWeight': '权重范围应为 0-100',
    'InvalidParameter.RecordIdInvalid': '记录编号错误',
    'InvalidParameterValue.DomainNotExists': '域名不存在，请检查输入',
    'LimitExceeded.AAAACountLimit': 'AAAA 记录数量超出限制',
    'LimitExceeded.RecordTtlLimit': 'TTL 值超出允许范围',
    'LimitExceeded.SrvCountLimit': 'SRV 记录数量超出限制',
    'ResourceNotFound.NoDataOfRecord': '记录列表为空',
    'ResourceNotFound.NoDataOfDomain': '域名列表为空',
    'OperationDenied.AccessDenied': '没有权限执行此操作',
    'OperationDenied.NoPermissionToOperateDomain': '当前域名无操作权限',
    'RequestLimitExceeded': '请求频率超限，请稍后重试',
    'InternalError': '服务器内部错误，请稍后重试',
    'ServiceUnavailable': '服务暂时不可用，请稍后重试',
  };

  String? _secretId;
  String? _secretKey;
  ApiClient? _client;

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

@override
  String mapErrorCode(String code) => '';

  String _getGenericErrorMessage(String code) {
    final lowerCode = code.toLowerCase();
    if (lowerCode.contains('auth') || lowerCode.contains('signature')) {
      return '认证失败，请检查 API 密钥是否正确';
    }
    if (lowerCode.contains('domain') && lowerCode.contains('not')) {
      return '域名不存在或已被删除';
    }
    if (lowerCode.contains('record') && lowerCode.contains('not')) {
      return '记录不存在或已被删除';
    }
    if (lowerCode.contains('quota') || lowerCode.contains('limit')) {
      return '超出限制配额，请清理无用资源';
    }
    if (lowerCode.contains('permission') || lowerCode.contains('denied')) {
      return '权限不足，无法执行此操作';
    }
    if (lowerCode.contains('invalid') || lowerCode.contains('parameter')) {
      return '请求参数错误，请检查输入内容';
    }
    return '操作失败，请稍后重试';
  }

  @override
  String getAddDomainTitle() => '添加域名';

  @override
  List<AddDomainField> getAddDomainFields() {
    return [
      const AddDomainField(
        key: 'domain',
        label: '域名',
        hintText: '例如: example.com',
        description: '输入主域名，如 dnspod.cn',
      ),
    ];
  }

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) {
    return {
      'domain': input['domain'] ?? input['name'] ?? '',
    };
  }

  Map<String, dynamic> _parseError(dynamic responseData) {
    if (responseData == null) {
      return {'error': '服务器无响应，请稍后重试', 'errorCode': 'UNKNOWN', 'success': false};
    }
    final data = responseData is Map ? responseData : {};
    final response = data['Response'] as Map?;
    if (response != null) {
      final error = response['Error'] as Map?;
      if (error != null) {
        final code = error['Code']?.toString() ?? 'UNKNOWN';
        final rawMessage = error['Message']?.toString() ?? '';
        final mappedMessage = _errorCodeMap[code];
        if (mappedMessage != null) {
          return {'error': mappedMessage, 'errorCode': code, 'success': false, 'rawMessage': rawMessage};
        }
        return {'error': rawMessage.isNotEmpty ? rawMessage : '操作失败，请稍后重试', 'errorCode': code, 'success': false, 'rawMessage': rawMessage};
      }
    }
    return {'error': '操作失败，请稍后重试', 'errorCode': 'UNKNOWN', 'success': false};
  }

  Future<Map<String, dynamic>> _callApi(String action, Map<String, dynamic> params) async {
    if (_secretId == null || _secretKey == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final headers = buildDnspodHeaders(
        secretId: _secretId!,
        secretKey: _secretKey!,
        action: action,
        payload: params,
      );
      final client = Dio(BaseOptions(
        baseUrl: AppConfig.dnspodBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json; charset=utf-8',
        responseType: ResponseType.plain,
      ));
      client.options.headers.addAll(headers);
      final response = await client.post('', data: params);
      if (response.data == null) {
        return {'error': '服务器无响应', 'errorCode': 'UNKNOWN', 'success': false};
      }
      final respData = response.data;
      if (respData is! Map) {
        try {
          final parsed = respData is String ? _tryParseJson(respData.toString()) : respData;
          if (parsed is Map) {
            return _processResponse(parsed);
          }
        } catch (_) {}
        return {'error': '响应数据格式异常', 'errorCode': 'PARSE_ERROR', 'success': false};
      }
      return _processResponse(respData as Map);
    } on DioException catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    } catch (e) {
      return {'error': '操作失败，请稍后重试', 'errorCode': 'UNKNOWN', 'success': false};
    }
  }

  Map<String, dynamic> _processResponse(Map respData) {
    if (respData.containsKey('Response')) {
      final responseObj = respData['Response'] as Map;
      if (responseObj.containsKey('Error')) {
        return _parseError(respData);
      }
      return {'success': true, 'data': responseObj, 'statusCode': 'OK'};
    }
    return {'success': true, 'data': respData, 'statusCode': 'OK'};
  }

  dynamic _tryParseJson(String jsonStr) {
    try {
      return jsonDecode(jsonStr);
    } catch (_) {
      return null;
    }
  }

  String _handleException(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return '连接超时，请检查网络后重试';
        case DioExceptionType.receiveTimeout:
          return '服务器响应超时，请稍后重试';
        case DioExceptionType.sendTimeout:
          return '请求发送超时，请稍后重试';
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络设置';
        default:
          return '网络请求失败，请稍后重试';
      }
    }
    return '操作失败，请稍后重试';
  }

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final secretId = credentials['secretId'];
    final secretKey = credentials['secretKey'];
    if (secretId == null || secretId.isEmpty || secretKey == null || secretKey.isEmpty) {
      return {'success': false, 'error': 'SecretId 或 SecretKey 不能为空', 'errorCode': 'INVALID_CREDENTIAL'};
    }
    try {
      _secretId = secretId;
      _secretKey = secretKey;
      final result = await _callApi('DescribeUserDetail', {});
      if (result['success'] == true) {
        return {'success': true};
      }
      _secretId = null;
      _secretKey = null;
      return result;
    } catch (e) {
      _secretId = null;
      _secretKey = null;
      return {'success': false, 'error': _handleException(e), 'errorCode': 'NETWORK_ERROR'};
    }
  }

  @override
  Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (_secretId == null || _secretKey == null) {
      return {'domains': [], 'pagination': {}, 'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final params = <String, dynamic>{
        'Offset': (page - 1) * pageSize,
        'Limit': pageSize,
        'Type': 'ALL',
      };
      if (filters != null && filters.containsKey('keyword')) {
        params['Keyword'] = filters['keyword'];
      }
      final result = await _callApi('DescribeDomainList', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        final domainList = data['DomainList'] as List? ?? [];
        final countInfo = data['DomainCountInfo'] as Map? ?? {};
        final domains = domainList.map((domain) {
          return {
            'id': domain['DomainId']?.toString() ?? '',
            'domain_id': domain['DomainId'],
            'name': domain['Name']?.toString() ?? '',
            'domain': domain['Name']?.toString() ?? '',
            'status': domain['Status']?.toString()?.toLowerCase() == 'enable' ? 'active' : 'paused',
            'grade': domain['Grade']?.toString() ?? '',
            'grade_title': domain['GradeTitle']?.toString() ?? '',
            'is_vip': domain['IsVip']?.toString() == 'YES',
            'ttl': domain['TTL'] ?? 600,
            'remark': domain['Remark']?.toString() ?? '',
            'created_on': domain['CreatedOn'],
            'updated_on': domain['UpdatedOn'],
            'record_count': domain['RecordCount'] ?? 0,
            'effective_dns': domain['EffectiveDNS'] as List? ?? [],
            'punycode': domain['Punycode']?.toString() ?? '',
            'dns_status': domain['DNSStatus']?.toString() ?? '',
          };
        }).toList();
        final total = countInfo['AllTotal'] ?? countInfo['DomainTotal'] ?? domainList.length;
        return {
          'domains': domains,
          'pagination': {
            'total': total,
            'page': page,
            'per_page': pageSize,
          },
          'success': true,
          'statusCode': 'OK',
          'total': total,
          'page': page,
          'pageSize': pageSize,
        };
      }
      return _parseError(result['data']);
    } catch (e) {
      return {
        'domains': [],
        'pagination': {},
        'error': _handleException(e),
        'errorCode': 'NETWORK_ERROR',
        'success': false
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getDnsRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (_secretId == null || _secretKey == null) {
      return {'records': [], 'pagination': {}, 'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    if (domainId.isEmpty) {
      return {'records': [], 'pagination': {}, 'error': '域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }
    try {
      final domainIdInt = int.tryParse(domainId);
      final params = <String, dynamic>{
        'DomainId': domainIdInt ?? domainId,
        'Offset': (page - 1) * pageSize,
        'Limit': pageSize,
      };
      if (filters != null) {
        if (filters.containsKey('subdomain')) {
          params['Subdomain'] = filters['subdomain'];
        }
        if (filters.containsKey('record_type')) {
          params['RecordType'] = filters['record_type'];
        }
        if (filters.containsKey('record_line')) {
          params['RecordLine'] = filters['record_line'];
        }
        if (filters.containsKey('keyword')) {
          params['Keyword'] = filters['keyword'];
        }
      }
      final result = await _callApi('DescribeRecordList', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        final recordList = data['RecordList'] as List? ?? [];
        final countInfo = data['RecordCountInfo'] as Map? ?? {};
        final records = recordList.map((record) {
          return {
            'id': record['RecordId']?.toString() ?? '',
            'record_id': record['RecordId'],
            'name': record['Name']?.toString() ?? '',
            'sub_domain': record['Name']?.toString() ?? '',
            'type': record['Type']?.toString() ?? 'A',
            'record_type': record['Type']?.toString() ?? 'A',
            'value': record['Value']?.toString() ?? '',
            'content': record['Value']?.toString() ?? '',
            'ttl': record['TTL'] ?? 600,
            'mx': record['MX'] ?? 0,
            'priority': record['MX'] ?? 0,
            'line': record['Line']?.toString() ?? '默认',
            'line_id': record['LineId']?.toString() ?? '0',
            'status': record['Status']?.toString()?.toLowerCase() == 'enable' ? 'active' : 'disabled',
            'enabled': record['Status']?.toString()?.toLowerCase() == 'enable',
            'weight': record['Weight'],
            'remark': record['Remark']?.toString() ?? '',
            'updated_on': record['UpdatedOn'],
            'created_on': record['UpdatedOn'],
            'monitor_status': record['MonitorStatus']?.toString() ?? '',
          };
        }).toList();
        final total = countInfo['TotalCount'] ?? recordList.length;
        return {
          'records': records,
          'pagination': {
            'total': total,
            'page': page,
            'per_page': pageSize,
          },
          'success': true,
          'statusCode': 'OK',
          'total': total,
          'page': page,
          'pageSize': pageSize,
        };
      }
      return _parseError(result['data']);
    } catch (e) {
      return {
        'records': [],
        'pagination': {},
        'error': _handleException(e),
        'errorCode': 'NETWORK_ERROR',
        'success': false
      };
    }
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    if (_secretId == null || _secretKey == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    if (domainId.isEmpty) {
      return {'error': '域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }
    try {
      final domainIdInt = int.tryParse(domainId);
      final params = <String, dynamic>{
        'DomainId': domainIdInt ?? domainId,
      };
      final recordType = recordData['type']?.toString()?.toUpperCase() ?? recordData['record_type']?.toString()?.toUpperCase();
      if (recordType != null) params['RecordType'] = recordType;
      final recordLine = recordData['line']?.toString() ?? recordData['record_line']?.toString();
      if (recordLine != null && recordLine.isNotEmpty) {
        params['RecordLine'] = recordLine;
      } else {
        params['RecordLine'] = '默认';
      }
      final value = recordData['content']?.toString() ?? recordData['value']?.toString() ?? '';
      if (value.isNotEmpty) params['Value'] = value;
      final subDomain = recordData['name']?.toString() ?? recordData['sub_domain']?.toString();
      if (subDomain != null && subDomain.isNotEmpty) {
        params['SubDomain'] = subDomain;
      } else {
        params['SubDomain'] = '@';
      }
      final ttl = recordData['ttl'];
      if (ttl != null && ttl > 0) params['TTL'] = ttl;
      final mx = recordData['mx'] ?? recordData['priority'];
      if (mx != null && mx > 0 && (recordType == 'MX' || recordType == 'SRV')) {
        params['MX'] = mx;
      }
      final weight = recordData['weight'];
      if (weight != null && weight > 0) params['Weight'] = weight;
      final status = recordData['status'];
      if (status != null && status.toString().toLowerCase() == 'disabled') {
        params['Status'] = 'DISABLE';
      } else {
        params['Status'] = 'ENABLE';
      }
      final remark = recordData['remark'];
      if (remark != null && remark.toString().isNotEmpty) params['Remark'] = remark.toString();
      final result = await _callApi('CreateRecord', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': data['RecordId']?.toString() ?? '',
            'record_id': data['RecordId'],
          },
          'message': 'DNS 记录创建成功'
        };
      }
      return _parseError(result['data']);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (_secretId == null || _secretKey == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    if (domainId.isEmpty || recordId.isEmpty) {
      return {'error': '域名或记录标识无效', 'errorCode': 'INVALID_ID', 'success': false};
    }
    try {
      final domainIdInt = int.tryParse(domainId);
      final recordIdInt = int.tryParse(recordId);
      final params = <String, dynamic>{
        'DomainId': domainIdInt ?? domainId,
        'RecordId': recordIdInt ?? recordId,
      };
      final recordType = recordData['type']?.toString()?.toUpperCase() ?? recordData['record_type']?.toString()?.toUpperCase();
      if (recordType != null) params['RecordType'] = recordType;
      final recordLine = recordData['line']?.toString() ?? recordData['record_line']?.toString();
      if (recordLine != null && recordLine.isNotEmpty) {
        params['RecordLine'] = recordLine;
      } else {
        params['RecordLine'] = '默认';
      }
      final value = recordData['content']?.toString() ?? recordData['value']?.toString() ?? '';
      if (value.isNotEmpty) params['Value'] = value;
      final subDomain = recordData['name']?.toString() ?? recordData['sub_domain']?.toString();
      if (subDomain != null && subDomain.isNotEmpty) {
        params['SubDomain'] = subDomain;
      } else {
        params['SubDomain'] = '@';
      }
      final ttl = recordData['ttl'];
      if (ttl != null && ttl > 0) params['TTL'] = ttl;
      final mx = recordData['mx'] ?? recordData['priority'];
      if (mx != null && mx > 0 && (recordType == 'MX' || recordType == 'SRV')) {
        params['MX'] = mx;
      }
      final weight = recordData['weight'];
      if (weight != null && weight > 0) params['Weight'] = weight;
      if (recordData.containsKey('status')) {
        params['Status'] = recordData['status'].toString().toLowerCase() == 'disabled' ? 'DISABLE' : 'ENABLE';
      }
      if (recordData.containsKey('remark')) {
        params['Remark'] = recordData['remark']?.toString() ?? '';
      }
      final result = await _callApi('ModifyRecord', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': data['RecordId']?.toString() ?? recordId,
            'record_id': data['RecordId'] ?? recordIdInt,
          },
          'message': 'DNS 记录更新成功'
        };
      }
      return _parseError(result['data']);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_secretId == null || _secretKey == null) {
      return {'success': false, 'error': '未初始化认证', 'errorCode': 'AUTH_REQUIRED'};
    }
    if (domainId.isEmpty || recordId.isEmpty) {
      return {'success': false, 'error': '域名或记录标识无效', 'errorCode': 'INVALID_ID'};
    }
    try {
      final domainIdInt = int.tryParse(domainId);
      final recordIdInt = int.tryParse(recordId);
      final params = <String, dynamic>{
        'DomainId': domainIdInt ?? domainId,
        'RecordId': recordIdInt ?? recordId,
      };
      final result = await _callApi('DeleteRecord', params);
      if (result['success'] == true) {
        return {'success': true, 'statusCode': 'OK'};
      }
      return _parseError(result['data']);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_secretId == null || _secretKey == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    final domain = domainData['domain']?.toString() ?? domainData['name']?.toString() ?? '';
    if (domain.isEmpty) {
      return {'error': '域名不能为空', 'errorCode': 'INVALID_DOMAIN', 'success': false};
    }
    try {
      final params = <String, dynamic>{'Domain': domain};
      final result = await _callApi('CreateDomain', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        final domainInfo = data['DomainInfo'] as Map? ?? {};
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': domainInfo['Id']?.toString() ?? domainInfo['DomainId']?.toString() ?? '',
            'domain_id': domainInfo['Id'] ?? domainInfo['DomainId'],
            'name': domainInfo['Domain']?.toString() ?? domain,
            'domain': domainInfo['Domain']?.toString() ?? domain,
            'punycode': domainInfo['Punycode']?.toString() ?? domain,
          },
          'message': '域名添加成功'
        };
      }
      return _parseError(result['data']);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_secretId == null || _secretKey == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    if (domainId.isEmpty) {
      return {'error': '域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }
    try {
      final domainIdInt = int.tryParse(domainId);
      final params = <String, dynamic>{'DomainId': domainIdInt ?? domainId};
      final result = await _callApi('DeleteDomain', params);
      if (result['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': '域名已删除'};
      }
      return _parseError(result['data']);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    return {'error': 'DNSPod 域名续期需在腾讯云控制台操作，不支持 API 续期', 'errorCode': 'NOT_SUPPORTED', 'success': false};
  }

  @override
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => false;

  @override
  bool get supportsShowNameServers => false;

  @override
  Widget buildDomainListItem(Map<String, dynamic> domainData, {
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required bool supportsDelete,
    required bool supportsRenew,
  }) {
    return const SizedBox.shrink();
  }

  @override
  void showDomainListItemMenu(BuildContext context, Map<String, dynamic> domainData, {
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required VoidCallback onShowNameServers,
    required bool supportsDelete,
    required bool supportsRenew,
    required bool supportsShowNameServers,
  }) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + renderBox.size.width / 2,
        offset.dy + renderBox.size.height / 2,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      items: [
        if (supportsDelete) PopupMenuItem(value: 'delete', child: const Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ).then((value) {
      if (value == 'delete') onDelete();
    });
  }

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    final name = recordData['name']?.toString() ?? recordData['sub_domain']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? recordData['record_type']?.toString() ?? 'A';
    final content = recordData['content']?.toString() ?? recordData['value']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 600;
    final priority = recordData['priority'] ?? recordData['mx'];
    final enabled = recordData['enabled'] == true || recordData['status']?.toString()?.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: DnsDesignTokens.getDnsTypeColor(type),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: type.length <= 2 ? 14 : 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (priority != null && priority > 0) ...[
                      const SizedBox(width: 4),
                      Text('P$priority', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DnsDesignTokens.dnsTypeMX)),
                    ],
                    if (!enabled) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text('暂停', style: TextStyle(fontSize: 9, color: Colors.orange)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(content, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DnsTtlTag(ttl: ttl),
        ],
      ),
    );
  }

  @override
  Map<String, String> getCredentialFields() {
    return {'secretId': 'SecretId', 'secretKey': 'SecretKey'};
  }

  @override
  List<String> getSupportedRecordTypes() {
    return ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA', 'URL', 'SPF'];
  }
}