# 雨云 API v2 - 综合文档

云服务商 DNS 托管与域名管理 API，支持域名注册、解析、模板管理等完整功能。

## 基本信息

| 项目 | 内容 |
|------|------|
| Base URL | `https://api.v2.rainyun.com` |
| API Version | v2 |
| Format | JSON |
| 官方文档 | [雨云百科](https://www.rainyun.com/docs/rcs/detail/api) |
| API控制台 | [Apifox](https://apifox.com/apidoc/shared-a4595cc8-44c5-4678-a2a3-eed7738dab03) |

---

## 认证方式

所有请求需要在 Header 中传递 API Key：

```http
X-Api-Key: YOUR_API_KEY
```

> **获取 API Key**: 在雨云控制台 > 账号设置 > API密钥 页面创建和管理。

---

## 接口概览

| 模块 | 接口数量 | 说明 |
|------|----------|------|
| 域名管理 | 12 | 域名列表、详情、注册、续费、模板、WHOIS等 |
| DNS解析 | 4 | 记录的增删改查 |
| 账户信息 | 1 | 产品汇总 |
| CDN域名 | - | 参考 RCDN 模块 |

---

## 响应结构

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

## 域名接口一览

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 列出域名列表 | GET | `/product/domain/` | 获取用户所有域名 |
| 获取域名详情 | GET | `/product/domain/{id}` | 获取单个域名详细信息 |
| 域名注册 | POST | `/product/domain/register` | 注册新域名 |
| 获取续费价格 | GET | `/product/domain/{id}/renew-price` | 查询续费费用 |
| 查询模板列表 | GET | `/product/domain/template/` | 获取域名模板列表 |
| 获取模板详情 | GET | `/product/domain/template/detail/` | 获取模板详细信息 |
| 获取白名单列表 | GET | `/product/domain/whitelist` | 获取域名白名单 |
| 添加白名单 | POST | `/product/domain/whitelist` | 添加域名到白名单 |
| 获取WHOIS信息 | GET | `/product/domain/whois` | 查询域名WHOIS |
| 获取可用免费域名 | GET | `/product/domain/free_subdomain/usable` | 获取免费域名列表 |
| 获取免费二级域名 | GET | `/product/domain/free_subdomain` | 获取已创建的免费域名 |
| 修改CDN设置 | POST | `/product/domain/free_subdomain/proxy` | 开关CDN |
| 下载证书 | GET | `/product/domain/{id}/cert` | 下载SSL证书 |
| 同步DNSSEC | POST | `/product/domain/{id}/dnssec/sync` | 同步DNSSEC信息 |

---

## DNS记录接口一览

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 列出DNS记录 | GET | `/product/domain/{id}/dns` | 获取域名所有解析记录 |
| 添加DNS记录 | POST | `/product/domain/{id}/dns` | 添加新解析记录 |
| 修改DNS记录 | PATCH | `/product/domain/{id}/dns` | 修改解析记录 |
| 删除DNS记录 | DELETE | `/product/domain/{id}/dns` | 删除解析记录 |

---

## DNS 记录类型

| 类型 | 说明 | 记录值格式 |
|------|------|------------|
| A | IPv4 地址 | IP 地址 |
| AAAA | IPv6 地址 | IPv6 地址 |
| CNAME | 规范名称 | 域名 |
| MX | 邮件交换 | 域名 + 优先级 |
| TXT | 文本记录 | 任意字符串 |
| SRV | 服务定位器 | 优先级 端口 目标 |

---

## 解析线路

| 值 | 说明 |
|----|------|
| DEFAULT | 默认线路 |
| LTEL | 电信线路 |
| LCNC | 联通线路 |
| LMOB | 移动线路 |
| LEDU | 教育网线路 |
| LSEO | 搜索引擎线路 |
| LFOR | 国外线路 |

---

## TTL 值

| 值 | 说明 |
|----|------|
| 600 | 10 分钟 (最小值) |
| 1200 | 20 分钟 |
| 3600 | 1 小时 |
| 86400 | 1 天 |

---

## 错误码速查

| 错误码 | 说明 |
|--------|------|
| auth_invalid_credentials | API 密钥无效 |
| bad_request | 请求参数无效 |
| not_found | 资源不存在 |
| domain_not_found | 域名未找到 |
| dns_record_not_found | DNS记录未找到 |
| rate_limit_exceeded | 速率限制超出 |
| quota_exceeded | 配额超出 |
| internal_error | 服务器内部错误 |

---

## cURL 调用示例

### 获取域名列表

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/?options={}" \
  -H "X-Api-Key: YOUR_API_KEY"
```

### 添加 DNS 记录

```bash
curl -X POST "https://api.v2.rainyun.com/product/domain/xxx/dns" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "host": "www",
    "type": "A",
    "value": "192.168.1.1",
    "line": "DEFAULT",
    "ttl": 600
  }'
```

### 修改 DNS 记录

```bash
curl -X PATCH "https://api.v2.rainyun.com/product/domain/xxx/dns" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "record_id": 123,
    "value": "192.168.1.2",
    "ttl": 1200
  }'
```

### 删除 DNS 记录

```bash
curl -X DELETE "https://api.v2.rainyun.com/product/domain/xxx/dns" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"record_id": 123}'
```

### 获取产品汇总

```bash
curl -X GET "https://api.v2.rainyun.com/product/" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 字段映射参考

### 域名字段对照

| 概念 | 雨云字段 |
|------|----------|
| 域名 ID | id |
| 域名 | domain |
| 状态 | status |
| 创建时间 | create_date |
| 过期时间 | exp_date |
| 自动续费 | auto_renew |

### DNS 记录字段对照

| 概念 | 雨云字段 |
|------|----------|
| 记录 ID | record_id |
| 主机名 | host |
| 记录类型 | type |
| 记录值 | value |
| 解析线路 | line |
| TTL | ttl |
| 优先级 | level |

---

## 注意事项

1. **HTTPS**: 所有请求必须使用 HTTPS
2. **认证**: API Key 通过 Header 传递
3. **TTL 最小值**: 600 秒
4. **默认线路**: 至少需要一条 DEFAULT 线路记录
5. **记录冲突**: A/AAAA 与 CNAME 不能共存于同一主机名