# ClouDNS API - 账户与子用户接口

## 1. 登录验证 (Login)

### 接口地址

```
GET /login/login.json
POST /login/login.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id / sub-auth-user | integer/string | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Login is successful."
}
```

### cURL

```bash
curl "https://api.cloudns.net/login/login.json?auth-id=0&auth-password=password"
```

---

## 2. 获取当前 IP (Get Current IP)

### 接口地址

```
GET /get-current-ip.json
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
  "ip": "203.0.113.1"
}
```

### cURL

```bash
curl "https://api.cloudns.net/get-current-ip.json?auth-id=0&auth-password=password"
```

---

## 3. 获取账户余额 (Get Account Balance)

### 接口地址

```
GET /get-balance.json
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
  "balance": "100.50",
  "currency": "USD"
}
```

### cURL

```bash
curl "https://api.cloudns.net/get-balance.json?auth-id=0&auth-password=password"
```

---

## 4. 列出子用户 (List Sub-Users)

### 接口地址

```
GET /subusers/list.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |

### 响应示例

```json
{
  "status": "Success",
  "subusers": [
    {
      "id": "123",
      "username": "subuser1",
      "status": "active",
      "access_level": "write",
      "zones_limit": "10",
      "records_limit": "100"
    }
  ]
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/list.json?auth-id=0&auth-password=password"
```

---

## 5. 获取子用户信息 (Get Sub-User Info)

### 接口地址

```
GET /subusers/get.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-auth-id | integer | 是 | 子用户 ID |

### 响应示例

```json
{
  "status": "Success",
  "subuser": {
    "id": "123",
    "username": "subuser1",
    "status": "active",
    "zones_used": "2",
    "records_used": "15"
  }
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/get.json?auth-id=0&auth-password=password&sub-auth-id=123"
```

---

## 6. 创建子用户 (Add Sub-User)

### 接口地址

```
GET /subusers/add.json
POST /subusers/add.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-user | string | 是 | 子用户名 |
| password | string | 是 | 密码 |
| zones_limit | integer | 是 | Zone 配额 |
| records_limit | integer | �� | 记录配额 |
| access_level | string | 是 | read/write |

### 响应示例

```json
{
  "status": "Success",
  "subuser_id": "123"
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/add.json?auth-id=0&auth-password=password&sub-user=newuser&password=pass123&zones_limit=5&records_limit=50&access_level=write"
```

---

## 7. 删除子用户 (Delete Sub-User)

### 接口地址

```
GET /subusers/delete.json
POST /subusers/delete.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-auth-id | integer | 是 | 子用户 ID |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Sub-user successfully deleted."
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/delete.json?auth-id=0&auth-password=password&sub-auth-id=123"
```

---

## 8. 修改子用户密码 (Modify Sub-User Password)

### 接口地址

```
GET /subusers/change-password.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-auth-id | integer | 是 | 子用户 ID |
| password | string | 是 | 新密码 |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Password changed successfully."
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/change-password.json?auth-id=0&auth-password=password&sub-auth-id=123&password=newpass"
```

---

## 9. 修改子用户状态 (Modify Sub-User Status)

### 接口地址

```
GET /subusers/change-status.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-auth-id | integer | 是 | 子用户 ID |
| status | string | 是 | active/disabled |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Sub-user status changed successfully."
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/change-status.json?auth-id=0&auth-password=password&sub-auth-id=123&status=active"
```

---

## 10. 委托 Zone (Delegate Zone)

### 接口地址

```
GET /subusers/delegate-zone.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-auth-id | integer | 是 | 子用户 ID |
| domain-name | string | 是 | 域名 |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Zone delegated successfully."
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/delegate-zone.json?auth-id=0&auth-password=password&sub-auth-id=123&domain-name=example.com"
```

---

## 11. 移除 Zone 委托 (Remove Zone Delegation)

### 接口地址

```
GET /subusers/remove-zone-delegation.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-auth-id | integer | 是 | 子用户 ID |
| domain-name | string | 是 | 域名 |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Zone delegation removed successfully."
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/remove-zone-delegation.json?auth-id=0&auth-password=password&sub-auth-id=123&domain-name=example.com"
```

---

## 12. 修��� Zone 配额 (Modify Zones Limit)

### 接口地址

```
GET /subusers/modify-zones-limit.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-auth-id | integer | 是 | 子用户 ID |
| zones_limit | integer | 是 | 新配额 |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Zones limit modified successfully."
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/modify-zones-limit.json?auth-id=0&auth-password=password&sub-auth-id=123&zones_limit=20"
```

---

## 13. 修改记录配额 (Modify Records Limit)

### 接口地址

```
GET /subusers/modify-records-limit.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-auth-id | integer | 是 | 子用户 ID |
| records_limit | integer | 是 | 新配额 |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "Records limit modified successfully."
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/modify-records-limit.json?auth-id=0&auth-password=password&sub-auth-id=123&records_limit=200"
```

---

## 14. 添加子用户 IP (Add IP)

### 接口地址

```
GET /subusers/add-ip.json
POST /subusers/add-ip.json
```

### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是 | API 用户 ID |
| auth-password | string | 是 | 密码 |
| sub-auth-id | integer | 是 | 子用户 ID |
| ip | string | 是 | IP 地址 |

### 响应示例

```json
{
  "status": "Success",
  "statusDescription": "IP successfully added."
}
```

### cURL

```bash
curl "https://api.cloudns.net/subusers/add-ip.json?auth-id=0&auth-password=password&sub-auth-id=123&ip=192.168.1.1"
```

---

## 账户接口汇总

| 接口 | 路径 | 方法 | 说明 |
|------|------|------|------|
| 登录 | /login/login.json | GET/POST | 验证凭证 |
| 当前IP | /get-current-ip.json | GET | 获取客户端IP |
| 余额 | /get-balance.json | GET | 获取账户余额 |
| 列出子用户 | /subusers/list.json | GET | 子用户列表 |
| 子用户信息 | /subusers/get.json | GET | 获取详情 |
| 创建子用户 | /subusers/add.json | GET/POST | 创建 |
| 删除子用户 | /subusers/delete.json | GET/POST | 删除 |
| 修改密码 | /subusers/change-password.json | GET | 修改密码 |
| 修改状态 | /subusers/change-status.json | GET | 修改状态 |
| 委托Zone | /subusers/delegate-zone.json | GET | 委托域名 |
| 移除委托 | /subusers/remove-zone-delegation.json | GET | 移除委托 |
| 修改配额 | /subusers/modify-zones-limit.json | GET | 修改ZOne配额 |
| 记录配额 | /subusers/modify-records-limit.json | GET | 修改记录配额 |
| 添加IP | /subusers/add-ip.json | GET/POST | 添加IP白名单 |