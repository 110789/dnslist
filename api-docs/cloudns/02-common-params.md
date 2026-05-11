# ClouDNS API - 公共参数与响应格式

## 公共请求参数

### 认证参数

所有接口必须携带以下认证参数之一：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是* | API 用户 ID |
| sub-auth-id | integer | 是* | 子用户 ID |
| sub-auth-user | string | 是* | 子用户名 |
| auth-password | string | 是 | 密码 |

*三选一

### 分页参数

用于需要分页的接口：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 是 | 页码 |
| rows-per-page | integer | 是 | 每页条数（10/20/30/50/100） |

---

## 通用响应结构

### 成功响应

```json
{
  "status": "Success",
  "statusDescription": "Operation description"
}
```

### 记录列表响应

```json
{
  "status": "Success",
  "records": [
    {
      "id": "12345",
      "record": "10.10.10.10",
      "host": "www",
      "type": "A",
      "ttl": "3600"
    }
  ]
}
```

### Zone 列表响应

```json
{
  "status": "Success",
  "zones": [
    {
      "id": "12345",
      "name": "example.com",
      "type": "master",
      "status": "active",
      "created_at": "2024-01-01 12:00:00"
    }
  ],
  "page": "1",
  "pages_count": "5"
}
```

### 失败响应

```json
{
  "status": "Failed",
  "statusDescription": "Error message description"
}
```

---

## 通用字段说明

### Zone 相关字段

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | Zone ID |
| name | string | 域名 |
| type | string | Zone 类型（master/slave/cloud） |
| status | string | 状态（active/disabled） |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

### Record 相关字段

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 记录 ID |
| host | string | 主机记录 |
| type | string | 记录类型 |
| record | string | 记录值 |
| ttl | integer | TTL（秒） |
| priority | integer | MX 优先级 |
| status | string | 状态（active/disabled） |

---

## TTL 值

| 值 | 说明 |
|-----|------|
| 60 | 1 minute |
| 300 | 5 minutes |
| 900 | 15 minutes |
| 1800 | 30 minutes |
| 3600 | 1 hour |
| 21600 | 6 hours |
| 43200 | 12 hours |
| 86400 | 1 day |
| 172800 | 2 days |
| 259200 | 3 days |
| 604800 | 1 week |
| 1209600 | 2 weeks |
| 2592000 | 1 month |

---

## 记录类型

| 类型 | 说明 | 必需参数 |
|------|------|---------|
| A | IPv4 地址 | record（IP） |
| AAAA | IPv6 地址 | record（IPv6） |
| CNAME | 别名记录 | record（域名） |
| MX | 邮件交换 | record（邮件服务器）, priority |
| TXT | 文本记录 | record（文本） |
| SPF | 发件人策略 | record（文本） |
| NS | 名称服务器 | record（域名） |
| SRV | 服务定位器 | record, priority, weight, port |
| PTR | 指针记录 | record（域名） |
| CAA | CA 授权 | caa_flag, caa_type, caa_value |
| TLSA | TLS 关联 | tlsa_usage, tlsa_selector, tlsa_matching_type |
| DS | 委托签名 | key_tag, algorithm, digest_type |
| SRV | 服务记录 | service, protocol, host, priority, weight, port |
| ALIAS | 别名 | record（域名） |
| RP | 负责人 | mail, txt |
| SSHFP | SSH 指纹 | algorithm, fp_type, record |
| NAPTR | 命名授权 | order, pref, flags, params, regexp, replacement |
| HINFO | 主机信息 | cpu, os |
| CAA | CA 授权 | 见 CAA 参数 |
| LOC | 位置记录 | lat_deg, lat_min, lat_sec, lat_dir, long_deg, long_min, long_sec, long_dir |
| DNAME | 别名 | record |
| SMIMEA | S/MIME | smimea_usage, smimea_selector, smimea_matching_type |
| CERT | 证书 | cert_type, cert_key_tag, cert_algorithm, record |
| OPENPGPKEY | OpenPGP | record |

---

## 状态值

### Zone 状态

| 状态 | 说明 |
|------|------|
| active | 正常解析 |
| disabled | 已暂停 |
| updated | 已更新 |

### Record 状态

| 状态 | 说明 |
|------|------|
| active | 正常解析 |
| disabled | 已暂停 |

---

## 通用参数

### 可选筛选参数

| 参数 | 类型 | 说明 |
|------|------|------|
| search | string | 搜索关键词 |
| group-id | integer | 分组 ID |
| type | string | 记录类型筛选 |

---

## 注意事项

1. **必填参数**: 必须在请求中提供
2. **可选参数**: 根据具体接口决定是否提供
3. **参数类型**: 必须是正确的数据类型，否则返回错误
4. **TTL 限制**: 必须使用支持的 TTL 值