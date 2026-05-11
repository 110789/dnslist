# 雨云 API - 公共参数

## 通用请求头

所有 API 请求都需要在 Header 中包含以下参数：

| Header | 类型 | 必填 | 说明 |
|--------|------|------|------|
| X-Api-Key | string | 是 | API 密钥 |
| rain-dev-token | string | 否 | 开发令牌，暂无用途 |

---

## 公共查询参数

### options 参数

用于筛选和分页的 JSON 字符串参数：

```json
{
  "page": 1,
  "page_size": 20,
  "keyword": "example"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码，从1开始 |
| page_size | integer | 否 | 每页数量 |
| keyword | string | 否 | 搜索关键词 |
| status | string | 否 | 状态筛选 |

---

## 路径参数

### 域名 ID (id)

用于指定具体的域名资源：

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |

---

## 产品类型 (rain_product_type)

指定关联的产品类型：

| 值 | 说明 |
|----|------|
| rcs | 云服务器 |
| rvh | 虚拟主机 |
| rgs | 游戏云 |
| rbm | 弹性云 |

---

## 分页参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| page | integer | 1 | 当前页码 |
| page_size | integer | 20 | 每页条目数 |

---

## 公共响应头

| Header | 说明 |
|--------|------|
| X-Request-Id | 请求唯一标识 |
| Content-Type | application/json |

---

## 请求超时

| 配置项 | 默认值 |
|--------|--------|
| 连接超时 | 30 秒 |
| 读取超时 | 30 秒 |

---

## 编码格式

所有请求和响应均使用 **UTF-8** 编码。