# DNSPod API v3 Documentation

腾讯云 DNSPod DNS 解析服务 API 参考文档。

## 文档概述

| 项目 | 内容 |
|------|------|
| Base URL | `https://dnspod.tencentcloudapi.com` |
| API Version | 2021-03-23 |
| Format | JSON |
| Protocol | HTTPS |
| 官方文档 | [DNSPod API 3.0](https://docs.dnspod.cn/api/api3/) |

---

## 文档目录

### 一、接入准备
- [01-getting-started.md](01-getting-started.md) - 服务地址、通信协议、接入准备

### 二、公共参数与签名
- [02-common-params.md](02-common-params.md) - 公共参数、签名方法 v3

### 三、数据结构
- [03-data-structures.md](03-data-structures.md) - 通用数据结构定义

### 四、错误码
- [04-error-codes.md](04-error-codes.md) - 公共错误码与业务错误码

### 五、域名相关接口
- [05-domain-apis.md](05-domain-apis.md) - 域名列表、域名信息、域名操作

### 六、记录相关接口
- [06-record-apis.md](06-record-apis.md) - 记录增删改查、批量操作

### 七、账号与套餐接口
- [07-account-apis.md](07-account-apis.md) - 账户信息、套餐查询

---

## 接口分类概览

| 分类 | 接口数 | 说明 |
|------|--------|------|
| 快照相关 | 12 | 快照创建、回滚、下载 |
| 批量操作相关 | 13 | 批量添加/删除域名、记录 |
| 线路相关 | 10 | 线路列表、自定义线路、分组 |
| 套餐及增值服务 | 11 | 套餐信息、自动续费 |
| 分组相关 | 8 | 域名分组、记录分组 |
| 记录相关 | 14 | 记录 CRUD、动态 DNS |
| 解析量相关 | 3 | 域名解析量统计 |
| 别名相关 | 3 | 域名别名管理 |
| 域名相关 | 20 | 域名增删改查、共享、锁定 |
| 账户相关 | 1 | 账户信息 |

---

## 核心接口速查

### 账户与认证

| 接口 | Action | 说明 |
|------|--------|------|
| 获取账户信息 | DescribeUserDetail | 获取用户账户信息 |

### 域名管理

| 接口 | Action | 说明 |
|------|--------|------|
| 获取域名列表 | DescribeDomainList | 获取用户域名列表 |
| 获取域名信息 | DescribeDomain | 获取单个域名详情 |
| 添加域名 | CreateDomain | 添加新域名 |
| 删除域名 | DeleteDomain | 删除域名 |

### DNS 记录

| 接口 | Action | 说明 |
|------|--------|------|
| 获取解析记录列表 | DescribeRecordList | 获取域名下所有记录 |
| 添加记录 | CreateRecord | 添加新记录 |
| 修改记录 | ModifyRecord | 修改记录 |
| 删除记录 | DeleteRecord | 删除记录 |
| 获取记录信息 | DescribeRecord | 获取单条记录详情 |
| 设置记录状态 | ModifyRecordStatus | 启用/暂停记录 |

### 辅助信息

| 接口 | Action | 说明 |
|------|--------|------|
| 获取等级允许的记录类型 | DescribeRecordType | 获取支持的记录类型 |
| 获取等级允许的线路 | DescribeRecordLineList | 获取支持的解析线路 |

---

## 认证方式

DNSPod API 采用腾讯云统一鉴权体系，使用 SecretId/SecretKey 进行签名认证。

**推荐签名方法**：TC3-HMAC-SHA256（签名方法 v3）

### 获取凭证步骤

1. 登录 [腾讯云控制台](https://console.cloud.tencent.com/)
2. 进入 **云 API 密钥** 页面
3. 创建密钥，获取 `SecretId` 和 `SecretKey`
4. 使用密钥进行签名认证

---

## 响应结构

### 成功响应

```json
{
    "Response": {
        "RequestId": "string",
        "data": { ... }
    }
}
```

### 错误响应

```json
{
    "Response": {
        "Error": {
            "Code": "string",
            "Message": "string"
        },
        "RequestId": "string"
    }
}
```

---

## 频率限制

| 接口类型 | 限制 |
|----------|------|
| 大部分接口 | 20 次/秒 |
| DescribeRecordList | 100 次/秒 |
| DescribeRecord | 200 次/秒 |
| DescribeVASStatistic | 10 次/秒 |

> 注意：频率限制维度为 `API + 接入地域 + 子账号`

---

## SDK 支持

腾讯云提供多语言 SDK 支持：

- [Python SDK](https://github.com/TencentCloud/tencentcloud-sdk-python)
- [Java SDK](https://github.com/TencentCloud/tencentcloud-sdk-java)
- [PHP SDK](https://github.com/TencentCloud/tencentcloud-sdk-php)
- [Go SDK](https://github.com/TencentCloud/tencentcloud-sdk-go)
- [Node.js SDK](https://github.com/TencentCloud/tencentcloud-sdk-nodejs)
- [.NET SDK](https://github.com/TencentCloud/tencentcloud-sdk-dotnet)
- [C++ SDK](https://github.com/TencentCloud/tencentcloud-sdk-cpp)
- [Ruby SDK](https://github.com/TencentCloud/tencentcloud-sdk-ruby)

---

## 注意事项

1. **新添加的解析记录存在短暂的索引延迟**，如果查询不到新增记录，请在 30 秒后重试
2. API 获取的记录总条数会比控制台多 2 条，原因是为防止用户误操作，2021-10-29 14:24:26 后添加的域名在控制台不显示系统 NS 记录
3. **建议使用腾讯云 SDK** 进行接口调用，避免自行实现签名带来的兼容性问题
4. DNSPod 旧版 API 已不再维护，请尽快切换至腾讯云 DNSPod API 3.0