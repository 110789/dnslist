# 雨云 API - 错误码

## 通用错误响应格式

### 错误响应

```json
{
  "success": false,
  "error_code": "ERROR_CODE",
  "message": "错误描述信息",
  "details": {}
}
```

### 常见错误码对照表

| 错误码 | HTTP 状态码 | 说明 | 处理建议 |
|--------|-------------|------|----------|
| bad_request | 400 | 请求参数无效 | 检查请求参数格式 |
| auth_invalid_credentials | 401 | API 密钥错误 | 检查 X-Api-Key 是否正确 |
| auth_ip_not_allowed | 403 | IP 未授权 | 检查 IP 白名单设置 |
| api_access_disabled | 403 | API 访问被禁用 | 联系客服启用 API |
| not_found | 404 | 资源未找到 | 检查请求的资源 ID |
| domain_not_found | 404 | 域名未找到 | 检查域名是否正确 |
| dns_record_not_found | 404 | DNS 记录未找到 | 检查记录 ID 是否正确 |
| quota_exceeded | 429 | 配额超出 | 升级套餐或清理资源 |
| rate_limit_exceeded | 429 | 速率限制超出 | 降低请求频率 |
| provider_operation_failed | 502 | 提供商错误 | 重试或联系技术支持 |
| internal_error | 500 | 服务器内部错误 | 重试或联系技术支持 |

---

## 认证错误

### auth_invalid_credentials

**描述**: API 密钥无效或过期

**触发场景**:
- API Key 填写错误
- API Key 已被禁用
- API Key 已过期

**处理建议**:
1. 登录雨云控制台
2. 进入账号设置 > API密钥
3. 重新生成或检查 API Key
4. 确保请求头中正确传递 X-Api-Key

### auth_ip_not_allowed

**描述**: 请求 IP 不在白名单中

**触发场景**:
- 账户设置了 IP 白名单
- 当前请求 IP 不在允许列表

**处理建议**:
1. 登录雨云控制台
2. 进入 API 密钥管理
3. 检查 IP 白名单设置
4. 将当前 IP 加入白名单或移除 IP 限制

---

## 资源错误

### not_found / domain_not_found

**描述**: 请求的资源不存在

**触发场景**:
- 域名 ID 不存在
- 域名已被删除
- 域名不属于当前用户

**处理建议**:
1. 先调用域名列表接口获取正确的域名 ID
2. 检查域名是否属于当前账户
3. 确认域名是否已被删除

### dns_record_not_found

**描述**: DNS 记录不存在

**触发场景**:
- 记录 ID 不存在
- 记录已被删除

**处理建议**:
1. 先调用 DNS 记录列表接口获取正确的记录 ID
2. 确认记录是否存在

---

## 参数错误

### bad_request

**描述**: 请求参数无效

**触发场景**:
- 缺少必填参数
- 参数格式不正确
- 参数值超出允许范围

**处理建议**:
1. 对照接口文档检查必填参数
2. 检查参数格式（字符串/整数/布尔值）
3. 确认参数值是否在允许范围内

### invalid_parameter

**描述**: 参数值无效

**常见场景**:
- host 为空或格式错误
- type 不在支持列表中
- line 不在支持列表中
- ttl 值小于最小值

**处理建议**:
1. 检查 host 是否为有效的主机名
2. 确认 type 值为: A/AAAA/CNAME/MX/TXT/SRV
3. 确认 line 值为: DEFAULT/LTEL/LCNC/LMOB/LEDU/LSEO/LFOR
4. 确认 ttl >= 600

---

## 配额错误

### quota_exceeded

**描述**: 资源配额已用尽

**触发场景**:
- DNS 记录数量达到上限
- 域名数量达到上限

**处理建议**:
1. 登录雨云控制台检查套餐配额
2. 删除不需要的记录或域名
3. 考虑升级到更高套餐

---

## 速率限制错误

### rate_limit_exceeded

**描述**: 请求频率超出限制

**触发场景**:
- 短时间内请求过于频繁

**处理建议**:
1. 降低请求频率
2. 在请求间添加适当延迟
3. 批量操作时使用分页

---

## 权限错误

### permission_denied

**描述**: 无权限执行此操作

**触发场景**:
- 非资源所有者尝试操作
- 子账户权限不足

**处理建议**:
1. 确认账户是否有操作权限
2. 使用主账户进行操作

### api_access_disabled

**描述**: API 访问权限被禁用

**触发场景**:
- API 功能被限制
- 账户状态异常

**处理建议**:
1. 联系雨云客服
2. 检查账户状态

---

## 服务器错误

### internal_error

**描述**: 服务器内部错误

**触发场景**:
- 服务器端异常
- 服务暂时不可用

**处理建议**:
1. 稍后重试请求
2. 如持续出现，联系技术支持

### provider_operation_failed

**描述**: 提供商操作失败

**触发场景**:
- 第三方服务异常
- 域名注册商服务异常

**处理建议**:
1. 重试操作
2. 如持续失败，联系技术支持

---

## 特定业务错误

### domain_exists

**描述**: 域名已存在

**触发场景**:
- 尝试添加已存在的域名

**处理建议**:
1. 检查域名是否已添加
2. 使用现有域名

### template_not_found

**描述**: 域名模板不存在

**触发场景**:
- 指定的模板 ID 不存在

**处理建议**:
1. 先获取模板列表确认模板 ID

### invalid_line

**描述**: 解析线路无效

**触发场景**:
- 指定的 line 不在支持列表中
- 线路不存在

**处理建议**:
1. 确认 line 为: DEFAULT/LTEL/LCNC/LMOB/LEDU/LSEO/LFOR
2. 至少需要有一条 DEFAULT 线路的记录

---

## 错误处理流程

### 1. 检查 HTTP 状态码

| 状态码 | 含义 | 处理 |
|--------|------|------|
| 200 | 成功 | 处理响应数据 |
| 400 | 请求错误 | 检查参数 |
| 401 | 认证失败 | 检查 API Key |
| 403 | 权限不足 | 检查权限 |
| 404 | 资源不存在 | 检查资源 ID |
| 429 | 限流 | 降低频率 |
| 500 | 服务器错误 | 重试 |

### 2. 检查响应体

```json
{
  "success": false,
  "error_code": "xxx",
  "message": "xxx",
  "details": {}
}
```

### 3. 根据错误码处理

1. **认证错误**: 检查并更新 API Key
2. **参数错误**: 修正请求参数
3. **资源错误**: 确认资源存在性
4. **限流错误**: 降低请求频率
5. **服务器错误**: 重试或联系支持

---

## 错误响应示例

### 认证失败

```json
{
  "success": false,
  "error_code": "auth_invalid_credentials",
  "message": "Invalid API key"
}
```

### 资源不存在

```json
{
  "success": false,
  "error_code": "domain_not_found",
  "message": "Domain not found"
}
```

### 参数错误

```json
{
  "success": false,
  "error_code": "bad_request",
  "message": "Missing required parameter: host"
}
```

### 速率限制

```json
{
  "success": false,
  "error_code": "rate_limit_exceeded",
  "message": "Rate limit exceeded, please retry later"
}
```

---

## 注意事项

1. **错误码可能会更新**: 建议在代码中预留未知错误处理
2. **错误信息可能变化**: 不要依赖错误信息文本进行逻辑判断
3. **重试策略**: 限流和服务器错误建议使用指数退避重试
4. **记录日志**: 记录请求 ID 和错误信息便于排查问题