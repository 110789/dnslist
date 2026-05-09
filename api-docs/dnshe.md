# DNSHE API v2.0 Documentation

免费子域名 DNS 托管服务，提供 Cloudflare 集成。

## 基本信息

| 项目 | 内容 |
|------|------|
| Base URL | `https://api005.dnshe.com/index.php` |
| API Version | 2.0 |
| Format | JSON |
| Rate Limit | 60 requests per minute |

---

## 认证方式

所有请求需要在 Header 中传递以下参数：

```http
X-API-Key: cfsd_xxxxxxxxxx
X-API-Secret: yyyyyyyyyy
```

### 获取 API Keys

1. 登录客户端区域（Client Area）
2. 进入免费域名管理（Free Domain Management）
3. 在左侧边栏找到密钥管理（Key Management）
4. 创建新的密钥

> **注意**：出于安全考虑，URL 参数认证方式已被禁用，请仅使用 Header 方式认证。

---

## 接口列表

### 1. 列出子域名 (List Subdomains)

**接口地址**

```
GET ?m=domain_hub&endpoint=subdomains&action=list
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码（从1开始） |
| per_page | integer | 否 | 每页条目数（最大100） |
| include_total | boolean | 否 | 返回总数（响应较慢） |
| search | string | 否 | 搜索关键词 |
| rootdomain | string | 否 | 按根域名筛选 |
| status | string | 否 | 按状态筛选 |
| created_from | string | 否 | 创建时间起（筛选） |
| created_to | string | 否 | 创建时间止（筛选） |
| sort_by | string | 否 | 排序字段 |
| sort_dir | string | 否 | 排序方向（asc/desc） |
| fields | string | 否 | 逗号分隔的返回字段 |

**响应示例 (Response)**

```json
{
  "success": true,
  "count": 2,
  "subdomains": [
    {
      "id": 1,
      "subdomain": "test",
      "rootdomain": "example.com",
      "full_domain": "test.example.com",
      "status": "active",
      "created_at": "2025-10-19 10:00:00",
      "updated_at": "2025-10-19 10:00:00"
    }
  ],
  "pagination": {
    "prev_page": 1,
    "per_page": 100,
    "has_more": true,
    "next_page": 3,
    "total": 12500,
    "page": 2
  }
}
```

**cURL 示例**

```bash
curl -X GET "https://api005.dnshe.com/index.php?m=domain_hub&endpoint=subdomains&action=list" \
  -H "X-API-Key: cfsd_xxxxxxxxxx" \
  -H "X-API-Secret: yyyyyy"
```

---

### 2. 注册子域名 (Register Subdomain)

**接口地址**

```
POST ?m=domain_hub&endpoint=subdomains&action=register
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| subdomain | string | 是 | 子域名前缀 |
| rootdomain | string | 是 | 根域名 |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "Subdomain registered successfully",
  "full_domain": "myapp.example.com",
  "subdomain_id": 3
}
```

**cURL 示例**

```bash
curl -X POST "https://api005.dnshe.com/index.php?m=domain_hub&endpoint=subdomains&action=register" \
  -H "X-API-Key: cfsd_xxxxxxxxxx" \
  -H "X-API-Secret: yyyyyy" \
  -H "Content-Type: application/json" \
  -d '{"subdomain":"myapp","rootdomain":"example.com"}'
```

---

### 3. 删除子域名 (Delete Subdomain)

**接口地址**

```
POST ?m=domain_hub&endpoint=subdomains&action=delete
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| subdomain_id | integer | 是 | 子域名 ID |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "Subdomain deleted successfully",
  "subdomain_id": 1,
  "full_domain": "test.example.com",
  "dns_records_deleted": 4
}
```

**cURL 示例**

```bash
curl -X POST "https://api005.dnshe.com/index.php?m=domain_hub&endpoint=subdomains&action=delete" \
  -H "X-API-Key: cfsd_xxxxxxxxxx" \
  -H "X-API-Secret: yyyyyy" \
  -H "Content-Type: application/json" \
  -d '{"subdomain_id":1}'
```

---

### 4. 续期子域名 (Renew Subdomain)

**接口地址**

```
POST ?m=domain_hub&endpoint=subdomains&action=renew
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| subdomain_id | integer | 是 | 子域名 ID |

**响应示例 (Response)**

```json
{
  "success": true,
  "subdomain_id": 3,
  "subdomain": "myapp",
  "never_expires": 0,
  "status": "active",
  "remaining_days": 366,
  "message": "Subdomain renewed successfully (charged 9.90 credit)",
  "previous_expires_at": "2025-05-01 00:00:00",
  "new_expires_at": "2026-05-01 00:00:00",
  "renewed_at": "2025-04-10 12:34:56",
  "charged_amount": 9.9
}
```

**可能的错误码**

| 错误码 | 说明 |
|--------|------|
| no_renew_config | 续期未配置 |
| not_in_renew_window | 不在续期窗口期 |
| redemption_manual | 需要人工处理 |
| renew_grace_expired | 宽限期已过期 |
| redemption_balance_insufficient | 余额不足 |

**cURL 示例**

```bash
curl -X POST "https://api005.dnshe.com/index.php?m=domain_hub&endpoint=subdomains&action=renew" \
  -H "X-API-Key: cfsd_xxxxxxxxxx" \
  -H "X-API-Secret: yyyyyy" \
  -H "Content-Type: application/json" \
  -d '{"subdomain_id":3}'
```

---

### 5. 列出 DNS 记录 (List DNS Records)

**接口地址**

```
GET ?m=domain_hub&endpoint=dns_records&action=list
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| subdomain_id | integer | 是 | 子域名 ID |

**响应示例 (Response)**

```json
{
  "success": true,
  "count": 2,
  "records": [
    {
      "id": 1,
      "record_id": "5a0ce6c4d1d4c71bc5e60a2a2a0e4997",
      "name": "test.example.com",
      "type": "A",
      "content": "192.168.1.1",
      "ttl": 600,
      "priority": null,
      "line": null,
      "proxied": false,
      "status": "active",
      "created_at": "2025-10-19 10:05:00",
      "updated_at": "2025-10-19 10:05:00"
    }
  ]
}
```

**cURL 示例**

```bash
curl -X GET "https://api005.dnshe.com/index.php?m=domain_hub&endpoint=dns_records&action=list&subdomain_id=1" \
  -H "X-API-Key: cfsd_xxxxxxxxxx" \
  -H "X-API-Secret: yyyyyy"
```

---

### 6. 创建 DNS 记录 (Create DNS Record)

**接口地址**

```
POST ?m=domain_hub&endpoint=dns_records&action=create
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| subdomain_id | integer | 是 | 子域名 ID |
| type | string | 是 | 记录类型 (A/AAAA/CNAME/MX/TXT/etc) |
| name | string | 否 | 记录名称 |
| content | string | 条件必填 | 记录值 |
| ttl | integer | 否 | TTL（默认600） |
| priority | integer | 否 | 优先级（MX/SRV） |
| line | string | 否 | 解析线路 |
| proxied | boolean | 否 | Cloudflare 代理（默认 false） |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "DNS record created successfully",
  "id": 3,
  "record_id": "5a0ce6c4d1d4c71bc5e60a2a2a0e4997"
}
```

**cURL 示例**

```bash
curl -X POST "https://api005.dnshe.com/index.php?m=domain_hub&endpoint=dns_records&action=create" \
  -H "X-API-Key: cfsd_xxxxxxxxxx" \
  -H "X-API-Secret: yyyyyy" \
  -H "Content-Type: application/json" \
  -d '{"subdomain_id":1,"type":"A","content":"192.168.1.100","ttl":600}'
```

---

### 7. 更新 DNS 记录 (Update DNS Record)

**接口地址**

```
POST ?m=domain_hub&endpoint=dns_records&action=update
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | integer | 否* | 内部 ID |
| record_id | string | 否* | Cloudflare 记录 ID |
| type | string | 否 | 新记录类型 |
| name | string | 否 | 新名称 |
| content | string | 否 | 新内容 |
| ttl | integer | 否 | 新 TTL |
| priority | integer | 否 | 新优先级 |
| proxied | boolean | 否 | 代理状态 |

*注：至少需要提供 `id` 或 `record_id` 其中之一。

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "DNS record updated successfully",
  "id": 1,
  "record_id": "5a0ce6c4d1d4c71bc5e60a2a2a0e4997"
}
```

**cURL 示例**

```bash
curl -X POST "https://api005.dnshe.com/index.php?m=domain_hub&endpoint=dns_records&action=update" \
  -H "X-API-Key: cfsd_xxxxxxxxxx" \
  -H "X-API-Secret: yyyyyy" \
  -H "Content-Type: application/json" \
  -d '{"id":1,"type":"A","content":"192.168.1.200","ttl":600}'
```

---

### 8. 删除 DNS 记录 (Delete DNS Record)

**接口地址**

```
POST ?m=domain_hub&endpoint=dns_records&action=delete
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | integer | 否* | 内部 ID |
| record_id | string | 否* | Cloudflare 记录 ID |

*注：至少需要提供 `id` 或 `record_id` 其中之一。

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "DNS record deleted successfully"
}
```

**cURL 示例**

```bash
curl -X POST "https://api005.dnshe.com/index.php?m=domain_hub&endpoint=dns_records&action=delete" \
  -H "X-API-Key: cfsd_xxxxxxxxxx" \
  -H "X-API-Secret: yyyyyy" \
  -H "Content-Type: application/json" \
  -d '{"id":1}'
```

---

### 9. 获取配额 (Get Quota)

**接口地址**

```
GET ?m=domain_hub&endpoint=quota
```

**响应示例 (Response)**

```json
{
  "success": true,
  "quota": {
    "base": 5,
    "used": 3,
    "invite_bonus": 2,
    "total": 7,
    "available": 4
  }
}
```

**cURL 示例**

```bash
curl -X GET "https://api005.dnshe.com/index.php?m=domain_hub&endpoint=quota" \
  -H "X-API-Key: cfsd_xxxxxxxxxx" \
  -H "X-API-Secret: yyyyyy"
```

---

### 10. 获取子域名详情 (Get Subdomain Details)

**接口地址**

```
GET ?m=domain_hub&endpoint=subdomains&action=get
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| subdomain_id | integer | 是 | 子域名 ID |

---

### 11. WHOIS 查询 (Public)

**接口地址**

```
GET ?m=domain_hub&endpoint=whois&domain={domain}
```

无需认证即可查询域名状态。

---

### 12. API 密钥管理

| 接口 | 说明 |
|------|------|
| GET /keys?action=list | 列出密钥 |
| POST /keys?action=create | 创建密钥 |
| POST /keys?action=delete | 删除密钥 |
| POST /keys?action=regenerate | 重新生成密钥 |

---

## 错误响应格式

所有错误响应遵循以下结构：

```json
{
  "success": false,
  "error_code": "auth_invalid_credentials",
  "message": "Invalid API key",
  "details": {},
  "error": "Invalid API key",
  "request_id": "optional"
}
```

### 常见错误码

| 错误码 | HTTP 状态码 | 说明 |
|--------|-------------|------|
| bad_request | 400 | 请求参数无效 |
| auth_invalid_credentials | 401 | API 密钥/密钥错误 |
| auth_ip_not_allowed | 403 | IP 未授权 |
| api_access_disabled | 403 | API 访问被禁用 |
| not_found | 404 | 资源未找到 |
| subdomain_not_found | 404 | 子域名未找到 |
| dns_record_not_found | 404 | DNS 记录未找到 |
| quota_exceeded | 429 | 配额超出 |
| rate_limit_exceeded | 429 | 速率限制超出 |
| provider_operation_failed | 502 | 提供商错误 |
| internal_error | 500 | 服务器内部错误 |

---

## 速率限制

- **限制**: 60 requests per minute
- **响应头**: 包含速率限制信息

### 速率限制超出响应

```json
{
  "success": false,
  "message": "Rate limit exceeded",
  "details": {
    "error_code": "rate_limit_exceeded",
    "limit": 60,
    "remaining": 0,
    "reset_at": "2025-10-19 15:31:00"
  },
  "error": "Rate limit exceeded"
}
```

---

## 数据结构参考

### 子域名对象 (Subdomain Object)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 唯一标识符 |
| subdomain | string | 子域名前缀 |
| rootdomain | string | 根域名 |
| full_domain | string | 完整域名 |
| status | string | 子域名状态 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 最后更新时间 |

### DNS 记录对象 (DNS Record Object)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 内部记录 ID |
| record_id | string | Cloudflare 记录 ID |
| name | string | 记录名称 |
| type | string | 记录类型 |
| content | string | 记录内容/值 |
| ttl | integer | 生存时间 |
| priority | integer | 优先级（MX/SRV） |
| line | string | 解析线路 |
| proxied | boolean | 代理状态 |
| status | string | 记录状态 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 最后更新时间 |

### 分页对象 (Pagination Object)

| 字段 | 类型 | 说明 |
|------|------|------|
| page | integer | 当前页码 |
| per_page | integer | 每页条目数 |
| prev_page | integer | 上一页 |
| next_page | integer | 下一页 |
| has_more | boolean | 是否还有更多页 |
| total | integer | 总条目数 |
| total_pages | integer | 总页数 |

---

## 域名状态值

| 状态 | 说明 |
|------|------|
| active | 域名/子域名处于活跃状态 |
| pending | 注册或转移待处理 |
| expired | 域名已过期 |
| suspended | 域名已暂停 |
| deleted | 域名已删除 |