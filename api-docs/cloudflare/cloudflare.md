# Cloudflare API v4 Documentation

企业级 DNS 和 CDN 提供商 API 参考文档。

## 基本信息

| 项目 | 内容 |
|------|------|
| Base URL | `https://api.cloudflare.com/client/v4` |
| API Version | v4 |
| Format | JSON |
| 官方文档 | [Cloudflare API Docs](https://developers.cloudflare.com/api) |

---

## 认证方式

所有请求需要在 Header 中传递 Bearer Token：

```http
Authorization: Bearer CLOUDFLARE_API_TOKEN
```

> **获取 API Token**: 在 Cloudflare Dashboard 中进入 Profile > API Tokens 创建。

---

## 响应结构

**成功响应**

```json
{
  "success": true,
  "result": { ... },
  "result_info": { ... },
  "errors": [],
  "messages": []
}
```

**错误响应**

```json
{
  "success": false,
  "errors": [
    {
      "code": 1000,
      "message": "Authentication error"
    }
  ],
  "result": null
}
```

---

## 接口列表

### 一、ZONES (区域管理)

#### 1.1 列出区域 (List Zones)

**接口地址**

```
GET /zones
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码 |
| per_page | integer | 否 | 每页条目数（最大100） |
| name | string | 否 | 按域名筛选 |
| status | string | 否 | 按状态筛选 |
| order | string | 否 | 排序字段 (name/status/account.id/account.name/plan.id) |
| direction | string | 否 | 排序方向 (asc/desc) |
| match | string | 否 | 匹配模式 (any/all) |
| type | array | 否 | 区域类型筛选 (full/partial/secondary/internal) |

**响应示例 (Response)**

```json
{
  "success": true,
  "result": [
    {
      "id": "023e105f4ecef8ad9ca31a8372d0c353",
      "name": "example.com",
      "status": "active",
      "paused": false,
      "type": "full",
      "created_on": "2014-01-01T05:20:00.12345Z",
      "modified_on": "2014-01-01T05:20:00.12345Z",
      "owner": {
        "id": "023e105f4ecef8ad9ca31a8372d0c353",
        "name": "Example Org",
        "type": "organization"
      },
      "plan": {
        "id": "023e105f4ecef8ad9ca31a8372d0c353",
        "name": "Free",
        "price": 0
      }
    }
  ],
  "result_info": {
    "total_count": 1,
    "page": 1,
    "per_page": 20,
    "count": 1,
    "total_pages": 1
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

---

#### 1.2 获取区域详情 (Zone Details)

**接口地址**

```
GET /zones/{zone_id}
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| zone_id | string | 区域 ID (UUID) |

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "id": "023e105f4ecef8ad9ca31a8372d0c353",
    "name": "example.com",
    "status": "active",
    "paused": false,
    "type": "full",
    "created_on": "2014-01-01T05:20:00.12345Z",
    "modified_on": "2014-01-01T05:20:00.12345Z",
    "name_servers": [
      "bob.ns.cloudflare.com",
      "lola.ns.cloudflare.com"
    ],
    "original_name_servers": [
      "ns1.originaldnshost.com",
      "ns2.originaldnshost.com"
    ],
    "original_registrar": "GoDaddy",
    "owner": {
      "id": "023e105f4ecef8ad9ca31a8372d0c353",
      "name": "Example Org",
      "type": "organization"
    },
    "plan": {
      "id": "023e105f4ecef8ad9ca31a8372d0c353",
      "name": "Free",
      "price": 0
    }
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

---

#### 1.3 创建区域 (Create Zone)

**接口地址**

```
POST /zones
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 域名 |
| type | string | 是 | 区域类型 (full/partial/secondary/internal) |
| account | object | 否 | 账户信息 {id: string} |

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "id": "023e105f4ecef8ad9ca31a8372d0c353",
    "name": "example.com",
    "status": "active",
    "paused": false,
    "type": "full",
    "created_on": "2014-01-01T05:20:00.12345Z",
    "modified_on": "2014-01-01T05:20:00.12345Z",
    "name_servers": [
      "bob.ns.cloudflare.com",
      "lola.ns.cloudflare.com"
    ]
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones" \
  -X POST \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"example.com","type":"full"}'
```

---

#### 1.4 删除区域 (Delete Zone)

**接口地址**

```
DELETE /zones/{zone_id}
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| zone_id | string | 区域 ID (UUID) |

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "id": "023e105f4ecef8ad9ca31a8372d0c353"
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353" \
  -X DELETE \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

---

#### 1.5 编辑区域 (Edit Zone)

**接口地址**

```
PATCH /zones/{zone_id}
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| zone_id | string | 区域 ID (UUID) |

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| paused | boolean | 否 | 是否仅使用 DNS 服务 |
| type | string | 否 | 区域类型 (full/partial/secondary/internal) |
| vanity_name_servers | array | 否 | 自定义名称服务器 |

> **注意**: 一次只能修改一个区域属性。

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "id": "023e105f4ecef8ad9ca31a8372d0c353",
    "name": "example.com",
    "status": "active",
    "paused": false,
    "type": "full",
    "modified_on": "2014-01-01T06:30:00.12345Z"
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353" \
  -X PATCH \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"full"}'
```

---

### 二、DNS RECORDS (DNS 记录管理)

#### 2.1 列出 DNS 记录 (List DNS Records)

**接口地址**

```
GET /zones/{zone_id}/dns_records
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| zone_id | string | 区域 ID (UUID) |

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码 |
| per_page | integer | 否 | 每页条目数 |
| name | string | 否 | 按记录名称筛选 |
| type | string | 否 | 按记录类型筛选 (A/AAAA/CNAME/MX/TXT/etc) |
| content | string | 否 | 按内容筛选 |
| order | string | 否 | 排序字段 (type/name/content/ttl/proxied) |
| direction | string | 否 | 排序方向 (asc/desc) |
| match | string | 否 | 匹配模式 (any/all) |
| proxied | boolean | 否 | 按代理状态筛选 |

**响应示例 (Response)**

```json
{
  "success": true,
  "result": [
    {
      "id": "023e105f4ecef8ad9ca31a8372d0c353",
      "name": "example.com",
      "type": "A",
      "content": "198.51.100.4",
      "proxiable": true,
      "proxied": true,
      "ttl": 3600,
      "locked": false,
      "created_on": "2014-01-01T05:20:00.12345Z",
      "modified_on": "2014-01-01T05:20:00.12345Z"
    }
  ],
  "result_info": {
    "total_count": 1,
    "page": 1,
    "per_page": 20,
    "count": 1,
    "total_pages": 1
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

---

#### 2.2 获取 DNS 记录详情 (DNS Record Details)

**接口地址**

```
GET /zones/{zone_id}/dns_records/{dns_record_id}
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| zone_id | string | 区域 ID (UUID) |
| dns_record_id | string | DNS 记录 ID (UUID) |

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "id": "023e105f4ecef8ad9ca31a8372d0c353",
    "name": "example.com",
    "type": "A",
    "content": "198.51.100.4",
    "proxiable": true,
    "proxied": true,
    "ttl": 3600,
    "locked": false,
    "created_on": "2014-01-01T05:20:00.12345Z",
    "modified_on": "2014-01-01T05:20:00.12345Z"
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/dns_records/023e105f4ecef8ad9ca31a8372d0c353" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

---

#### 2.3 创建 DNS 记录 (Create DNS Record)

**接口地址**

```
POST /zones/{zone_id}/dns_records
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| zone_id | string | 区域 ID (UUID) |

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 是 | 记录类型 (A/AAAA/CNAME/MX/TXT/SRV/CAA/etc) |
| name | string | 是 | 记录名称 (Punycode 格式) |
| content | string | 是 | 记录内容/值 |
| ttl | integer | 否 | TTL (1=自动, 60-86400) |
| priority | integer | 否 | 优先级 (MX/SRV) |
| proxied | boolean | 否 | Cloudflare 代理 |
| data | object | 否 | 高级数据 (SRV/CAA 等) |
| comment | string | 否 | 记录备注 |
| tags | array | 否 | 自定义标签 |

> **注意**:
> - A/AAAA 记录不能与 CNAME 记录共存于同一名称
> - NS 记录不能与其他记录类型共存
> - 域名始终以 Punycode 格式存储

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "id": "023e105f4ecef8ad9ca31a8372d0c353",
    "name": "www.example.com",
    "type": "A",
    "content": "198.51.100.4",
    "proxiable": true,
    "proxied": true,
    "ttl": 3600,
    "locked": false,
    "created_on": "2014-01-01T05:20:00.12345Z",
    "modified_on": "2014-01-01T05:20:00.12345Z"
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/dns_records" \
  -X POST \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"A","name":"www.example.com","content":"198.51.100.4","ttl":3600}'
```

---

#### 2.4 更新 DNS 记录 (Update DNS Record)

**接口地址**

```
PUT /zones/{zone_id}/dns_records/{dns_record_id}
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| zone_id | string | 区域 ID (UUID) |
| dns_record_id | string | DNS 记录 ID (UUID) |

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 否 | 记录类型 |
| name | string | 否 | 记录名称 |
| content | string | 否 | 记录内容 |
| ttl | integer | 否 | TTL |
| priority | integer | 否 | 优先级 |
| proxied | boolean | 否 | 代理状态 |
| comment | string | 否 | 备注 |
| tags | array | 否 | 标签 |

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "id": "023e105f4ecef8ad9ca31a8372d0c353",
    "name": "www.example.com",
    "type": "A",
    "content": "198.51.100.5",
    "proxiable": true,
    "proxied": true,
    "ttl": 1800,
    "locked": false,
    "created_on": "2014-01-01T05:20:00.12345Z",
    "modified_on": "2014-01-01T06:30:00.12345Z"
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/dns_records/023e105f4ecef8ad9ca31a8372d0c353" \
  -X PUT \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"198.51.100.5","ttl":1800}'
```

---

#### 2.5 删除 DNS 记录 (Delete DNS Record)

**接口地址**

```
DELETE /zones/{zone_id}/dns_records/{dns_record_id}
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| zone_id | string | 区域 ID (UUID) |
| dns_record_id | string | DNS 记录 ID (UUID) |

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "id": "023e105f4ecef8ad9ca31a8372d0c353"
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/dns_records/023e105f4ecef8ad9ca31a8372d0c353" \
  -X DELETE \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

---

### 三、DNSSEC

#### 3.1 获取 DNSSEC 详情 (DNSSEC Details)

**接口地址**

```
GET /zones/{zone_id}/dnssec
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| zone_id | string | 区域 ID (UUID) |

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "algorithm": "13",
    "digest": "48E939042E82C22542CB377B580DFDC52A361CEFDC72E7F9107E2B6BD9306A45",
    "digest_algorithm": "SHA256",
    "digest_type": "2",
    "dnssec_multi_signer": false,
    "dnssec_presigned": true,
    "dnssec_use_nsec3": false,
    "ds": "example.com. 3600 IN DS 16953 13 2 48E939042E82C22542CB377B580DFDC52A361CEFDC72E7F9107E2B6BD9306A45",
    "flags": 257,
    "key_tag": 42,
    "key_type": "ECDSAP256SHA256",
    "modified_on": "2014-01-01T05:20:00Z",
    "public_key": "oXiGYrSTO+LSCJ3mohc8EP+CzF9KxBj8/ydXJ22pKuZP3VAC3/Md/k7xZfz470CoRyZJ6gV6vml07IC3d8xqhA==",
    "status": "active"
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/dnssec" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

---

### 四、USER (用户信息)

#### 4.1 获取用户信息 (Get User Info)

**接口地址**

```
GET /user
```

**响应示例 (Response)**

```json
{
  "success": true,
  "result": {
    "id": "023e105f4ecef8ad9ca31a8372d0c353",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "username": "johndoe",
    "tier": null,
    "beta": false,
    "two_factor": true
  },
  "errors": [],
  "messages": []
}
```

**cURL 示例**

```bash
curl "https://api.cloudflare.com/client/v4/user" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

---

## 常见错误码

| 错误码 | 说明 |
|--------|------|
| 1000 | 认证错误 |
| 1001 | 资源未找到 |
| 1002 | 验证错误 |
| 1003 | 操作失败 |
| 1004 | 速率限制超出 |
| 1005 | 资源已存在 |
| 7000 | 区域未找到 |
| 7001 | 区域已存在 |
| 7003 | 区域不可用 |

---

## 数据结构参考

### Zone Object (区域对象)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 区域标识符 (UUID) |
| name | string | 域名 |
| status | string | 状态 (initializing/pending/active/moved) |
| paused | boolean | DNS 仅模式 |
| type | string | 类型 (full/partial/secondary/internal) |
| created_on | datetime | 创建时间 |
| modified_on | datetime | 最后修改时间 |
| name_servers | array | Cloudflare 分配的名称服务器 |
| owner | object | 所有者信息 |
| plan | object | 订阅计划 |

### DNS Record Object (DNS 记录对象)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 记录标识符 (UUID) |
| name | string | 记录名称 |
| type | string | 记录类型 |
| content | string | 记录内容 |
| proxiable | boolean | 是否可被代理 |
| proxied | boolean | 当前是否代理 |
| ttl | integer | 生存时间 |
| locked | boolean | 记录是否锁定 |
| created_on | datetime | 创建时间 |
| modified_on | datetime | 最后修改时间 |
| data | object | 高级数据 (SRV/CAA 等) |
| meta | object | Cloudflare 元数据 |
| comment | string | 记录备注 |
| tags | array | 自定义标签 |

### DNSSEC Object

| 字段 | 类型 | 说明 |
|------|------|------|
| status | string | 状态 (active/pending/disabled/pending-disabled/error) |
| algorithm | string | 算法密钥代码 |
| key_type | string | 算法密钥类型 |
| key_tag | number | 密钥标签 |
| public_key | string | 公钥 |
| ds | string | 完整 DS 记录 |
| digest | string | 摘要哈希 |
| digest_algorithm | string | 摘要算法类型 |
| digest_type | string | 摘要算法代码 |
| flags | number | DNSSEC 记录标志 |
| modified_on | datetime | 最后修改时间 |
| dnssec_multi_signer | boolean | 多签名 DNSSEC |
| dnssec_presigned | boolean | 预签名 DNSSEC |
| dnssec_use_nsec3 | boolean | NSEC3 用法 |

---

## TTL 值

| 值 | 说明 |
|----|------|
| 1 | 自动（由提供商管理） |
| 60-86400 | 自定义 TTL（秒） |

> **注意**: Enterprise 区域可使用最低 30 秒的 TTL。

---

## Zone Type Values (区域类型值)

| 类型 | 说明 |
|------|------|
| full | 完整 DNS 托管 |
| partial | CNAME 设置 |
| secondary | 辅助 DNS |
| internal | 内部使用 |

---

## Zone Status Values (区域状态值)

| 状态 | 说明 |
|------|------|
| initializing | 正在设置 |
| pending | 待验证 |
| active | 完全活跃 |
| moved | 已转移到其他账户 |
| deactivated | 已停用 |

---

## DNS 记录类型

| 类型 | 说明 |
|------|------|
| A | IPv4 地址 |
| AAAA | IPv6 地址 |
| CNAME | 规范名称 |
| MX | 邮件交换 |
| TXT | 文本记录 |
| NS | 名称服务器 |
| SRV | 服务定位器 |
| CAA | 认证机构授权 |
| CERT | 证书记录 |
| DNSKEY | DNS 密钥 |
| DS | 委托签名者 |
| HTTPS | HTTPS 记录 |
| LOC | 位置记录 |
| NAPTR | 命名权限指针 |
| OPENPGPKEY | OpenPGP 密钥 |
| PTR | 指针记录 |
| SMIMEA | S/MIME 关联 |
| SSHFP | SSH 指纹 |
| SVCB | 服务绑定 |
| TLSA | TLSA 关联 |
| URI | URI 记录 |

---

## 分页

**请求参数**

| 参数 | 默认值 | 最大值 | 说明 |
|------|--------|--------|------|
| page | 1 | - | 页码 |
| per_page | 20 | 100 | 每页条目数 |

**响应结构**

```json
{
  "result_info": {
    "page": 1,
    "per_page": 20,
    "total_pages": 3,
    "count": 20,
    "total": 45
  }
}
```

---

## 速率限制

| 计划类型 | 限制 | 时间窗口 |
|----------|------|----------|
| 免费 | 1200 requests | 每 5 分钟 |
| Pro | 2500 requests | 每 5 分钟 |
| Enterprise | 6000 requests | 每 5 分钟 |

> **处理方式**: 返回 429 状态码和 `Retry-After` Header（秒为单位）

---

## 字段映射参考

### DNS 记录字段对照表

| 概念 | Cloudflare 字段 |
|------|-----------------|
| 记录 ID | id |
| 名称/标签 | name |
| 类型 | type |
| 内容/目标 | content |
| TTL | ttl |
| 优先级 | priority |
| 代理/CDN | proxied |
| 创建日期 | created_on |
| 更新日期 | modified_on |