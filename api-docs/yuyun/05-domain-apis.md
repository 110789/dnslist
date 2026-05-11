# 雨云 API - 域名接口

## 一、域名列表

### 1.1 列出域名列表 (List Domains)

**接口地址**

```
GET /product/domain/
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| options | string | 是 | 查询选项 (JSON 字符串) |

**options 参数结构**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | integer | 否 | 页码 |
| page_size | integer | 否 | 每页数量 |
| keyword | string | 否 | 搜索关键词 |

**请求头 (Headers)**

| Header | 必填 | 说明 |
|--------|------|------|
| X-Api-Key | 是 | API 密钥 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": [
    {
      "id": "xxx",
      "domain": "example.com",
      "status": "active",
      "create_date": 1704067200,
      "exp_date": 1735689600,
      "auto_renew": true,
      "product": "domain"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 100
  }
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/?options={}" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 二、域名详情

### 2.1 获取域名详情 (Get Domain Details)

**接口地址**

```
GET /product/domain/{id}
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": {
    "id": "xxx",
    "domain": "example.com",
    "status": "active",
    "create_date": 1704067200,
    "exp_date": 1735689600,
    "auto_renew": true,
    "dns_servers": [
      "f1g1ns1.dnspod.net",
      "f1g1ns2.dnspod.net"
    ]
  }
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/xxx" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 三、域名注册

### 3.1 域名注册 (Register Domain)

**接口地址**

```
POST /product/domain/register
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| domain | string | 是 | 要注册的域名 |
| duration | integer | 是 | 注册年限 (1-10) |
| type | string | 是 | 域名类型 (normal/溢价) |
| template_sys_id | string | 否* | 模板 ID |
| new_template_info | object | 否* | 新模板信息 |

*template_sys_id 和 new_template_info 二选一

**模板信息结构 (new_template_info)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 是 | 所有者类型 (I=个人, E=企业) |
| name | string | 是 | 联系人名称 |
| company_name | string | 否 | 企业名称 (type=E 时必填) |
| id_type | string | 是 | 证件类型 |
| id_num | string | 是 | 证件号 |
| email | string | 是 | 邮箱 |
| phone | string | 是 | 电话 |
| country | string | 是 | 国家 |
| province | string | 是 | 省 |
| city | string | 是 | 市 |
| address | string | 是 | 地址 |
| zip_code | string | 是 | 邮编 |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "Domain registered successfully",
  "data": {
    "id": "xxx",
    "domain": "example.com"
  }
}
```

**cURL 示例**

```bash
curl -X POST "https://api.v2.rainyun.com/product/domain/register" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.com",
    "duration": 1,
    "type": "normal",
    "new_template_info": {
      "type": "I",
      "name": "张三",
      "id_type": "SFZ",
      "id_num": "xxxx",
      "email": "test@example.com",
      "phone": "13800138000",
      "country": "中国",
      "province": "广东",
      "city": "深圳",
      "address": "xxx",
      "zip_code": "518000"
    }
  }'
```

---

## 四、域名续费

### 4.1 获取域名续费价格 (Get Renewal Price)

**接口地址**

```
GET /product/domain/{id}/renew-price
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": {
    "price": 29.00,
    "currency": "CNY"
  }
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/xxx/renew-price" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 五、域名模板

### 5.1 查询域名模板列表 (List Templates)

**接口地址**

```
GET /product/domain/template/
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| options | string | 是 | 查询选项 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": [
    {
      "sys_id": "xxx",
      "name": "张三",
      "type": "I",
      "id_type": "SFZ",
      "email": "test@example.com"
    }
  ]
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/template/?options={}" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

### 5.2 获取域名模板详情 (Get Template Details)

**接口地址**

```
GET /product/domain/template/detail/
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| sys_id | string | 是 | 模板标识 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": {
    "sys_id": "xxx",
    "type": "I",
    "name": "张三",
    "company_name": "",
    "id_type": "SFZ",
    "id_num": "xxxx",
    "email": "test@example.com",
    "phone": "13800138000",
    "country": "中国",
    "province": "广东",
    "city": "深圳",
    "address": "xxx",
    "zip_code": "518000"
  }
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/template/detail/?sys_id=xxx" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 六、域名白名单

### 6.1 获取域名白名单列表 (List Whitelist)

**接口地址**

```
GET /product/domain/whitelist
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| options | string | 是 | 查询选项 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": [
    {
      "domain": "example.com",
      "region": "cn-sq1"
    }
  ]
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/whitelist?options={}" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

### 6.2 添加域名白名单 (Add to Whitelist)

**接口地址**

```
POST /product/domain/whitelist
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| domain | string | 是 | 域名 |
| region | string | 是 | 过白区域 |

**region 可选值**

| 值 | 说明 |
|----|------|
| cn-sq1 | 上海 |
| cn-nb1 | 宁波 |
| cn-xy1 | 西安 |
| cn-cq1 | 重庆 |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "Whitelist added successfully"
}
```

**cURL 示例**

```bash
curl -X POST "https://api.v2.rainyun.com/product/domain/whitelist" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.com",
    "region": "cn-sq1"
  }'
```

---

## 七、域名 WHOIS

### 7.1 获取域名 WHOIS 信息 (Get WHOIS)

**接口地址**

```
GET /product/domain/whois
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| domain | string | 是 | 要查询的域名 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": {
    "domain": "example.com",
    "registrar": "xxx",
    "create_date": "2024-01-01",
    "expire_date": "2025-01-01",
    "name_server": [
      "f1g1ns1.dnspod.net",
      "f1g1ns2.dnspod.net"
    ],
    "status": "ok",
    "registrant": {
      "name": "xxx",
      "organization": "xxx"
    }
  }
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/whois?domain=example.com" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 八、免费二级域名

### 8.1 获取可用的免费域名列表 (List Usable Free Domains)

**接口地址**

```
GET /product/domain/free_subdomain/usable
```

**响应示例 (Response)**

```json
{
  "success": true,
  "data": [
    {
      "domain": "rainyun.com",
      "available_count": 100
    }
  ]
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/free_subdomain/usable" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

### 8.2 获取免费二级域名列表 (List Free Subdomains)

**接口地址**

```
GET /product/domain/free_subdomain
```

**请求参数 (Query Parameters)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| options | string | 是 | 查询选项 |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "subdomain": "test",
      "domain": "rainyun.com",
      "full_domain": "test.rainyun.com",
      "status": "active",
      "is_enable": true,
      "create_date": 1704067200
    }
  ]
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/free_subdomain?options={}" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

### 8.3 修改免费二级域名的 CDN 设置 (Update CDN Settings)

**接口地址**

```
POST /product/domain/free_subdomain/proxy
```

**请求参数 (Request Body)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | integer | 是 | 域名 ID |
| is_enable | boolean | 是 | 是否启用 CDN |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "CDN settings updated successfully"
}
```

**cURL 示例**

```bash
curl -X POST "https://api.v2.rainyun.com/product/domain/free_subdomain/proxy" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "is_enable": true
  }'
```

---

## 九、域名证书

### 9.1 下载域名证书 (Download Certificate)

**接口地址**

```
GET /product/domain/{id}/cert
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |

**响应示例 (Response)**

```json
{
  "success": true,
  "data": {
    "cert_content": "-----BEGIN CERTIFICATE-----...",
    "private_key": "-----BEGIN PRIVATE KEY-----..."
  }
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/domain/xxx/cert" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 十、DNSSEC

### 10.1 同步域名 DNSSEC (Sync DNSSEC)

**接口地址**

```
POST /product/domain/{id}/dnssec/sync
```

**路径参数 (Path Parameters)**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 域名产品 ID |

**响应示例 (Response)**

```json
{
  "success": true,
  "message": "DNSSEC sync started"
}
```

**cURL 示例**

```bash
curl -X POST "https://api.v2.rainyun.com/product/domain/xxx/dnssec/sync" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 十一、产品汇总

### 11.1 获取用户产品汇总数据 (Get Product Summary)

**接口地址**

```
GET /product/
```

**响应示例 (Response)**

```json
{
  "success": true,
  "data": [
    {
      "product_type": "rcs",
      "product_id": 123,
      "name": "云服务器",
      "status": "active",
      "exp_date": 1735689600,
      "usage_data": {
        "traffic_used": 100,
        "traffic_total": 500
      }
    }
  ]
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/" \
  -H "X-Api-Key: YOUR_API_KEY"
```