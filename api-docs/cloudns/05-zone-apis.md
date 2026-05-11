# ClouDNS API - Zone 管理接口

## 1. 列出 Zones (List Zones)

### 接口地址

```
GET /dns/list-zones.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id / sub-auth-user | integer/string | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| page | integer | 是 | 页码 |
| rows-per-page | integer | 是 | 每页条数 |
| search | string | 否 | 搜索关键词 |
| group-id | integer | 否 | 分组 ID |
| has-cloud-domains | integer | 否 | 1=仅显示有 cloud domains 的 |

### 响应示例

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

### cURL

```bash
curl "https://api.cloudns.net/dns/list-zones.json?auth-id=0&auth-password=password&page=1&rows-per-page=10"
```

---

## 2. 注册 Zone (Register Zone)

### 接口地址

```
GET /dns/register.json
POST /dns/register.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |
| zone-type | string | 否 | master/cloud（默认 master） |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Domain zone successfully registered.",
  "id": "12345"
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/register.json?auth-id=0&auth-password=password&domain-name=example.com"
```

---

## 3. 删除 Zone (Delete Zone)

### 接口地址

```
GET /dns/delete.json
POST /dns/delete.json
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
  "statusDescription": "Domain zone successfully deleted."
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/delete.json?auth-id=0&auth-password=password&domain-name=example.com"
```

---

## 4. 获取 Zone 信息 (Get Zone Information)

### 接口地址

```
GET /dns/get-zone-info.json
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
  "id": "12345",
  "name": "example.com",
  "type": "master",
  "status": "active",
  "created_at": "2024-01-01 12:00:00",
  "serial": "2024010101",
  "ns": ["ns1.cloudns.net", "ns2.cloudns.net"],
  "is_dnssec": false
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/get-zone-info.json?auth-id=0&auth-password=password&domain-name=example.com"
```

---

## 5. 更新 Zone (Update Zone)

### 接口地址

```
GET /dns/update-zone.json
POST /dns/update-zone.json
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
  "statusDescription": "Zone updated successfully."
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/update-zone.json?auth-id=0&auth-password=password&domain-name=example.com"
```

---

## 6. 更改 Zone 状态 (Change Status)

### 接口地址

```
GET /dns/change-status.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| domain-name | string | 是 | 域名 |
| status | string | 是 | active/disabled |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Zone status changed successfully."
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/change-status.json?auth-id=0&auth-password=password&domain-name=example.com&status=active"
```

---

## 7. 获取 Zone 统计 (Get Zones Statistics)

### 接口地址

```
GET /dns/zones-statistics.json
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
  "zones_count": "10",
  "active_zones": "8",
  "disabled_zones": "2"
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/zones-statistics.json?auth-id=0&auth-password=password"
```

---

## 8. 获取分页数 (Get Pages Count)

### 接口地址

```
GET /dns/pages-count.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| rows-per-page | integer | 否 | 每页条数 |

### 响应示例

```json
{
  "status": "Success",
  "pages_count": "5"
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/pages-count.json?auth-id=0&auth-password=password&rows-per-page=10"
```

---

## 9. Zone 是否已更新 (Is Updated)

### 接口地址

```
GET /dns/is-updated.json
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
  "is_updated": "true"
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/is-updated.json?auth-id=0&auth-password=password&domain-name=example.com"
```

---

## 10. 获取可用名称服务器 (Available Name Servers)

### 接口地址

```
GET /dns/available-name-servers.json
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
  "name_servers": [
    "ns1.cloudns.net",
    "ns2.cloudns.net",
    "ns3.cloudns.net"
  ]
}
```

### cURL

```bash
curl "https://api.cloudns.net/dns/available-name-servers.json?auth-id=0&auth-password=password"
```

---

## Zone 接口汇总

| 接口 | 路径 | 方法 | 说明 |
|------|------|------|------|
| 列出 Zones | /dns/list-zones.json | GET | 分页获取 Zone 列表 |
| 注册 Zone | /dns/register.json | GET/POST | 创建新 Zone |
| 删除 Zone | /dns/delete.json | GET/POST | 删除 Zone |
| 获取信息 | /dns/get-zone-info.json | GET | 获取 Zone 详情 |
| 更新 Zone | /dns/update-zone.json | GET/POST | 触发更新 |
| 更改状态 | /dns/change-status.json | GET | 启用/暂停 Zone |
| 统计数据 | /dns/zones-statistics.json | GET | 获取统计 |
| 分页数 | /dns/pages-count.json | GET | 获取分页数 |
| 是否更新 | /dns/is-updated.json | GET | 检查更新状态 |
| 名称服务器 | /dns/available-name-servers.json | GET | 获取 NS 列表 |