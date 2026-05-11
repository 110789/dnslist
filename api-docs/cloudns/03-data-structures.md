# ClouDNS API - 数据结构

## Zone 对象

### 完整 Zone 信息

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | Zone 唯一标识符 |
| name | string | 域名 |
| user_id | integer | 用户 ID |
| type | string | Zone 类型（master/slave/cloud） |
| status | string | 状态 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |
| expire_at | datetime | 过期时间 |
| serial | integer | 区域 Serial |
| ns | array | 名称服务器列表 |
| custom_ns | array | 自定义 NS |
| is_dnssec | boolean | DNSSEC 状态 |
| is_spam_free | boolean | 免费域名 |

### Zone 列表项

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | Zone ID |
| name | string | 域名 |
| type | string | 类型 |
| status | string | 状态 |
| created_at | string | 创建时间 |

---

## Record 对象

### DNS 记录

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 记录 ID |
| host | string | 主机记录 |
| record | string | 记录值 |
| type | string | 记录类型 |
| ttl | integer | TTL |
| priority | integer | MX 优先级 |
| status | string | 状态 |

### SOA 记录

| 字段 | 类型 | 说明 |
|------|------|------|
| mname | string | 主名称服务器 |
| rname |负责人 | |
| serial | integer | 序列号 |
| refresh | integer | 刷新时间 |
| retry | integer | 重试时间 |
| expire | integer | 过期时间 |
| minimum | integer | 最小 TTL |

---

## 子用户对象

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 子用户 ID |
| username | string | 用户名 |
| status | string | 状态 |
| access_level | string | 访问级别 |
| zones_limit | integer | Zone 配额 |
| records_limit | integer | 记录配额 |
| zones_used | integer | 已用 Zone |
| records_used | integer | 已用记录 |

---

## 账户信息

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 用户 ID |
| username | string | 用户名 |
| email | string | 邮箱 |
| balance | float | 余额 |
| currency | string | 货币 |

---

## 监控检查对象

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 检查 ID |
| host | string | 监控主机 |
| type | string | 监控类型 |
| port | integer | 端口 |
| interval | integer | 检查间隔（秒） |
| status | string | 状态 |
| uptime | float | 可用率 |

---

## 邮件转发对象

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 转发 ID |
| from | string | 源邮箱 |
| to | string | 目标邮箱 |
| enabled | boolean | 是否启用 |

---

## 分页对象

| 字段 | 类型 | 说明 |
|------|------|------|
| page | integer | 当前页码 |
| pages_count | integer | 总页数 |
| total_items | integer | 总条目数 |
| total_pages | integer | 总页数 |

---

## GeoDNS 对象

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 位置 ID |
| code | string | 位置代码 |
| country | string | 国家 |
| city | string | 城市 |

---

## DNSSEC 对象

| 字段 | 类型 | 说明 |
|------|------|------|
| flags | integer | 标志 |
| protocol | integer | 协议 |
| algorithm | integer | 算法 |
| public_key | string | 公钥 |
| DS | string | DS 记录 |

---

## 数据类型定义

### Zone 类型

| 类型 | 说明 |
|------|------|
| master | 主 Zone |
| slave | 从 Zone |
| cloud | 云 Zone |
| free | 免费 Zone |
| parked | 停放 Zone |

### 记录类型

标准记录类型：A, AAAA, CNAME, MX, TXT, SPF, NS, SRV, PTR, DS, CAA, TLSA, CERT, SSHFP, NAPTR, HINFO, LOC, DNAME, SMIMEA, OPENPGPKEY, ALIAS, RP

### 监控类型

| 类型 | 说明 |
|------|------|
| ping | ICMP Ping |
| port | TCP/UDP |
| dns | DNS |
| http | HTTP |
| https | HTTPS |
| heartbeat | 心跳 |

---

## 枚举值

### Zone 状态

| 值 | 说明 |
|-----|------|
| active | 活跃 |
| disabled | 禁用 |
| updated | 已更新 |

### 访问级别

| 值 | 说明 |
|-----|------|
| read | 只读 |
| write | 读写 |

### 返回状态

| 值 | 说明 |
|-----|------|
| Success | 成功 |
| Failed | 失败 |

---

## 注意事项

1. **ID 字段**: Zone 和 Record 都有唯一 ID
2. **时间格式**: 通常为 `YYYY-MM-DD HH:MM:SS`
3. **枚举值**: 必须使用定义的值
4. **嵌套对象**: 部分响应包含嵌套对象