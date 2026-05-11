# 雨云 API - 账户接口

## 一、获取用户产品汇总

### 1.1 获取用户产品汇总数据和使用情况 (Get Product Summary)

**接口地址**

```
GET /product/
```

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
      "product_type": "rcs",
      "product_id": 123,
      "name": "云服务器",
      "status": "active",
      "create_date": 1704067200,
      "exp_date": 1735689600,
      "auto_renew": true,
      "usage_data": {
        "traffic_used": 100,
        "traffic_limit": 500,
        "traffic_unit": "GB"
      }
    },
    {
      "product_type": "domain",
      "product_id": 456,
      "name": "example.com",
      "status": "active",
      "create_date": 1704067200,
      "exp_date": 1735689600,
      "auto_renew": true
    },
    {
      "product_type": "rgs",
      "product_id": 789,
      "name": "游戏云",
      "status": "active",
      "create_date": 1704067200,
      "exp_date": 1735689600,
      "auto_renew": true
    }
  ]
}
```

**cURL 示例**

```bash
curl -X GET "https://api.v2.rainyun.com/product/" \
  -H "X-Api-Key: YOUR_API_KEY"
```

---

## 二、产品类型参考

### 产品类型 (product_type)

| 类型 | 说明 |
|------|------|
| rcs | 云服务器 |
| rvh | 虚拟主机 |
| rgs | 游戏云 |
| rbm | 弹性云 |
| domain | 域名 |
| rcdn | CDN |
| ros | 对象存储 |

---

## 三、账户信息字段

### 3.1 产品对象字段

| 字段 | 类型 | 说明 |
|------|------|------|
| product_type | string | 产品类型 |
| product_id | integer | 产品 ID |
| name | string | 产品名称 |
| status | string | 状态 (active/inactive/expired) |
| create_date | integer | 创建时间戳 |
| exp_date | integer | 过期时间戳 |
| auto_renew | boolean | 自动续费 |
| usage_data | object | 使用数据 |

### 3.2 使用数据字段 (usage_data)

| 字段 | 类型 | 说明 |
|------|------|------|
| traffic_used | number | 已用流量 |
| traffic_limit | number | 流量限制 |
| traffic_unit | string | 流量单位 |
| cpu_usage | number | CPU 使用率 |
| memory_usage | number | 内存使用率 |
| disk_usage | number | 磁盘使用率 |

---

## 四、状态值参考

### 4.1 产品状态 (status)

| 状态 | 说明 |
|------|------|
| active | 正常使用 |
| inactive | 已停用 |
| expired | 已过期 |
| pending | 处理中 |

### 4.2 自动续费状态 (auto_renew)

| 值 | 说明 |
|----|------|
| true | 已开启自动续费 |
| false | 未开启自动续费 |

---

## 五、时间戳转换

### 5.1 Unix 时间戳

所有时间字段使用 Unix 时间戳（秒）：

```json
{
  "create_date": 1704067200,
  "exp_date": 1735689600
}
```

### 5.2 转换示例

**JavaScript**
```javascript
const createDate = new Date(create_date * 1000);
// 2024-01-01T00:00:00.000Z

const timestamp = Math.floor(new Date('2025-01-01').getTime() / 1000);
// 1735689600
```

**Python**
```python
from datetime import datetime

create_date = 1704067200
dt = datetime.fromtimestamp(create_date)
# 2024-01-01 00:00:00

timestamp = int(datetime(2025, 1, 1).timestamp())
# 1735689600
```

---

## 六、错误处理

### 6.1 获取产品列表失败

```json
{
  "success": false,
  "error_code": "auth_invalid_credentials",
  "message": "Invalid API key"
}
```

### 6.2 无产品数据

```json
{
  "success": true,
  "data": [],
  "message": "No products found"
}
```

---

## 七、使用场景

### 7.1 获取所有域名产品

```bash
curl -X GET "https://api.v2.rainyun.com/product/" \
  -H "X-Api-Key: YOUR_API_KEY" | jq '.data[] | select(.product_type == "domain")'
```

### 7.2 统计过期域名

```bash
curl -X GET "https://api.v2.rainyun.com/product/" \
  -H "X-Api-Key: YOUR_API_KEY" | jq '[.data[] | select(.product_type == "domain" and .exp_date < now)]'
```

### 7.3 检查未开启自动续费的产品

```bash
curl -X GET "https://api.v2.rainyun.com/product/" \
  -H "X-Api-Key: YOUR_API_KEY" | jq '.data[] | select(.auto_renew == false)'
```