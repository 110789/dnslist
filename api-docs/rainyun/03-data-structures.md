# 雨云 API - 数据结构

## 通用响应结构

### 成功响应

```json
{
  "success": true,
  "data": { ... },
  "message": "操作成功"
}
```

### 错误响应

```json
{
  "success": false,
  "error_code": "ERROR_CODE",
  "message": "错误描述信息",
  "details": {}
}
```

---

## 域名对象 (Domain)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |
| domain | string | 域名 |
| status | string | 状态 |
| create_date | integer | 创建时间戳 |
| exp_date | integer | 过期时间戳 |
| auto_renew | boolean | 自动续费 |
| renew_notice | integer | 续费通知 |
| product | string | 产品类型 |

---

## DNS 记录对象 (DNSRecord)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| host | string | 是 | 主机名 |
| type | string | 是 | 解析类型 |
| value | string | 是 | 解析值 |
| line | string | 是 | 解析线路 |
| ttl | integer | 是 | TTL |
| level | integer | 否 | 优先等级 |
| record_id | integer | 否 | 记录 ID |
| rain_product_id | integer | 否 | 关联产品 ID |
| rain_product_type | string | 否 | 关联产品类型 |

### DNS 记录类型 (type)

| 类型 | 说明 |
|------|------|
| A | IPv4 地址 |
| AAAA | IPv6 地址 |
| CNAME | 规范名称 |
| MX | 邮件交换 |
| TXT | 文本记录 |
| SRV | 服务定位器 |

### 解析线路 (line)

| 值 | 说明 |
|----|------|
| DEFAULT | 默认线路 |
| LTEL | 电信线路 |
| LCNC | 联通线路 |
| LMOB | 移动线路 |
| LEDU | 教育网线路 |
| LSEO | 搜索引擎线路 |
| LFOR | 国外线路 |

### TTL 值

| 值 | 说明 |
|----|------|
| 600 | 10 分钟 |
| 1200 | 20 分钟 |
| 3600 | 1 小时 |
| 86400 | 1 天 |

> **注意**: TTL 最小值为 600 秒

---

## 域名模板对象 (Template)

| 字段 | 类型 | 说明 |
|------|------|------|
| sys_id | string | 模板标识 |
| name | string | 联系人名称 |
| type | string | 所有者类型 (I=个人, E=企业) |
| company_name | string | 企业名称 |
| id_type | string | 证件类型 |
| id_num | string | 证件号 |
| email | string | 邮箱 |
| phone | string | 电话 |
| country | string | 国家 |
| province | string | 省 |
| city | string | 市 |
| address | string | 地址 |
| zip_code | string | 邮编 |

---

## WHOIS 信息对象 (Whois)

| 字段 | 类型 | 说明 |
|------|------|------|
| domain | string | 域名 |
| registrar | string | 注册商 |
| create_date | string | 创建日期 |
| expire_date | string | 过期日期 |
| name_server | array | 名称服务器 |
| status | string | 域名状态 |
| registrant | object | 注册人信息 |

---

## 白名单对象 (Whitelist)

| 字段 | 类型 | 说明 |
|------|------|------|
| domain | string | 域名 |
| region | string | 过白区域 |

### 过白区域 (region)

| 值 | 说明 |
|----|------|
| cn-sq1 | 上海 |
| cn-nb1 | 宁波 |
| cn-xy1 | 西安 |
| cn-cq1 | 重庆 |

---

## 免费二级域名对象 (FreeSubdomain)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 域名 ID |
| subdomain | string | 子域名 |
| domain | string | 根域名 |
| full_domain | string | 完整域名 |
| status | string | 状态 |
| is_enable | boolean | CDN 状态 |
| create_date | integer | 创建时间 |

---

## 产品汇总对象 (ProductSummary)

| 字段 | 类型 | 说明 |
|------|------|------|
| product_type | string | 产品类型 |
| product_id | integer | 产品 ID |
| name | string | 产品名称 |
| status | string | 状态 |
| usage_data | object | 使用数据 |
| exp_date | integer | 过期时间 |

---

## 错误响应字段

| 字段 | 类型 | 说明 |
|------|------|------|
| success | boolean | 是否成功 |
| error_code | string | 错误码 |
| message | string | 错误信息 |
| details | object | 详细错误信息 |
| request_id | string | 请求 ID |

---

## 数据类型

| 类型 | 说明 | 示例 |
|------|------|------|
| string | 字符串 | `"example.com"` |
| integer | 整数 | `123` |
| boolean | 布尔值 | `true` / `false` |
| array | 数组 | `["item1", "item2"]` |
| object | 对象 | `{"key": "value"}` |

---

## 时间戳格式

所有时间字段使用 Unix 时间戳（秒）：

```json
{
  "create_date": 1704067200,
  "exp_date": 1735689600
}
```

转换示例：
- Unix 时间戳 → 日期：`new Date(1704067200 * 1000)`
- 日期 → Unix 时间戳：`Math.floor(new Date().getTime() / 1000)`