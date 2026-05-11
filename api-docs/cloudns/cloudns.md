# ClouDNS API Documentation

Professional DNS Hosting 服务商 API 参考文档。

## 基本信息

| 项目 | 内容 |
|------|------|
| Base URL | `https://api.cloudns.net` |
| API Version | HTTP API |
| Format | JSON / XML |
| Rate Limit | 20 req/s, 600 req/min, 36000 req/hour |
| 官方文档 | [ClouDNS Wiki](https://www.cloudns.net/wiki/article/41/) |

---

## 目录结构

| 文件 | 内容 |
|------|------|
| [01-getting-started.md](01-getting-started.md) | 接入准备、API 基础信息 |
| [02-common-params.md](02-common-params.md) | 公共参数、响应格式 |
| [03-data-structures.md](03-data-structures.md) | 数据结构定义 |
| [04-error-codes.md](04-error-codes.md) | 错误码归集 |
| [05-zone-apis.md](05-zone-apis.md) | DNS Zone 管理接口 |
| [06-record-apis.md](06-record-apis.md) | DNS Record 管理接口 |
| [07-account-apis.md](07-account-apis.md) | 账户与子用户接口 |
| [08-advanced-apis.md](08-advanced-apis.md) | 高级功能接口 |

---

## 快速开始

### 1. 获取认证凭证

1. 登录 ClouDNS 控制面板
2. 进入 **API & Resellers** > **API Users**
3. 创建新用户，获取 `auth-id` 和 `auth-password`
4. 可选：创建子用户获取 `sub-auth-id` 或 `sub-auth-user`

### 2. 测试连接

```bash
curl "https://api.cloudns.net/login/login.json?auth-id=0&auth-password=password"
```

### 3. 基础调用示例

```bash
# 列出 Zones
curl "https://api.cloudns.net/dns/list-zones.json?auth-id=0&auth-password=password&page=1&rows-per-page=10"

# 列出 DNS Records
curl "https://api.cloudns.net/dns/records.json?auth-id=0&auth-password=password&domain-name=example.com"
```

---

## 核心功能模块

- **DNS Zones**: 域名区域管理（注册/删除/列表/统计）
- **DNS Records**: 解析记录 CRUD（全记录类型支持）
- **Account**: 账户信息、子用户管理
- **DNSSEC**: 安全签名配置
- **Monitoring**: 监控告警
- **Mail Forwards**: 邮件转发

---

## 驱动开发注意事项

1. **认证方式**: 支持 `auth-id` 或 `sub-auth-id/sub-auth-user`
2. **响应格式**: 优先使用 JSON（`.json` 后缀）
3. **分页**: Zones 和 Records 均支持分页（page/rows-per-page）
4. **TTL 值**: 必须是官方支持的值列表
5. **记录类型**: 支持 A/AAAA/MX/CNAME/TXT/SRV/CAA/TLSA 等