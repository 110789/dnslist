class ApiResult<T> {
  final bool success;
  final T? data;
  final String? errorCode;
  final String? errorMessage;
  final int? statusCode;

  ApiResult({
    required this.success,
    this.data,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiResult.success(T data, {String? statusCode}) {
    return ApiResult(
      success: true,
      data: data,
      errorCode: statusCode,
    );
  }

  factory ApiResult.failure(String code, String message, {int? httpCode}) {
    return ApiResult(
      success: false,
      errorCode: code,
      errorMessage: message,
      statusCode: httpCode,
    );
  }
}

class StatusCodeMapper {
  static String mapToMessage(String provider, String? code, String? defaultMessage) {
    if (code == null) return defaultMessage ?? '操作失败';
    
    switch (provider.toLowerCase()) {
      case 'cloudflare':
        return _mapCloudflareCode(code);
      case 'dnshe':
        return _mapDnsheCode(code);
      default:
        return defaultMessage ?? code;
    }
  }

  static String _mapCloudflareCode(String code) {
    final Map<String, String> codeMap = {
      '1000': '认证失败，请检查 API Token 是否正确',
      '1001': '资源不存在',
      '1002': '请求参数验证失败',
      '1003': '操作失败，请稍后重试',
      '1004': '请求频率超限，请稍后重试',
      '1005': '资源已存在',
      '7000': '区域不存在',
      '7001': '区域已存在',
      '7003': '区域不可用',
      '9100': '权限不足，缺少必要权限',
      '9101': '权限不足，无法访问此资源',
      '9109': '未授权访问请求的资源',
      '10200': '账户问题导致操作被阻止',
    };
    return codeMap[code] ?? 'Cloudflare 错误: $code';
  }

  static String _mapDnsheCode(String code) {
    final Map<String, String> codeMap = {
      'auth_invalid_credentials': 'API 密钥或密钥 Secret 错误',
      'auth_ip_not_allowed': 'IP 地址未授权',
      'api_access_disabled': 'API 访问已被禁用',
      'not_found': '资源不存在',
      'subdomain_not_found': '子域名不存在',
      'dns_record_not_found': 'DNS 记录不存在',
      'quota_exceeded': '配额已超出限制',
      'rate_limit_exceeded': '请求频率超限，请稍后重试',
      'provider_operation_failed': '服务商操作失败',
      'internal_error': '服务器内部错误',
      'no_renew_config': '续期未配置',
      'not_in_renew_window': '不在续期窗口期内',
      'redemption_manual': '需要人工处理',
      'renew_grace_expired': '宽限期已过期',
      'redemption_balance_insufficient': '余额不足',
      'bad_request': '请求参数无效',
    };
    return codeMap[code] ?? 'DNSHE 错误: $code';
  }
}