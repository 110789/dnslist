# DNSPod API v3 - 公共参数与签名方法

## 公共参数

公共参数是用于标识用户和接口签名的参数，每次请求均需要携带。

### 签名方法 v3 的公共参数

签名方法 v3（TC3-HMAC-SHA256）相比 v1 更安全，支持更大请求包，推荐使用。

公共参数统一放到 HTTP Header 中：

| 参数名称 | 类型 | 必选 | 描述 | Header 字段 |
|----------|------|------|------|-------------|
| Action | String | 是 | 操作接口名称 | X-TC-Action |
| Region | String | - | 地域参数（部分接口不需要） | X-TC-Region |
| Timestamp | Integer | 是 | 当前 UNIX 时间戳 | X-TC-Timestamp |
| Version | String | 是 | API 版本，固定值 `2021-03-23` | X-TC-Version |
| Authorization | String | 是 | 签名认证信息 | Authorization |
| Token | String | 否 | 临时安全凭证 Token | X-TC-Token |
| Language | String | 否 | 返回语言：zh-CN / en-US | X-TC-Language |

### 签名方法 v1 的公共参数

公共参数放到请求串中：

| 参数名称 | 类型 | 必选 | 描述 |
|----------|------|------|------|
| Action | String | 是 | 操作接口名称 |
| Region | String | - | 地域参数 |
| Timestamp | Integer | 是 | 当前 UNIX 时间戳 |
| Nonce | Integer | 是 | 随机正整数，防止重放攻击 |
| SecretId | String | 是 | 密钥 ID |
| Signature | String | 是 | 请求签名 |
| Version | String | 是 | API 版本 |
| SignatureMethod | String | 否 | 签名方式：HmacSHA256 / HmacSHA1 |
| Token | String | 否 | 临时安全凭证 Token |
| Language | String | 否 | 返回语言 |

---

## 签名方法 v3（TC3-HMAC-SHA256）

### 签名流程

#### 1. 拼接规范请求串

```
CanonicalRequest =
    HTTPRequestMethod + '\n' +
    CanonicalURI + '\n' +
    CanonicalQueryString + '\n' +
    CanonicalHeaders + '\n' +
    SignedHeaders + '\n' +
    HashedRequestPayload
```

**字段说明：**

| 字段 | 说明 |
|------|------|
| HTTPRequestMethod | HTTP 请求方法（GET/POST） |
| CanonicalURI | URI，API 3.0 固定为 `/` |
| CanonicalQueryString | 查询字符串，POST 请求固定为空字符串 |
| CanonicalHeaders | 参与签名的头部，至少包含 host 和 content-type |
| SignedHeaders | 参与签名的头部列表，格式为 key;key |
| HashedRequestPayload | 请求正文的 SHA256 哈希值（十六进制小写） |

**CanonicalHeaders 拼接规则：**
1. 头部 key 和 value 统一转成小写，去掉首尾空格
2. 格式为 `key:value\n`
3. 按 key 的 ASCII 升序拼接

**示例：**
```
content-type:application/json; charset=utf-8
host:dnspod.tencentcloudapi.com
x-tc-action:describeuserdetail
```

#### 2. 拼接待签名字符串

```
StringToSign =
    Algorithm + "\n" +
    RequestTimestamp + "\n" +
    CredentialScope + "\n" +
    HashedCanonicalRequest
```

| 字段 | 说明 |
|------|------|
| Algorithm | 固定值 `TC3-HMAC-SHA256` |
| RequestTimestamp | 请求时间戳（X-TC-Timestamp） |
| CredentialScope | 凭证范围，格式：`Date/service/tc3_request` |
| HashedCanonicalRequest | 规范请求串的 SHA256 哈希值 |

**Date 格式**：UTC 标准时间的日期，如 `2019-02-25`

**Service**：产品名，DNSPod 取值为 `dnspod`

#### 3. 计算签名

**计算派生签名密钥：**
```
SecretKey = "YourSecretKey"
SecretDate = HMAC_SHA256("TC3" + SecretKey, Date)
SecretService = HMAC_SHA256(SecretDate, Service)
SecretSigning = HMAC_SHA256(SecretService, "tc3_request")
```

**计算签名值：**
```
Signature = HexEncode(HMAC_SHA256(SecretSigning, StringToSign))
```

#### 4. 拼接 Authorization

```
Authorization =
    Algorithm + ' ' +
    'Credential=' + SecretId + '/' + CredentialScope + ', ' +
    'SignedHeaders=' + SignedHeaders + ', ' +
    'Signature=' + Signature
```

**示例：**
```
TC3-HMAC-SHA256 Credential=AKID********************************/2019-02-25/dnspod/tc3_request, SignedHeaders=content-type;host;x-tc-action, Signature=10b1a37a7301a02ca19a647ad722d5e43b4b3cff309d421d85b46093f6ab6c4f
```

---

## 签名示例

### Python 示例

```python
import hashlib, hmac, json, time
from datetime import datetime

secret_id = "YourSecretId"
secret_key = "YourSecretKey"
service = "dnspod"
host = "dnspod.tencentcloudapi.com"
action = "DescribeUserDetail"
version = "2021-03-23"
region = "ap-guangzhou"
timestamp = int(time.time())
date = datetime.utcfromtimestamp(timestamp).strftime("%Y-%m-%d")

# 1. 拼接规范请求串
http_request_method = "POST"
canonical_uri = "/"
canonical_querystring = ""
ct = "application/json; charset=utf-8"
payload = "{}"
canonical_headers = f"content-type:{ct}\nhost:{host}\nx-tc-action:{action.lower()}\n"
signed_headers = "content-type;host;x-tc-action"
hashed_request_payload = hashlib.sha256(payload.encode("utf-8")).hexdigest()
canonical_request = (http_request_method + "\n" +
                     canonical_uri + "\n" +
                     canonical_querystring + "\n" +
                     canonical_headers + "\n" +
                     signed_headers + "\n" +
                     hashed_request_payload)

# 2. 拼接待签名字符串
credential_scope = f"{date}/{service}/tc3_request"
hashed_canonical_request = hashlib.sha256(canonical_request.encode("utf-8")).hexdigest()
string_to_sign = (f"TC3-HMAC-SHA256\n{timestamp}\n{credential_scope}\n{hashed_canonical_request}")

# 3. 计算签名
def sign(key, msg):
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()
secret_date = sign(("TC3" + secret_key).encode("utf-8"), date)
secret_service = sign(secret_date, service)
secret_signing = sign(secret_service, "tc3_request")
signature = hmac.new(secret_signing, string_to_sign.encode("utf-8"), hashlib.sha256).hexdigest()

# 4. 拼接 Authorization
authorization = (f"TC3-HMAC-SHA256 Credential={secret_id}/{credential_scope}, "
                 f"SignedHeaders={signed_headers}, Signature={signature}")
print(authorization)
```

### Java 示例

```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

public class TencentCloudSign {
    public static byte[] hmac256(byte[] key, String msg) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        SecretKeySpec secretKeySpec = new SecretKeySpec(key, mac.getAlgorithm());
        mac.init(secretKeySpec);
        return mac.doFinal(msg.getBytes(StandardCharsets.UTF_8));
    }

    public static String sha256Hex(String s) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] d = md.digest(s.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder();
        for (byte b : d) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    public static void main(String[] args) throws Exception {
        String secretId = "YourSecretId";
        String secretKey = "YourSecretKey";
        String service = "dnspod";
        long timestamp = System.currentTimeMillis() / 1000;
        String date = "2019-02-25"; // UTC date

        String payload = "{}";
        String hashedPayload = sha256Hex(payload);

        String canonicalRequest = "POST\n/\n\n" +
            "content-type:application/json; charset=utf-8\n" +
            "host:dnspod.tencentcloudapi.com\n" +
            "x-tc-action:describeuserdetail\n\n" +
            "content-type;host;x-tc-action\n" + hashedPayload;

        String credentialScope = date + "/" + service + "/tc3_request";
        String stringToSign = "TC3-HMAC-SHA256\n" + timestamp + "\n" + credentialScope + "\n" +
            sha256Hex(canonicalRequest);

        byte[] secretDate = hmac256(("TC3" + secretKey).getBytes(StandardCharsets.UTF_8), date);
        byte[] secretService = hmac256(secretDate, service);
        byte[] secretSigning = hmac256(secretService, "tc3_request");
        String signature = hmac256(secretSigning, stringToSign).toString();

        String authorization = "TC3-HMAC-SHA256 Credential=" + secretId + "/" + credentialScope +
            ", SignedHeaders=content-type;host;x-tc-action, Signature=" + signature;
        System.out.println(authorization);
    }
}
```

---

## 签名方法 v1（HmacSHA256/HmacSHA1）

### 签名原文字符串拼接

```
SignatureContent = Action + Timestamp + Nonce + SecretId
```

### 计算签名

```
Signature = Base64(HmacSHA256(SecretKey, SignatureContent))
```

### GET 请求签名示例

```
https://dnspod.tencentcloudapi.com/
?Action=DescribeUserDetail
&Version=2021-03-23
&Timestamp=1551113065
&Nonce=23823223
&SecretId=AKID********************************
&Signature=37ac2f4fde00b0ac9bd9eadeb459b1bbee224158d66e7ae5fcadb70b2d181d02
&SignatureMethod=HmacSHA256
```

---

## 常见问题

### Q: 签名过期错误 (SignatureExpire)

**原因**：本地时间与服务器时间相差超过 5 分钟

**解决**：
1. 检查系统时间是否准确
2. 使用 NTP 服务同步时间
3. 确认使用正确的时区

### Q: 签名验证失败 (SignatureFailure)

**原因**：
1. SecretKey 填写错误
2. 签名计算过程有误
3. 请求头与签名计算时不一致

**解决**：
1. 检查 SecretKey 是否正确
2. 使用腾讯云 API Explorer 验证签名
3. 对比实际发送的请求内容与签名计算内容

### Q: 密钥不存在 (SecretIdNotFound)

**原因**：
1. 密钥已被删除或禁用
2. SecretId 填写错误

**解决**：
1. 在控制台检查密钥状态
2. 确认 SecretId 填写正确