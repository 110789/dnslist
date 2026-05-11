# ClouDNS API - Record 管理接口

## 1. 列出 Records (List Records)

### 接口地址

```
GET /dns/records.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id / sub-auth-user | integer/string | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |
| host | string | 否 | 主机记录筛选 |
| host-like | string | 否 | 主机记录模糊匹配 |
| type | string | 否 | 记录类型筛选 |
| rows-per-page | integer | 否 | 每页条数 |
| page | integer | 否 | 页码 |
| order-by | string | 否 | 排序字段 |
| include-notes | integer | 否 | 0/1 是否包含备注 |

### 响应示例

```json
{
  "status": "Success",
  "records": [
    {
      "id": "12345",
      "host": "www",
      "record": "192.168.1.1",
      "type": "A",
      "ttl": "3600",
      "priority": "0",
      "status": "active"
    }
  ]
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/records.json?auth-id=0&auth-password=password&domain-name=example.com&type=A"
```

---

## 2. 获取单条 Record (Get Record)

### 接口地址

```
GET /dns/get-record.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |
| id | integer | 是 | 记录 ID |

### 响应示例

```json
{
  "status": "Success",
  "record": {
    "id": "12345",
    "host": "www",
    "record": "192.168.1.1",
    "type": "A",
    "ttl": "3600",
    "status": "active"
  }
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/get-record.json?auth-id=0&auth-password=password&domain-name=example.com&id=12345"
```

---

## 3. 添加 Record (Add Record)

### 接口地址

```
GET /dns/add-record.json
POST /dns/add-record.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |
| record-type | string | 是 | 记录类型 |
| host | string | 是 | 主机记录 |
| record | string | 否 | 记录值 |
| ttl | integer | 是 | TTL |
| priority | integer | 否 | MX/SRV 优先级 |
| weight | integer | 否 | SRV weight |
| port | integer | 否 | SRV port |
| geodns-location | integer | 否 | GeoDNS 位置 ID |
| geodns-code | string | 否 | GeoDNS 位置代码 |
| status | integer | 否 | 0/1 状态 |

### 记录类型参数

**A/AAAA**: record（IP）
**CNAME**: record（域名）
**MX**: record, priority
**TXT**: record
**SRV**: record, priority, weight, port
**CAA**: caa_flag, caa_type, caa_value
**TLSA**: tlsa_usage, tlsa_selector, tlsa_matching_type, record

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Record successfully added.",
  "id": "12345"
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/add-record.json?auth-id=0&auth-password=password&domain-name=example.com&record-type=A&host=www&record=192.168.1.1&ttl=3600"
```

---

## 4. 修改 Record (Modify Record)

### 接口地址

```
GET /dns/mod-record.json
POST /dns/mod-record.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |
| id | integer | 是 | 记录 ID |
| host | string | 是 | 主机记录 |
| record | string | 否 | 记录值 |
| ttl | integer | 是 | TTL |
| priority | integer | 否 | MX/SRV 优先级 |
| weight | integer | 否 | SRV weight |
| port | integer | 否 | SRV port |
| geodns-location | integer | 否 | GeoDNS 位置 ID |
| geodns-code | string | 否 | GeoDNS 位置代码 |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Record successfully modified."
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/mod-record.json?auth-id=0&auth-password=password&domain-name=example.com&record-id=12345&host=www&record=192.168.1.2&ttl=3600"
```

---

## 5. 删除 Record (Delete Record)

### 接口地址

```
GET /dns/delete-record.json
POST /dns/delete-record.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |
| id | integer | 是 | 记录 ID |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Record successfully deleted."
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/delete-record.json?auth-id=0&auth-password=password&domain-name=example.com&record-id=12345"
```

---

## 6. 更改 Record 状态 (Change Record Status)

### 接口地址

```
GET /dns/change-record-status.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |
| id | integer | 是 | 记录 ID |
| status | string | 是 | active/disabled |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Record status changed successfully."
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/change-record-status.json?auth-id=0&auth-password=password&domain-name=example.com&record-id=12345&status=disabled"
```

---

## 7. 获取记录分页数 (Get Records Pages Count)

### 接口地址

```
GET /dns/records-pages-count.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |

### 响应示例

```json
{
  "status": "Success",
  "pages_count": "3"
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/records-pages-count.json?auth-id=0&auth-password=password&domain-name=example.com"
```

---

## 8. 获取记录数 (Get Records Count)

### 接口地址

```
GET /dns/records-count.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |

### 响应示例

```json
{
  "status": "Success",
  "records_count": "25"
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/records-count.json?auth-id=0&auth-password=password&domain-name=example.com"
```

---

## 9. 获取可用 TTL (Get Available TTL)

### 接口地址

```
GET /dns/get-available-ttl.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |

### 响应示例

```json
{
  "status": "Success",
  "ttl": ["60", "300", "900", "1800", "3600", "21600", "43200", "86400", "172800", "259200", "604800", "1209600", "2592000"]
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/get-available-ttl.json?auth-id=0&auth-password=password"
```

---

## 10. 获取可用记录类型 (Get Available Record Types)

### 接口地址

```
GET /dns/get-record-types.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |

### 响应示例

```json
{
  "status": "Success",
  "record_types": ["A", "AAAA", "MX", "CNAME", "TXT", "SPF", "NS", "SRV", "PTR"]
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/get-record-types.json?auth-id=0&auth-password=password"
```

---

## 11. 导出 Records (Export Records)

### 接口地址

```
GET /dns/export-records.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |

### 响应示例

```json
{
  "status": "Success",
  "bind": "www.example.com. 3600 IN A 192.168.1.1"
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/export-records.json?auth-id=0&auth-password=password&domain-name=example.com"
```

---

## Record 接口汇总

| 接口 | 路径 | 方法 | 说明 |
|------|------|------|------|
| 列表 | /dns/records.json | GET | 获取记录列表 |
| 获取 | /dns/get-record.json | GET | 获取单条记录 |
| 添加 | /dns/add-record.json | GET/POST | 添加新记录 |
| 修改 | /dns/mod-record.json | GET/POST | 修改记录 |
| 删除 | /dns/delete-record.json | GET/POST | 删除记录 |
| 状态 | /dns/change-record-status.json | GET | 更改状态 |
| 分页数 | /dns/records-pages-count.json | GET | 获取分页数 |
| 记录数 | /dns/records-count.json | GET | 获取记录数 |
| TTL | /dns/get-available-ttl.json | GET | 获取可用 TTL |
| 类型 | /dns/get-record-types.json | GET | 获取记录类型 |
| 导出 | /dns/export-records.json | GET | 导出 BIND 格式 |