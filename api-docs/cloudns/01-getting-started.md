# ClouDNS API - 接入准备

## 基本信息

### 服务地址

| 项目 | 地址 |
|------|------|
| API Base URL | `https://api.cloudns.net` |
| 协议 | HTTPS（强制）|

### 速率限制

| 限制类型 | 阈值 |
|----------|------|
| 每秒 | 20 requests |
| 每分钟 | 600 requests |
| 每小时 | 36000 requests |

如需更高限制，请联系技术支持。

---

## 认证方式

### 认证参数

所有请求需要以下认证参数之一：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auth-id | integer | 是* | API 用户 ID |
| sub-auth-id | integer | 是* | API 子用户 ID |
| sub-auth-user | string | 是* | 子用户名 |
| auth-password | string | 是 | 密码 |

*三选一：auth-id 或 sub-auth-id 或 sub-auth-user

### 获取 API 凭证

1. 登录 ClouDNS 控制面板
2. 进入 **API & Resellers** > **API Users**
3. 点击 **Add new user**
4. 设置密码和 IP 白名单（可选）
5. 保存后获取 `auth-id`

### 子用户创建

1. 进入 **API & Resellers** > **API Sub-Users**
2. 点击 **Add new sub-user**
3. 配置：
   - sub-auth-user（可选用户名）
   - auth-password
   - DNS zones 数量限制
   - DNS records 数量限制
   - Access level（Read/Write）
4. 保存后获取 `sub-auth-id`

---

## 请求格式

### HTTP 方法

支持 GET 和 POST 两种方式：

```bash
# GET 方式
GET https://api.cloudns.net/dns/list-zones.json?auth-id=0&auth-password=password&page=1

# POST 方式
POST https://api.cloudns.net/dns/list-zones.json
Body: auth-id=0&auth-password=password&page=1
```

### 响应格式

通过 URL 后缀指定：

| 格式 | 后缀 | 示例 |
|------|------|------|
| JSON | .json | `https://api.cloudns.net/login/login.json` |
| XML | .xml | `https://api.cloudns.net/login/login.xml` |

推荐使用 JSON 格式。

---

## 接口路径

| 模块 | 接口路径 |
|------|---------|
| 登录 | `/login/login` |
| DNS Zone | `/dns/` |
| DNS Records | `/dns/` |
| 子用户 | `/subusers/` |
| 监控 | `/monitoring/` |
| SSL | `/ssl/` |

---

## 快速测试

### 测试登录

```bash
curl "https://api.cloudns.net/login/login.json?auth-id=0&auth-password=password"
```

成功响应：
```json
{
  "status": "Success",
  "statusDescription": "Login is successful."
}
```

失败响应：
```json
{
  "status": "Failed",
  "statusDescription": "Invalid authentication, incorrect auth-id or auth-password."
}
```

### 获取当前 IP

```bash
curl "https://api.cloudns.net/get-current-ip.json?auth-id=0&auth-password=password"
```

### 获取账户余额

```bash
curl "https://api.cloudns.net/get-balance.json?auth-id=0&auth-password=password"
```

---

## 数据类型

| 类型 | 说明 | 示例 |
|------|------|------|
| Integer | 整数 | `12345` |
| String | 字符串 | `example.com` |
| Boolean | true/false | `true` |
| Array | 数组 | `domain[]=a.com&domain[]=b.com` |

---

## 基础接入流程

1. 创建 API 用户获取凭证
2. 调用 login 接口验证凭证
3. 调用 list-zones 获取域名列表
4. 调用 records 接口管理解析记录

---

## 注意事项

1. **安全**: 所有请求必须使用 HTTPS
2. **IP 限制**: 可在控制面板设置 IP 白名单
3. **子用户**: 权限受限，推荐用于受限访问场景
4. **频率**: 遵守速率限制，避免被封禁