# DNSPod API v3 - 接入准备

## 服务地址

API 支持就近地域接入，本产品就近地域接入域名为 `dnspod.tencentcloudapi.com`，也支持指定地域域名访问。

**推荐使用就近地域接入域名**，根据调用接口时客户端所在位置，会自动解析到最近的地域服务器。

> 对时延敏感的业务，建议指定带地域的域名。

### 地域域名列表

| 接入地域 | 域名 |
|----------|------|
| **就近地域接入（推荐）** | `dnspod.tencentcloudapi.com` |
| 华南地区（广州） | `dnspod.ap-guangzhou.tencentcloudapi.com` |
| 华东地区（上海） | `dnspod.ap-shanghai.tencentcloudapi.com` |
| 华东地区（南京） | `dnspod.ap-nanjing.tencentcloudapi.com` |
| 华北地区（北京） | `dnspod.ap-beijing.tencentcloudapi.com` |
| 西南地区（成都） | `dnspod.ap-chengdu.tencentcloudapi.com` |
| 西南地区（重庆） | `dnspod.ap-chongqing.tencentcloudapi.com` |
| 港澳台地区（中国香港） | `dnspod.ap-hongkong.tencentcloudapi.com` |
| 亚太东南（新加坡） | `dnspod.ap-singapore.tencentcloudapi.com` |
| 亚太东南（雅加达） | `dnspod.ap-jakarta.tencentcloudapi.com` |
| 亚太东南（曼谷） | `dnspod.ap-bangkok.tencentcloudapi.com` |
| 亚太东北（首尔） | `dnspod.ap-seoul.tencentcloudapi.com` |
| 亚太东北（东京） | `dnspod.ap-tokyo.tencentcloudapi.com` |
| 美国东部（弗吉尼亚） | `dnspod.na-ashburn.tencentcloudapi.com` |
| 美国西部（硅谷） | `dnspod.na-siliconvalley.tencentcloudapi.com` |
| 南美地区（圣保罗） | `dnspod.sa-saopaulo.tencentcloudapi.com` |
| 欧洲地区（法兰克福） | `dnspod.eu-frankfurt.tencentcloudapi.com` |

### 金融区域名

金融区和非金融区隔离不互通，访问金融区服务时需要指定金融区域名：

| 金融区域 | 域名 |
|----------|------|
| 华东地区（上海金融） | `dnspod.ap-shanghai-fsi.tencentcloudapi.com` |
| 华南地区（深圳金融） | `dnspod.ap-shenzhen-fsi.tencentcloudapi.com` |

---

## 通信协议

腾讯云 API 的所有接口均通过 **HTTPS** 进行通信，提供高安全性的通信通道。

---

## 请求方法

支持的 HTTP 请求方法：

| 方法 | 说明 | 请求包大小限制 |
|------|------|----------------|
| **POST（推荐）** | 支持 JSON 格式 | 使用签名 v3 时支持 10MB |
| GET | - | 不得超过 32KB |

### POST 请求 Content-Type

| Content-Type | 签名方法 | 说明 |
|--------------|----------|------|
| `application/json`（推荐） | v3 (TC3-HMAC-SHA256) | 需使用签名方法 v3 |
| `application/x-www-form-urlencoded` | v1 (HmacSHA1/HmacSHA256) | - |
| `multipart/form-data` | v3 (TC3-HMAC-SHA256) | 仅部分接口支持 |

---

## 字符编码

所有请求和响应均使用 **UTF-8** 编码。

---

## 接入准备

### 步骤 1：获取密钥

1. 登录 [腾讯云控制台](https://console.cloud.tencent.com/)
2. 进入 **云 API 密钥** 页面
3. 创建一对密钥，获得：
   - **SecretId**：标识用户身份
   - **SecretKey**：验证签名密钥

> ⚠️ 请严格保管密钥，避免泄露。若已泄露，请立即禁用并重新创建密钥。

### 步骤 2：生成签名

使用获取的 SecretId 和 SecretKey，按照签名方法生成请求签名。

推荐使用 **签名方法 v3 (TC3-HMAC-SHA256)**，更安全且支持更大的请求包。

签名计算流程：
1. 拼接规范请求串
2. 拼接待签名字符串
3. 计算签名
4. 拼接 Authorization

### 步骤 3：发起请求

在 HTTP Header 中携带签名信息：

```
POST / HTTP/1.1
Host: dnspod.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: DescribeDomainList
X-TC-Version: 2021-03-23
X-TC-Timestamp: {timestamp}
X-TC-Region: ap-guangzhou
Authorization: TC3-HMAC-SHA256 Credential={SecretId}/.../...
```

### 步骤 4：处理响应

检查响应中的 `Error` 字段：
- 无 `Error` → 请求成功
- 有 `Error` → 请求失败，查看错误码和错误信息

---

## cURL 请求示例

```bash
curl -X POST https://dnspod.tencentcloudapi.com \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "Host: dnspod.tencentcloudapi.com" \
  -H "X-TC-Action: DescribeUserDetail" \
  -H "X-TC-Version: 2021-03-23" \
  -H "X-TC-Timestamp: 1551113065" \
  -H "X-TC-Region: ap-guangzhou" \
  -H "Authorization: TC3-HMAC-SHA256 Credential=AKID********************************/..." \
  -d '{}'
```

---

## 快速开始代码示例

### Python

```python
from tencentcloud.dnspod.v20210323 import dnspod_client, models

# 初始化客户端
client = dnspod_client.DnspodClient(
    cred=credentials.Credential("SecretId", "SecretKey"),
    region="ap-guangzhou"
)

# 获取账户信息
req = models.DescribeUserDetailRequest()
resp = client.DescribeUserDetail(req)
print(resp.UserInfo)
```

### Go

```go
import "github.com/TencentCloud/tencentcloud-sdk-go/tencentcloud/dnspod/v20210323"

client, _ := dnspod.NewClient(credential, "ap-guangzhou")
req := dnspod.NewDescribeUserDetailRequest()
resp, err := client.DescribeUserDetail(req)
```

---

## SDK 推荐

强烈建议使用腾讯云官方 SDK 进行 API 调用，避免自行实现签名：

| 语言 | SDK 地址 |
|------|----------|
| Python | [tencentcloud-sdk-python](https://github.com/TencentCloud/tencentcloud-sdk-python) |
| Java | [tencentcloud-sdk-java](https://github.com/TencentCloud/tencentcloud-sdk-java) |
| Go | [tencentcloud-sdk-go](https://github.com/TencentCloud/tencentcloud-sdk-go) |
| PHP | [tencentcloud-sdk-php](https://github.com/TencentCloud/tencentcloud-sdk-php) |
| Node.js | [tencentcloud-sdk-nodejs](https://github.com/TencentCloud/tencentcloud-sdk-nodejs) |
| .NET | [tencentcloud-sdk-dotnet](https://github.com/TencentCloud/tencentcloud-sdk-dotnet) |
| C++ | [tencentcloud-sdk-cpp](https://github.com/TencentCloud/tencentcloud-sdk-cpp) |
| Ruby | [tencentcloud-sdk-ruby](https://github.com/TencentCloud/tencentcloud-sdk-ruby) |

---

## 注意事项

1. **时间同步**：请求时间戳与服务器时间相差不能超过 5 分钟，请确保本地时间准确
2. **请求频率**：注意接口频率限制，避免触发限频错误
3. **错误处理**：务必检查响应中的 `Error` 字段，进行适当的错误处理
4. **数据安全**：传输过程全程 HTTPS 加密，保证数据安全