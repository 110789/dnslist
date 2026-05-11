# ClouDNS API - 错误码

## 通用错误响应

所有错误响应格式：

```json
{
  "status": "Failed",
  "statusDescription": "错误描述信息"
}
```

---

## 认证错误

| 错误码 | 描述 | 触发场景 |
|--------|------|----------|
| Invalid authentication, incorrect auth-id or auth-password. | auth-id 或密码错误 | API 用户认证失败 |
| Invalid authentication, incorrect sub-auth-id, sub-auth-user or auth-password. | 子用户凭证错误 | 子用户认证失败 |
| Wrong or missing required parameter 'auth-id'. | 缺少 auth-id | 未提供认证参数 |

**处理建议**: 检查 auth-id 和 auth-password 是否正确

---

## 参数错误

| 错误码 | 描述 | 触发场景 |
|--------|------|----------|
| Missing domain-name | 缺少域名 | 未提供 domain-name 参数 |
| Missing required parameter 'page'. | 缺少 page 参数 | 分页请求未提供 page |
| Wrong or missing required parameter 'rows-per-page'. | rows-per-page 无效 | 分页参数不正确 |
| Missing required parameter 'id'. | 缺少记录 ID | 未提供记录 ID |
| Wrong or missing required parameter 'password'. | 密码无效 | 密码参数错误 |
| Invalid TTL. Choose from the list of the values we support. | TTL 值无效 | 使用了不支持的 TTL |
| This record type is not supported. | 记录类型不支持 | 使用了不支持的记录类型 |
| Invalid record-id param. | record-id 无效 | 记录 ID 不存在 |
| This is not a domain name. | 域名格式错误 | 记录值不是有效域名 |
| This is not a valid IP address. | IP 地址错误 | 记录值不是有效 IP |
| The domain must be pointed to an URL as shown in the example. | URL 格式错误 | Web redirect 记录值错误 |

**处理建议**: 检查请求参数是否正确提供，格式是否有效

---

## 资源错误

| 错误码 | 描述 | 触发场景 |
|--------|------|----------|
| There is no such zone. | Zone 不存在 | 域名不存在 |
| There is no such record. | 记录不存在 | 记录不存在 |
| This domain is already taken. | 域名已存在 | 重复添加域名 |
| Zone is already deleted. | Zone 已删除 | 重复删除操作 |
| You can't add records in this type of zone. | Zone 类型不支持 | slave zone 添加记录 |
| This feature is not available for your plan. | 套餐不支持 | 功能超出套餐限制 |

**处理建议**: 确认资源存在性和操作权限

---

## 权限错误

| 错误码 | 描述 | 触发场景 |
|--------|------|----------|
| You don't have access to this zone. | 无 Zone 权限 | 子用户无操作权限 |
| You don't have access to this record. | 无记录权限 | 子用户无操作权限 |
| This is not a master zone. | Zone 类型错误 | 在非 master zone 操作 |
| You can't delete this record. | 无法删除记录 | 权限不足 |

**处理建议**: 检查子用户权限配置和 Zone 委托

---

## 配额错误

| 错误码 | 描述 | 触发场景 |
|--------|------|----------|
| You have reached the zones limit for this sub-user. | 达到 Zone 上限 | 子用户 Zone 配额用尽 |
| You have reached the records limit for this sub-user. | 达到记录上限 | 子用户记录配额用尽 |
| You have reached the limits of your plan. | 达到套餐上限 | 账户配额用尽 |

**处理建议**: 升级套餐或删除不需要的资源

---

## 操作错误

| 错误码 | 描述 | 触发场景 |
|--------|------|----------|
| Zone update is failed. | Zone 更新失败 | 服务器端错误 |
| Record update is failed. | 记录更新失败 | 服务器端错误 |
| Zone delete is failed. | Zone 删除失败 | 服务器端错误 |
| Record delete is failed. | 记录删除失败 | 服务器端错误 |
| Zone creation is failed. | Zone 创建失败 | 服务器端错误 |
| Record creation is failed. | 记录创建失败 | 服务器端错误 |

**处理建议**: 重试操作，如持续失败请联系技术支持

---

## 格式错误

| 错误码 | 描述 | 触发场景 |
|--------|------|----------|
| Invalid IP address. | IP 地址格式错误 | IP 参数格式不正确 |
| Invalid domain name. | 域名格式错误 | 域名格式不正确 |
| Invalid email address. | 邮箱格式错误 | 邮箱格式不正确 |

**处理建议**: 检查输入格式是否符合规范

---

## 限制错误

| 错误码 | 描述 | 触发场景 |
|--------|------|----------|
| Rate limit exceeded. | 请求频率超限 | 超过速率限制 |
| Too many requests. | 请求过多 | 超过配额限制 |

**处理建议**: 降低请求频率

---

## 子用户错误

| 错误码 | 描述 | 触发场景 |
|--------|------|----------|
| There is no such sub-user. | 子用户不存在 | 子用户 ID 不存在 |
| Wrong password. | 密码错误 | 子用户密码错误 |
| Wrong or missing required parameter 'username'. | 用户名参数错误 | 用户名参数问题 |

---

## 错误处理建议

### 认证错误处理

1. 确认 auth-id 是否正确
2. 确认 auth-password 是否正确
3. 检查是否设置了 IP 白名单限制

### 参数错误处理

1. 对照文档检查必填参数
2. 确认参数格式（Integer/String）
3. 检查参数值是否在允许范围内

### 资源错误处理

1. 先查询确认资源是否存在
2. 检查操作是否对该 Zone 类型允许
3. 确认套餐是否支持该功能

### 权限错误处理

1. 检查子用户是否被委托该 Zone
2. 检查子用户的 access_level
3. 确认子用户的配额是否足够

---

## 错误响应示例

### 认证失败

```json
{
  "status": "Failed",
  "statusDescription": "Invalid authentication, incorrect auth-id or auth-password."
}
```

### 参数缺失

```json
{
  "status": "Failed",
  "statusDescription": "Missing domain-name"
}
```

### 资源不存在

```json
{
  "status": "Failed",
  "statusDescription": "There is no such zone."
}
```

### TTL 无效

```json
{
  "status": "Failed",
  "statusDescription": "Invalid TTL. Choose from the list of the values we support."
}
```

---

## 注意事项

1. **status**: 固定为 "Failed" 表示失败
2. **statusDescription**: 错误描述，可能随版本变化
3. **错误码**: 基于 statusDescription 关键字识别
4. **处理建议**: 根据具体错误进行相应处理