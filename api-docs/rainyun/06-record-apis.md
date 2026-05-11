# 雨云 API - DNS 记录接口

## 一、DNS 记录列表

### 1.1 列出 DNS 记录 (List DNS Records)

**接口地址**

```
GET /product/domain/{id}/dns
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |

**请求头 (Headers)**

| Header | 必填 | 说明 |
|--------|------|------|
| X-Api-Key | 是 | API 密钥 |

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| options | string | 是 | 查询选项 (JSON 字符串) |

**options 参数结构**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码 |
| page_size | integer | 否 | 每页数量 |
| type | string | 否 | 记录类型筛选 |
| line | string | 否 | 线路筛选 |
| keyword | string | 否 | 搜索关键词 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": [
    {
      "record_id": 1,
      "host": "www",
      "type": "A",
      "value": "192.168.1.1",
      "line": "DEFAULT",
      "ttl": 600,
      "level": 1,
      "status": "enabled"
    },
    {
      "record_id": 2,
      "host": "mail",
      "type": "MX",
      "value": "mail.example.com",
      "line": "DEFAULT",
      "ttl": 600,
      "level": 10,
      "status": "enabled"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 50,
    "total": 10
  }
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/xxx/dns?options={}" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 二、添加 DNS 记录

### 2.1 添加域名 DNS 解析 (Create DNS Record)

**接口地址**

```
POST /product/domain/{id}/dns
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |

**请求头 (Headers)**

| Header | 必填 | 说明 |
|--------|------|------|
| X-Api-Key | 是 | API 密钥 |
| Content-Type | 是 | application/json |

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| host | string | 是 | 主机名 |
| type | string | 是 | 解析类型 |
| value | string | 是 | 解析值 |
| line | string | 是 | 解析线路 |
| ttl | integer | 是 | TTL (最小600) |
| level | integer | 否 | 优先等级 |
| rain_product_id | integer | 否 | 关联产品 ID |
| rain_product_type | string | 否 | 关联产品类型 |

**解析类型 (type)**

| 类型 | 说明 | 记录值格式 |
|------|------|------------|
| A | IPv4 地址 | IP 地址 (如 192.168.1.1) |
| AAAA | IPv6 地址 | IPv6 地址 |
| CNAME | 规范名称 | 域名 (如 example.com) |
| MX | 邮件交换 | 域名 + 优先级 |
| TXT | 文本记录 | 任意字符串 |
| SRV | 服务定位器 | 优先级 端口 目标 |

**解析线路 (line)**

| 值 | 说明 |
|----|------|
| DEFAULT | 默认线路 |
| LTEL | 电信线路 |
| LCNC | 联通线路 |
| LMOB | 移动线路 |
| LEDU | 教育网线路 |
| LSEO | 搜索引擎线路 |
| LFOR | 国外线路 |

**TTL 值参考**

| 值 | 说明 |
|----|------|
| 600 | 10 分钟 |
| 1200 | 20 分钟 |
| 1800 | 30 分钟 |
| 3600 | 1 小时 |
| 7200 | 2 小时 |
| 14400 | 4 小时 |
| 86400 | 1 天 |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "DNS record created successfully",
  "data": {
    "record_id": 123,
    "host": "www",
    "type": "A",
    "value": "192.168.1.1",
    "line": "DEFAULT",
    "ttl": 600
  }
}
```

**cURL 示例**

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

**添加 MX 记录示例**

```bash
curl -X POST "https://api.v2.rainyun.com/product/domain/xxx/dns" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "host": "@",
    "type": "MX",
    "value": "mail.example.com",
    "line": "DEFAULT",
    "ttl": 600,
    "level": 10
  }'
```

**添加 CNAME 记录示例**

```bash
curl -X POST "https://api.v2.rainyun.com/product/domain/xxx/dns" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "host": "www",
    "type": "CNAME",
    "value": "example.com",
    "line": "DEFAULT",
    "ttl": 600
  }'
```

**添加 TXT 记录示例**

```bash
curl -X POST "https://api.v2.rainyun.com/product/domain/xxx/dns" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "host": "@",
    "type": "TXT",
    "value": "v=spf1 include:_spf.example.com ~all",
    "line": "DEFAULT",
    "ttl": 600
  }'
```

---

## 三、修改 DNS 记录

### 3.1 修改域名 DNS 解析 (Update DNS Record)

**接口地址**

```
PATCH /product/domain/{id}/dns
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |

**请求头 (Headers)**

| Header | 必填 | 说明 |
|--------|------|------|
| X-Api-Key | 是 | API 密钥 |
| Content-Type | 是 | application/json |

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| record_id | integer | 是 | 记录 ID |
| host | string | 否 | 新主机名 |
| type | string | 否 | 新解析类型 |
| value | string | 否 | 新解析值 |
| line | string | 否 | 新解析线路 |
| ttl | integer | 否 | 新 TTL |
| level | integer | 否 | 新优先等级 |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "DNS record updated successfully",
  "data": {
    "record_id": 123,
    "host": "www",
    "type": "A",
    "value": "192.168.1.2",
    "line": "DEFAULT",
    "ttl": 1200
  }
}
```

**cURL 示例**

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

---

## 四、删除 DNS 记录

### 4.1 删除域名 DNS 解析 (Delete DNS Record)

**接口地址**

```
DELETE /product/domain/{id}/dns
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |

**请求头 (Headers)**

| Header | 必填 | 说明 |
|--------|------|------|
| X-Api-Key | 是 | API 密钥 |
| Content-Type | 是 | application/json |

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| record_id | integer | 是 | 记录 ID |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "DNS record deleted successfully"
}
```

**cURL 示例**

```bash
curl -X DELETE "https://api.v2.rainyun.com/product/domain/xxx/dns" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "record_id": 123
  }'
```

---

## 五、批量操作

### 5.1 批量添加 DNS 记录

通过多次调用 POST 接口实现批量添加：

```bash
# 批量添加 A 记录
for host in www api blog; do
  curl -X POST "https://api.v2.rainyun.com/product/domain/xxx/dns" \
    -H "X-Api-Key: YOUR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"host\":\"$host\",\"type\":\"A\",\"value\":\"192.168.1.1\",\"line\":\"DEFAULT\",\"ttl\":600}"
done
```

### 5.2 批量修改 DNS 记录

通过多次调用 PATCH 接口实现批量修改：

```bash
# 批量修改记录 TTL
curl -X PATCH "https://api.v2.rainyun.com/product/domain/xxx/dns" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"record_id":123,"ttl":3600}'

curl -X PATCH "https://api.v2.rainyun.com/product/domain/xxx/dns" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"record_id":124,"ttl":3600}'
```

---

## 六、注意事项

### 6.1 记录冲突规则

- **A/AAAA 记录**: 不能与 CNAME 记录共存于同一主机名
- **NS 记录**: 不能与其他记录类型共存
- **MX/TXT/SRV**: 可以与其他类型共存

### 6.2 线路规则

- 至少需要有一条 DEFAULT 线路的记录
- 同一主机名+类型可以有多条不同线路的记录

### 6.3 主机名规则

| 主机名 | 说明 |
|--------|------|
| @ | 根域名 (example.com) |
| www | 子域名 (www.example.com) |
| * | 泛解析 (*.example.com) |
| mail | 子域名 (mail.example.com) |

### 6.4 优先级 (level)

- MX 和 SRV 记录使用 level 作为优先级
- 数值越小优先级越高
- 范围: 1-100

---

## 七、错误处理示例

### 7.1 记录已存在

```json
{
  "success": false,
  "error_code": "record_exists",
  "message": "DNS record already exists for this host and type"
}
```

### 7.2 线路无效

```json
{
  "success": false,
  "error_code": "invalid_line",
  "message": "Invalid line value, must be one of: DEFAULT, LTEL, LCNC, LMOB, LEDU, LSEO, LFOR"
}
```

### 7.3 TTL 过小

```json
{
  "success": false,
  "error_code": "invalid_ttl",
  "message": "TTL must be at least 600 seconds"
}
```

### 7.4 缺少默认线路

```json
{
  "success": false,
  "error_code": "missing_default_line",
  "message": "At least one DEFAULT line record is required"
}
```