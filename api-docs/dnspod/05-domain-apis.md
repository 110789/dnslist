# DNSPod API v3 - 域名相关接口

## 概述

域名相关接口用于管理用户的域名，包括域名列表获取、域名详情查询、域名添加删除、域名分组管理等操作。

---

## 接口列表

| 接口 | Action | 频率限制 |
|------|--------|----------|
| 获取域名列表 | DescribeDomainList | 20次/秒 |
| 获取域名信息 | DescribeDomain | 20次/秒 |
| 添加域名 | CreateDomain | 20次/秒 |
| 删除域名 | DeleteDomain | 20次/秒 |
| 获取域名筛选列表 | DescribeDomainFilterList | 20次/秒 |
| 设置域名备注 | ModifyDomainRemark | 20次/秒 |
| 修改域名状态 | ModifyDomainStatus | 20次/秒 |
| 获取域名共享信息 | DescribeDomainShareInfo | 20次/秒 |
| 删除域名共享 | DeleteShareDomain | 20次/秒 |
| 获取域名日志 | DescribeDomainLogList | 20次/秒 |
| 锁定域名 | ModifyDomainLock | 20次/秒 |
| 解锁域名 | ModifyDomainUnlock | 20次/秒 |
| 域名过户 | ModifyDomainOwner | 20次/秒 |
| 获取域名权限 | DescribeDomainPurview | 20次/秒 |
| 获取域名 Whois 信息 | DescribeDomainWhois | 20次/秒 |
| 获取域名概览信息 | DescribeDomainPreview | 20次/秒 |
| 暂停子域名解析记录 | ModifySubdomainStatus | 20次/秒 |
| 获取域名别名列表 | DescribeDomainAliasList | 20次/秒 |
| 创建域名别名 | CreateDomainAlias | 20次/秒 |
| 删除域名别名 | DeleteDomainAlias | 20次/秒 |

---

## 获取域名列表

### DescribeDomainList

获取用户的域名列表。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Type | String | 否 | 域名分组类型：`ALL`(默认)/`MINE`/`SHARE`/`ISMARK`/`PAUSE`/`VIP`/`RECENT`/`SHARE_OUT`/`FREE` |
| Offset | Integer | 否 | 记录偏移量，第一条为 0，默认 0 |
| Limit | Integer | 否 | 获取域名数量，默认 3000 |
| GroupId | Integer | 否 | 分组 ID |
| Keyword | String | 否 | 搜索关键字 |
| Tags.N | Array of TagItemFilter | 否 | 标签过滤 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| DomainCountInfo | DomainCountInfo | 列表统计信息 |
| DomainList | Array of DomainListItem | 域名列表 |
| RequestId | String | 请求 ID |

**响应示例**

```json
{
    "Response": {
        "DomainCountInfo": {
            "AllTotal": 35,
            "DomainTotal": 1,
            "ErrorTotal": 28,
            "LockTotal": 1,
            "MineTotal": 28,
            "PauseTotal": 1,
            "ShareOutTotal": 4,
            "ShareTotal": 7,
            "SpamTotal": 0,
            "VipExpire": 0,
            "VipTotal": 4
        },
        "DomainList": [
            {
                "DomainId": 12614766,
                "Name": "dnspod.com",
                "Status": "ENABLE",
                "TTL": 600,
                "CNAMESpeedup": "DISABLE",
                "DNSStatus": "DNSERROR",
                "Grade": "DP_ULTRA",
                "GradeLevel": 10,
                "GradeTitle": "尊享版",
                "GroupId": 1,
                "IsVip": "YES",
                "Punycode": "dnspod.com",
                "EffectiveDNS": ["ns3.dnsv5.com", "ns4.dnsv5.com"],
                "SearchEnginePush": "NO",
                "Remark": "",
                "CreatedOn": "2021-05-06 20:40:39",
                "UpdatedOn": "2023-03-09 11:51:56",
                "Owner": "qcloud_uin_000000000@qcloud.com",
                "VipAutoRenew": "YES",
                "VipEndAt": "2024-01-16 15:56:31",
                "VipStartAt": "2023-01-16 15:56:31",
                "RecordCount": 0,
                "TagList": [
                    {"TagKey": "app", "TagValue": "redis"}
                ]
            }
        ],
        "RequestId": "bfb3f27e-4dba-4a5c-9aff-08d1c27d1c61"
    }
}
```

**cURL 示例**

```bash
curl -X POST https://dnspod.tencentcloudapi.com \
  -H "X-TC-Action: DescribeDomainList" \
  -H "X-TC-Version: 2021-03-23" \
  -H "X-TC-Timestamp: 1551113065" \
  -H "Content-Type: application/json" \
  -H "Authorization: TC3-HMAC-SHA256 ..." \
  -d '{"Offset": 0, "Limit": 20, "Type": "ALL"}'
```

---

## 获取域名信息

### DescribeDomain

获取单个域名的详细信息。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| DomainInfo | DomainInfo | 域名信息 |
| RequestId | String | 请求 ID |

**响应示例**

```json
{
    "Response": {
        "DomainInfo": {
            "DomainId": 12620688,
            "Domain": "dnspod.cn",
            "Punycode": "dnspod.cn",
            "Grade": "DP_FREE",
            "GradeLevel": 2,
            "GradeTitle": "免费版",
            "Status": "enable",
            "GroupId": 1,
            "IsMark": "no",
            "TTL": 600,
            "CnameSpeedup": "disable",
            "Remark": "",
            "DNSStatus": "dnserror",
            "DnspodNsList": ["temporary.dnspod.net", "barman.dnspod.net"],
            "ActualNsList": [],
            "RecordCount": 182761,
            "UserId": 5301126,
            "IsVip": "no",
            "Owner": "qcloud_uin_100000******@qcloud.com",
            "OwnerNick": "昵称",
            "Uin": "100000******",
            "CreatedOn": "2023-03-21 17:27:40",
            "UpdatedOn": "2024-12-30 10:16:57",
            "IsGracePeriod": "no",
            "VipBuffered": "no",
            "IsSubDomain": false,
            "TagList": [],
            "SearchEnginePush": "no",
            "SlaveDNS": "no"
        },
        "RequestId": "c1ea5ee3-aa4b-446e-a42d-859b9461487b"
    }
}
```

---

## 添加域名

### CreateDomain

添加新域名到 DNSPod。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名（如 dnspod.cn） |
| GroupId | Integer | 否 | 分组 ID |
| Tags.N | Array of TagItem | 否 | 标签列表 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| DomainInfo | DomainCreateInfo | 创建的域名信息 |
| RequestId | String | 请求 ID |

**DomainCreateInfo 结构**

| 字段 | 类型 | 说明 |
|------|------|------|
| Id | Integer | 域名 ID |
| Domain | String | 域名 |
| Punycode | String | Punycode 格式 |
| GradeNsList | Array of String | NS 列表 |

---

## 删除域名

### DeleteDomain

删除域名。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 设置域名备注

### ModifyDomainRemark

设置域名备注信息。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| Remark | String | 是 | 备注内容（为空则删除备注） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 修改域名状态

### ModifyDomainStatus

修改域名状态（启用/暂停）。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| Status | String | 是 | 状态：`ENABLE` / `PAUSE` |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 获取域名共享信息

### DescribeDomainShareInfo

获取域名共享信息列表。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| DomainShareList | Array of DomainShareInfo | 共享信息列表 |
| RequestId | String | 请求 ID |

---

## 删除域名共享

### DeleteShareDomain

删除域名共享。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| AccountTo | String | 是 | 要删除的共享账号 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 锁定域名

### ModifyDomainLock

锁定域名。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| LockDays | Integer | 是 | 锁定天数 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| LockInfo | LockInfo | 锁定信息 |
| RequestId | String | 请求 ID |

---

## 解锁域名

### ModifyDomainUnlock

解锁域名。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| LockCode | String | 是 | 解锁代码 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 域名过户

### ModifyDomainOwner

将域名过户给其他用户。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| AccountTo | String | 是 | 目标用户账号 |
| Force | Boolean | 否 | 是否强制过户 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 获取域名 Whois 信息

### DescribeDomainWhois

获取域名的 Whois 信息。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| WhoisInfo | WhoisInfo | Whois 信息 |
| RequestId | String | 请求 ID |

---

## 获取域名筛选列表

### DescribeDomainFilterList

获取域名筛选列表。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Type | String | 否 | 筛选类型 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| DomainCountInfo | DomainCountInfo | 统计信息 |
| DomainList | Array of DomainListItem | 域名列表 |
| RequestId | String | 请求 ID |

---

## 获取域名日志

### DescribeDomainLogList

获取域名操作日志。

**请求参数**

| 参数名 | Type | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| LogList | Array of String | 日志列表 |
| RequestId | String | 请求 ID |

---

## 暂停子域名解析记录

### ModifySubdomainStatus

暂停子域名的所有解析记录。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| SubDomain | String | 是 | 子域名 |
| Status | String | 是 | 状态：`ENABLE` / `DISABLE` |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 获取域名别名列表

### DescribeDomainAliasList

获取域名别名列表。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| DomainAliasList | Array of DomainAliasInfo | 别名列表 |
| RequestId | String | 请求 ID |

---

## 创建域名别名

### CreateDomainAlias

为域名创建别名。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| DomainAlias | String | 是 | 域名别名 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| DomainAliasInfo | DomainAliasInfo | 创建的别名信息 |
| RequestId | String | 请求 ID |

---

## 删除域名别名

### DeleteDomainAlias

删除域名别名。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| DomainAliasId | Integer | 是 | 别名 ID |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 批量操作相关接口

### 批量添加域名

**CreateDomainBatch**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| DomainList.N | Array of String | 是 | 域名列表 |
| GroupId | Integer | 否 | 分组 ID |

**响应返回任务 ID**，需要配合 DescribeBatchTask 查询结果。

### 批量删除域名

**DeleteDomainBatch**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| DomainList.N | Array of Integer/String | 是 | 域名 ID 或域名列表 |

**响应返回任务 ID**，需要配合 DescribeBatchTask 查询结果。

---

## 域名分组接口

### 创建域名分组

**CreateDomainGroup**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| GroupName | String | 是 | 分组名称 |

### 获取域名分组列表

**DescribeDomainGroupList**

获取用户所有域名分组列表。

### 修改域名所属分组

**ModifyDomainToGroup**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| DomainList.N | Array of Integer | 是 | 域名 ID 列表 |
| GroupId | Integer | 是 | 分组 ID |

---

## 常见错误码

| 错误码 | 说明 |
|--------|------|
| FailedOperation.DomainExists | 域名已在列表中 |
| FailedOperation.DomainOwnedByOtherUser | 域名被其他账号添加 |
| FailedOperation.DomainIsLocked | 锁定域名不能操作 |
| FailedOperation.DomainIsSpam | 封禁域名不能操作 |
| FailedOperation.NotDomainOwner | 域名不在您的名下 |
| InvalidParameter.DomainInvalid | 域名格式不正确 |
| InvalidParameter.DomainIdInvalid | 域名编号不正确 |
| InvalidParameterValue.DomainNotExists | 域名不存在 |