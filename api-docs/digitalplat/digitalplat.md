# DigitalPlat API v1 Documentation

域名注册和管理 API 服务。

## 基本信息

| 项目 | 内容 |
|------|------|
| Base URL | `https://domain-api.digitalplat.org/api/v1` |
| API Version | v1 |
| Format | JSON |

---

## 认证方式

所有请求需要在 Header 中传递 Bearer Token：

```http
Authorization: Bearer dp_live_xxxxxxxxxxxxxxxxx
```

### API Key 格式

- **生产密钥**: `dp_live_...`
- **测试密钥**: `dp_test_...`

> **注意**: 生产环境使用生产密钥，开发环境使用测试密钥。

---

## 响应结构

所有响应遵循以下格式：

```json
{
  "success": true,
  "data": { ... },
  "meta": { ... }
}
```

---

## 接口列表

### 1. 列出域名 (List Domains)

**接口地址**

```
GET /domains
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码 |
| per_page | integer | 否 | 每页条目数 |
| search | string | 否 | 搜索域名 |
| status | string | 否 | 按状态筛选 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": [
    {
      "created_at": "20250327",
      "dns_server": "Specify server",
      "domain": "alist.us.kg",
      "expires_at": "20270327",
      "lifecycle_type": "permanent",
      "nameservers": [
        "mustafa.ns.cloudflare.com",
        "aron.ns.cloudflare.com"
      ],
      "registrant": "Christopher L Eby",
      "registrar": "DigitalPlat Registrar",
      "slot_type": "free",
      "status": "ok",
      "subscription_stage": null,
      "whois_privacy": "Disabled",
      "zone": ".us.kg"
    }
  ],
  "meta": {
    "count": 4
  }
}
```

**cURL 示例**

```bash
curl "https://domain-api.digitalplat.org/api/v1/domains" \
  -H "Authorization: Bearer dp_live_xxxxxxxxxxxxxxxxx"
```

---

### 2. 注册域名 (Register Domain)

**接口地址**

```
POST /domains
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| domain | string | 是 | 要注册的域名 |
| slot_type | string | 是 | 类型：free, paid 或 subscription |
| nameservers | array | 是 | 名称服务器字符串数组 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": {
    "name": "example.us.kg",
    "status": "ok",
    "slot_type": "subscription",
    "lifecycle_type": "subscription"
  },
  "meta": {}
}
```

**cURL 示例**

```bash
curl "https://domain-api.digitalplat.org/api/v1/domains" \
  -X POST \
  -H "Authorization: Bearer dp_live_xxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.us.kg",
    "slot_type": "subscription",
    "nameservers": [
      "ns1.provider.com",
      "ns2.provider.com"
    ]
  }'
```

---

### 3. 更新名称服务器 (Update Nameservers)

**接口地址**

```
PATCH /domains/{domain}/nameservers
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| domain | string | 域名 |

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| nameservers | array | 是 | 名称服务器字符串数组 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": {
    "name": "example.us.kg",
    "nameservers": ["ns1.provider.com", "ns2.provider.com"]
  },
  "meta": {}
}
```

**cURL 示例**

```bash
curl "https://domain-api.digitalplat.org/api/v1/domains/example.us.kg/nameservers" \
  -X PATCH \
  -H "Authorization: Bearer dp_live_xxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "nameservers": [
      "ns1.provider.com",
      "ns2.provider.com"
    ]
  }'
```

---

### 4. 删除域名 (Delete Domain)

**接口地址**

```
DELETE /domains/{domain}
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| domain | string | 域名 |

> **注意**: 删除域名后，DNS 会立即禁用，域名将在 7 天后释放。

**响应示例 (Response)**

```json
{
  "success": true,
  "data": {
    "domain": "example.us.kg",
    "status": "pendingdelete"
  },
  "meta": {}
}
```

**cURL 示例**

```bash
curl "https://domain-api.digitalplat.org/api/v1/domains/example.us.kg" \
  -X DELETE \
  -H "Authorization: Bearer dp_live_xxxxxxxxxxxxxxxxx"
```

---

### 5. 获取账户信息 (Get Account Info)

**接口地址**

```
GET /me
```

**响应示例 (Response)**

```json
{
  "success": true,
  "data": {
    "account_id": "...",
    "email": "user@example.com",
    "created_at": "2024-01-01"
  },
  "meta": {}
}
```

**cURL 示例**

```bash
curl "https://domain-api.digitalplat.org/api/v1/me" \
  -H "Authorization: Bearer dp_live_xxxxxxxxxxxxxxxxx"
```

---

## 错误响应格式

```json
{
  "success": false,
  "error": "error message",
  "data": null,
  "meta": {}
}
```

### 错误码说明

| 错误码 | 说明 |
|--------|------|
| domain_taken | 域名已被占用 |
| invalid_slot_type | 无效的 slot_type 值 |
| nameserver_required | 需要提供名称服务器 |
| invalid_domain | 无效的域名格式 |
| authentication_failed | 无效的 API 密钥 |
| rate_limit_exceeded | 请求过于频繁 |

---

## 数据结构参考

### 域名对象 (Domain Object)

| 字段 | 类型 | 说明 |
|------|------|------|
| domain | string | 完整域名 |
| status | string | 域名状态 (ok/pending/pendingdelete) |
| slot_type | string | 类型：free/paid/subscription |
| lifecycle_type | string | 生命周期类型：permanent/subscription |
| expires_at | string | 过期日期 (YYYYMMDD) |
| created_at | string | 创建日期 (YYYYMMDD) |
| nameservers | array | 名称服务器字符串数组 |
| registrant | string | 注册人名称 |
| registrar | string | 注册商名称 |
| dns_server | string | DNS 服务器配置 |
| zone | string | 区域后缀 |
| whois_privacy | string | Whois 隐私保护：Enabled/Disabled |
| subscription_stage | string | 订阅阶段（可为空） |

### Slot Types (插槽类型)

| 类型 | 说明 |
|------|------|
| free | 免费层域名 |
| paid | 付费层域名 |
| subscription | 订阅层域名 |

> **注意**: 如 .us.kg 和 .xx.kg 等付费专属后缀需要付费或订阅额度。

### Lifecycle Types (生命周期类型)

| 类型 | 说明 |
|------|------|
| permanent | 永久注册 |
| subscription | 活跃订阅 |

### Domain Status Values (域名状态值)

| 状态 | 说明 |
|------|------|
| ok | 活跃且健康 |
| pending | 注册待处理 |
| pendingdelete | 等待删除 |
| expired | 已过期 |
| redemption | 赎回期 |
| transferred | 已转出 |

---

## 分页

**请求参数**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| page | 1 | 页码 |
| per_page | 20 | 每页条目数 |

**响应示例**

```json
{
  "meta": {
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 45,
      "total_pages": 3
    }
  }
}
```

---

## 速率限制

- **限制**: 因端点而异
- **建议**: 使用指数退避策略处理 429 错误 |

---

## 字段映射参考

### 域名字段对照表

| 概念 | DigitalPlat 字段 |
|------|-----------------|
| 域名 | domain |
| 状态 | status |
| 创建日期 | created_at |
| 过期日期 | expires_at |
| 名称服务器 | nameservers[] |