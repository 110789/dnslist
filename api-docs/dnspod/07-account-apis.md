# DNSPod API v3 - 账号与套餐接口

## 概述

账号与套餐相关接口用于获取用户账户信息、套餐信息、增值服务等。

---

## 接口列表

| 接口 | Action | 频率限制 |
|------|--------|----------|
| 获取账户信息 | DescribeUserDetail | 20次/秒 |
| 获取套餐列表 | DescribeDomainVipList | 20次/秒 |
| 获取套餐配置详情 | DescribePackageDetail | 20次/秒 |
| 获取增值服务用量 | DescribeVASStatistic | 10次/秒 |
| DNS 解析套餐自动续费设置 | ModifyPackageAutoRenew | 20次/秒 |
| 套餐绑定、解绑、更换域名 | ModifyPackageDomain | 20次/秒 |
| 增值服务自动续费设置 | ModifyVasAutoRenewStatus | 20次/秒 |
| DNSPod 商品余额支付 | PayOrderWithBalance | 20次/秒 |
| 商品下单 | CreateDeal | 20次/秒 |
| 商品下单并支付 | CreateAndPayDeal | 20次/秒 |
| 获取增值服务列表 | DescribeVasList | 20次/秒 |

---

## 获取账户信息

### DescribeUserDetail

获取当前登录用户的账户信息。

**请求参数**

无。

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| UserInfo | UserInfo | 账户信息 |
| RequestId | String | 请求 ID |

**UserInfo 结构**

| 字段 | 类型 | 说明 |
|------|------|------|
| Id | Integer | 用户 ID |
| UIN | Integer | 腾讯云 UIN |
| Email | String | 邮箱地址 |
| EmailVerified | String | 邮箱是否验证：`yes` / `no` |
| Nick | String | 用户昵称 |
| Status | String | 账户状态：`enabled` / `disabled` |
| Telephone | String | 手机号 |
| TelephoneVerified | String | 手机是否验证：`yes` / `no` |
| RealName | String | 实名认证姓名 |
| WechatBinded | String | 是否绑定微信：`yes` / `no` |
| UserGrade | String | 用户等级，如 `DP_Free` |
| AllowTransferIn | Boolean | 是否允许转入 |
| FreeNs | Array of String | 免费 NS 列表 |

**响应示例**

```json
{
    "Response": {
        "RequestId": "8b7a2ed1-0f04-4cf6-b5b1-b77f91572f34",
        "UserInfo": {
            "AllowTransferIn": false,
            "Email": "qcloud_uin_123456@qcloud.com",
            "EmailVerified": "yes",
            "FreeNs": [
                "v4u4f.dnspod.net",
                "c6b8q.dnspod.net"
            ],
            "Id": 123456,
            "Nick": "",
            "RealName": "",
            "Status": "enabled",
            "Telephone": "",
            "TelephoneVerified": "yes",
            "Uin": 123456,
            "UserGrade": "DP_Free",
            "WechatBinded": "no"
        }
    }
}
```

**cURL 示例**

```bash
curl -X POST https://dnspod.tencentcloudapi.com \
  -H "X-TC-Action: DescribeUserDetail" \
  -H "X-TC-Version: 2021-03-23" \
  -H "X-TC-Timestamp: 1551113065" \
  -H "Content-Type: application/json" \
  -H "Authorization: TC3-HMAC-SHA256 ..." \
  -d '{}'
```

---

## 获取套餐列表

### DescribeDomainVipList

获取用户的套餐列表。

**请求参数**

无。

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| VipList | Array of PackageListItem | 套餐列表 |
| RequestId | String | 请求 ID |

**PackageListItem 结构**

| 字段 | 类型 | 说明 |
|------|------|------|
| Domain | String | 绑定的域名 |
| Type | String | 套餐类型 |
| Value | String | 套餐值 |
| StartTime | String | 开始时间 |
| EndTime | String | 结束时间 |

**响应示例**

```json
{
    "Response": {
        "RequestId": "example-request-id",
        "VipList": [
            {
                "Domain": "example.com",
                "Type": "DP_Ultra",
                "Value": "企业旗舰版",
                "StartTime": "2024-01-01 00:00:00",
                "EndTime": "2025-01-01 00:00:00"
            }
        ]
    }
}
```

---

## 获取套餐配置详情

### DescribePackageDetail

获取各套餐的配置详情。

**请求参数**

无。

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| PackageDetailList | Array of PackageDetailItem | 套餐配置列表 |
| RequestId | String | 请求 ID |

**PackageDetailItem 结构**

| 字段 | 类型 | 说明 |
|------|------|------|
| Name | String | 配置名称 |
| Value | String | 配置值 |

---

## 获取增值服务用量

### DescribeVASStatistic

获取域名增值服务用量。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| VASStatisticList | Array of VASStatisticItem | 增值服务用量列表 |
| RequestId | String | 请求 ID |

**VASStatisticItem 结构**

| 字段 | 类型 | 说明 |
|------|------|------|
| Name | String | 增值服务名称 |
| Count | Integer | 使用量 |
| Unit | String | 单位 |
| Value | String | 配置值 |

---

## DNS 解析套餐自动续费设置

### ModifyPackageAutoRenew

设置 DNS 解析套餐自动续费。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| AutoRenew | Boolean | 是 | 是否自动续费：`true` / `false` |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 套餐绑定、解绑、更换域名

### ModifyPackageDomain

套餐与域名绑定关系操作。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| Type | String | 是 | 操作类型：`bind`（绑定）/`unbind`（解绑）/`upgrade`（升级套餐换绑） |
| PackageType | String | 否 | 套餐类型 |
| ResourceId | String | 否 | 资源 ID |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 增值服务自动续费设置

### ModifyVasAutoRenewStatus

设置增值服务自动续费。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| VasType | String | 是 | 增值服务类型 |
| AutoRenew | Boolean | 是 | 是否自动续费 |
| Renew | Boolean | 否 | 是否立即续费 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## DNSPod 商品余额支付

### PayOrderWithBalance

使用账户余额支付订单。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| DealName | String | 是 | 订单号 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 商品下单

### CreateDeal

创建商品订单（不下单支付）。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| GoodsType | String | 是 | 商品类型 |
| GoodsDetail | String | 是 | 商品详情 |
| GoodsNum | Integer | 否 | 商品数量 |
| Domain | String | 否 | 关联域名 |
| Type | String | 否 | 类型 |
| TimeSpan | Integer | 否 | 时长 |
| AutoRenew | Integer | 否 | 是否自动续费 |
| VipDomain | String | 否 | VIP 域名 |
| PackageType | String | 否 | 套餐类型 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| DealId | String | 订单 ID |
| DealName | String | 订单号 |
| RequestId | String | 请求 ID |

---

## 商品下单并支付

### CreateAndPayDeal

创建商品订单并立即支付。

**请求参数**

与 CreateDeal 参数相同。

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| DealId | String | 订单 ID |
| DealName | String | 订单号 |
| RequestId | String | 请求 ID |

---

## 获取增值服务列表

### DescribeVasList

获取增值服务列表。

**请求参数**

无。

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| VasList | Array of VasListItem | 增值服务列表 |
| RequestId | String | 请求 ID |

**VasListItem 结构**

| 字段 | 类型 | 说明 |
|------|------|------|
| Name | String | 服务名称 |
| Status | String | 服务状态 |
| Value | String | 配置值 |
| StartTime | String | 开始时间 |
| EndTime | String | 结束时间 |

---

## 套餐等级说明

### 旧套餐

| 等级代码 | 说明 | 说明 |
|----------|------|------|
| D_Free | 免费版 | 基础 DNS 解析 |
| D_Plus | 个人豪华版 | 更多记录额度 |
| D_Extra | 企业 I 版 | 企业级功能 |
| D_Expert | 企业 II 版 | 高级功能 |
| D_Ultra | 企业 III 版 | 全部功能 |

### 新套餐

| 等级代码 | 说明 |
|----------|------|
| DP_Free | 新免费版 |
| DP_Plus | 个人专业版 |
| DP_Extra | 企业创业版 |
| DP_Expert | 企业标准版 |
| DP_Ultra | 企业旗舰版 |

---

## 常见错误码

| 错误码 | 说明 |
|--------|------|
| FailedOperation.InsufficientBalance | 账户余额不足 |
| FailedOperation.OrderCanNotPay | 不能付款此订单 |
| FailedOperation.OrderHasPaid | 订单已经付过款 |
| InvalidParameter.GoodsTypeInvalid | 商品类型无效 |
| InvalidParameter.GoodsNumInvalid | 商品数量无效 |
| InvalidParameter.TimeSpanInvalid | 时长无效 |
| ResourcesSoldOut | 资源售罄 |