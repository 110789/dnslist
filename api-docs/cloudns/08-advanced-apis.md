# ClouDNS API - 高级功能接口

## 1. SOA 记录

### 获取 SOA 详情 (Get SOA Details)

```
GET /dns/get-soa.json
```

**参数**: auth-id, auth-password, domain-name

**响应**:
```json
{
  "status": "Success",
  "mname": "ns1.cloudns.net",
  "rname": "admin.cloudns.net",
  "serial": "2024010101",
  "refresh": "3600",
  "retry": "1800",
  "expire": "604800",
  "minimum": "3600"
}
```

### 修改 SOA (Modify SOA Details)

```
GET /dns/mod-soa.json
```

**参数**: auth-id, auth-password, domain-name, mname, rname, serial, refresh, retry, expire, minimum

---

## 2. DNSSEC

### 检查 DNSSEC 可用性 (Is DNSSEC Available)

```
GET /dnssec/is-available.json
```

**参数**: auth-id, auth-password, domain-name

### 激活 DNSSEC (Activate DNSSEC)

```
GET /dnssec/activate.json
```

**参数**: auth-id, auth-password, domain-name

### 关闭 DNSSEC (Deactivate DNSSEC)

```
GET /dnssec/deactivate.json
```

**参数**: auth-id, auth-password, domain-name

### 获取 DS 记录 (Get DS Records)

```
GET /dnssec/get-ds-records.json
```

**参数**: auth-id, auth-password, domain-name

**响应**:
```json
{
  "status": "Success",
  "ds_records": [
    {
      "key_tag": "12345",
      "algorithm": "13",
      "digest_type": "2",
      "digest": "ABCDEF..."
    }
  ]
}
```

---

## 3. 邮件转发

### 列出邮件转发 (List Mail Forwards)

```
GET /mail/list.json
```

**参数**: auth-id, auth-password, domain-name

### 添加邮件转发 (Add Mail Forward)

```
GET /mail/add.json
```

**参数**: auth-id, auth-password, domain-name, from, to

### 删除邮件转发 (Delete Mail Forward)

```
GET /mail/delete.json
```

**参数**: auth-id, auth-password, domain-name, id

### 修改邮件转发 (Modify Mail Forward)

```
GET /mail/mod.json
```

**参数**: auth-id, auth-password, domain-name, id, from, to

---

## 4. 监控 (Monitoring)

### 创建监控检查 (Create Monitoring Check)

```
GET /monitoring/create.json
POST /monitoring/create.json
```

**参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id / sub-auth-id | integer | 是 | 认证参数 |
| auth-password | string | 是 | 密码 |
| host | string | 是 | 监控主机 |
| type | string | 是 | 监控类型 |
| port | integer | 是 | 端口 |
| interval | integer | 是 | 间隔（秒） |

监控类型: ping, port, dns, http, https, heartbeat, smtp, pop3, imap

### 列出监控检查 (List Monitoring Checks)

```
GET /monitoring/list.json
```

**参数**: auth-id, auth-password

### 更新监控检查 (Update Monitoring Check)

```
GET /monitoring/update.json
```

**参数**: auth-id, auth-password, id, host, type, port, interval

### 删除监控检查 (Delete Monitoring Check)

```
GET /monitoring/delete.json
```

**参数**: auth-id, auth-password, id

### 获取监控历史 (Get Monitoring History)

```
GET /monitoring/get-history.json
```

**参数**: auth-id, auth-password, id

### 获取监控检查 (Get Monitoring Check)

```
GET /monitoring/get.json
```

**参数**: auth-id, auth-password, id

---

## 5. DNS Failover

### 获取 Failover 设置 (Get Failover Settings)

```
GET /failover/get.json
```

**参数**: auth-id, auth-password, domain-name, host, type

### 激活 Failover (Activate Failover)

```
GET /failover/activate.json
```

**参数**: auth-id, auth-password, domain-name, host, type, failback_enabled, ips

### 关闭 Failover (Deactivate Failover)

```
GET /failover/deactivate.json
```

**参数**: auth-id, auth-password, domain-name, host, type

### 修改 Failover (Modify Failover)

```
GET /failover/modify.json
```

**参数**: auth-id, auth-password, domain-name, host, type, ips

---

## 6. GeoDNS

### 列出 GeoDNS 位置 (List GeoDNS Locations)

```
GET /geodns/list-locations.json
```

**参数**: auth-id, auth-password

### GeoDNS 可用性检查 (Is GeoDNS Available)

```
GET /geodns/is-available.json
```

**参数**: auth-id, auth-password, domain-name

---

## 7. 分组管理

### 列出分组 (List Groups)

```
GET /groups/list.json
```

**参数**: auth-id, auth-password

### 创建分组 (Add Group)

```
GET /groups/add.json
```

**参数**: auth-id, auth-password, name

### 删除分组 (Delete Group)

```
GET /groups/delete.json
```

**参数**: auth-id, auth-password, id

### 重命名分组 (Rename Group)

```
GET /groups/rename.json
```

**参数**: auth-id, auth-password, id, name

### 修改分组 (Change Group)

```
GET /groups/change.json
```

**参数**: auth-id, auth-password, domain-name, group_id

---

## 8. Zone Transfer

### 允许新 IP (Allow New IP)

```
GET /transfer/allow-ip.json
```

**参数**: auth-id, auth-password, domain-name, ip

### 删除允许的 IP (Delete Allowed IP)

```
GET /transfer/delete-ip.json
```

**参数**: auth-id, auth-password, domain-name, ip

### 列出允许的 IPs (List Allowed IPs)

```
GET /transfer/list-ips.json
```

**参数**: auth-id, auth-password, domain-name

---

## 9. Cloud Domains

### 添加 Cloud Domain

```
GET /cloud/add.json
```

**参数**: auth-id, auth-password, domain-name, master

### 删除 Cloud Domain

```
GET /cloud/delete.json
```

**参数**: auth-id, auth-password, domain-name

### 列出 Cloud Domains

```
GET /cloud/list.json
```

**参数**: auth-id, auth-password

### 修改 Cloud Master

```
GET /cloud/change-master.json
```

**参数**: auth-id, auth-password, domain-name, master

---

## 10. Import/Export

### 导入记录 (Import Records)

```
GET /dns/import-records.json
POST /dns/import-records.json
```

**参数**: auth-id, auth-password, domain-name, records

### 导出为 BIND 格式 (Export in BIND Format)

```
GET /dns/export-bind.json
```

**参数**: auth-id, auth-password, domain-name

---

## 高级接口汇总

| 模块 | 接口 |
|------|------|
| SOA | get-soa, mod-soa, reset-soa |
| DNSSEC | is-available, activate, deactivate, get-ds-records |
| Mail Forwards | list, add, delete, mod |
| Monitoring | create, list, update, delete, get-history |
| DNS Failover | get, activate, deactivate, modify |
| GeoDNS | list-locations, is-available |
| Groups | list, add, delete, rename, change |
| Zone Transfer | allow-ip, delete-ip, list-ips |
| Cloud Domains | add, delete, list, change-master |
| Import/Export | import-records, export-bind |