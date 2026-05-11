# 雨云 API - 接入准备

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

### API 密钥认证

所有请求需要在 Header 中传递 API Key：

```http
X-Api-Key: YOUR_API_KEY
```

> **获取 API Key**: 在雨云控制台 > 账号设置 > API密钥 页面创建和管理。

---

## 请求头

| Header | 必填 | 说明 |
|--------|------|------|
| X-Api-Key | 是 | API 密钥 |
| Content-Type | 否 | 请求内容类型，默认 application/json |
| rain-dev-token | 否 | 开发令牌，暂无用途，无需传入 |

---

## 通信协议

所有接口均通过 **HTTPS** 进行通信，提供高安全性的通信通道。

---

## 请求方法

支持 **GET** 和 **POST** 两种方式：

| 方法 | 说明 | 适用场景 |
|------|------|----------|
| GET | 查询操作 | 获取域名列表、获取DNS记录等 |
| POST | 创建/修改操作 | 添加DNS记录、修改解析等 |
| PATCH | 部分更新 | 修改DNS记录 |
| DELETE | 删除操作 | 删除DNS记录 |

---

## 速率限制

| 限制类型 | 阈值 |
|----------|------|
| 请求频率 | 请参考官方文档具体接口限制 |

> **处理方式**: 返回相应错误码，建议降低请求频率重试。

---

## 接入准备

### 步骤 1：获取 API 密钥

1. 登录 [雨云控制台](https://app.rainyun.com)
2. 进入 **账号设置** > **API密钥**
3. 点击创建新的 API 密钥
4. 保存生成的密钥

> ⚠️ 请严格保管 API 密钥，避免泄露。若已泄露，请立即禁用并重新创建密钥。

### 步骤 2：发起请求

在 HTTP Header 中携带 API Key：

```http
GET /product/domain/ HTTP/1.1
Host: api.v2.rainyun.com
X-Api-Key: YOUR_API_KEY
```

### 步骤 3：处理响应

检查响应中的状态字段：
- `success: true` → 请求成功
- `success: false` → 请求失败，查看错误信息

---

## cURL 请求示例

### 获取域名列表

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/?options={}" \
  -H "X-Api-Key: YOUR_API_KEY"
```

### 添加 DNS 解析

```bash
curl -X POST "https://api.v2.rainyun.com/product/domain/{id}/dns" \
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

---

## 注意事项

1. **HTTPS**: 所有请求必须使用 HTTPS
2. **认证**: API Key 通过 Header 传递，请勿在 URL 中暴露
3. **时间同步**: 确保请求时间戳准确
4. **错误处理**: 务必检查响应状态，进行适当的错误处理
5. **数据安全**: 传输过程全程 HTTPS 加密，保证数据安全