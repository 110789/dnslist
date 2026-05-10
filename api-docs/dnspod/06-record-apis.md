# DNSPod API v3 - 记录相关接口

## 概述

记录相关接口用于管理域名的 DNS 解析记录，包括记录的增删改查、批量操作、动态 DNS 等功能。

---

## 接口列表

| 接口 | Action | 频率限制 |
|------|--------|----------|
| 获取解析记录列表 | DescribeRecordList | 100次/秒 |
| 获取记录信息 | DescribeRecord | 200次/秒 |
| 添加记录 | CreateRecord | - |
| 修改记录 | ModifyRecord | - |
| 删除记录 | DeleteRecord | - |
| 设置记录状态 | ModifyRecordStatus | 20次/秒 |
| 设置记录备注 | ModifyRecordRemark | 20次/秒 |
| 更新动态 DNS 记录 | ModifyDynamicDNS | 20次/秒 |
| 修改记录可选字段 | ModifyRecordFields | 20次/秒 |
| 添加 TXT 记录 | CreateTXTRecord | 20次/秒 |
| 修改 TXT 记录 | ModifyTXTRecord | 20次/秒 |
| 获取等级允许的记录类型 | DescribeRecordType | 20次/秒 |
| 获取等级允许的线路 | DescribeRecordLineList | 20次/秒 |
| 获取域名的解析记录筛选列表 | DescribeRecordFilterList | 20次/秒 |
| 判断是否有除系统默认的 @-NS 记录之外的记录 | DescribeRecordExistExceptDefaultNS | 20次/秒 |
| 批量添加记录 | CreateRecordBatch | 20次/秒 |
| 批量修改记录 | ModifyRecordBatch | 20次/秒 |
| 批量删除记录 | DeleteRecordBatch | 20次/秒 |

---

## 获取解析记录列表

### DescribeRecordList

获取某个域名下的解析记录列表。

> 注意：新添加的解析记录存在短暂的索引延迟，如果查询不到新增记录，请在 30 秒后重试。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| Subdomain | String | 否 | 主机头筛选 |
| RecordType | String | 否 | 记录类型筛选：`A`/`CNAME`/`NS`/`AAAA`/`显性URL`/`隐性URL`/`CAA`/`SPF` 等 |
| RecordLine | String | 否 | 解析线路名称 |
| RecordLineId | String | 否 | 解析线路 ID（优先级高于 RecordLine） |
| GroupId | Integer | 否 | 记录分组 ID |
| Keyword | String | 否 | 搜索关键字（主机头和记录值） |
| SortField | String | 否 | 排序字段：`name`/`line`/`type`/`value`/`weight`/`mx`/`ttl`/`updated_on` |
| SortType | String | 否 | 排序方式：`ASC`/`DESC`，默认 ASC |
| Offset | Integer | 否 | 偏移量，默认 0 |
| Limit | Integer | 否 | 限制数量，最大 3000，默认 100 |
| ErrorOnEmpty | String | 否 | 查询不到数据时是否报错：`yes`/`no`，默认 yes |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RecordCountInfo | RecordCountInfo | 记录数量统计 |
| RecordList | Array of RecordListItem | 记录列表 |
| RequestId | String | 请求 ID |

**响应示例**

```json
{
    "Response": {
        "RequestId": "561cdfcb-37a6-47de-b3c5-2b038e2c2276",
        "RecordCountInfo": {
            "SubdomainCount": 2,
            "TotalCount": 2,
            "ListCount": 2
        },
        "RecordList": [
            {
                "RecordId": 556507778,
                "Value": "f1g1ns1.dnspod.net.",
                "Status": "ENABLE",
                "UpdatedOn": "2021-03-28 11:27:09",
                "Name": "@",
                "Line": "默认",
                "LineId": "0",
                "Type": "NS",
                "Weight": null,
                "MonitorStatus": "",
                "Remark": "",
                "TTL": 86400,
                "MX": 0,
                "DefaultNS": true
            },
            {
                "RecordId": 556507779,
                "Value": "f1g1ns2.dnspod.net.",
                "Status": "ENABLE",
                "UpdatedOn": "2021-03-28 11:27:09",
                "Name": "@",
                "Line": "默认",
                "LineId": "0",
                "Type": "NS",
                "Weight": null,
                "MonitorStatus": "",
                "Remark": "",
                "TTL": 86400,
                "MX": 0,
                "DefaultNS": true
            }
        ]
    }
}
```

**cURL 示例**

```bash
curl -X POST https://dnspod.tencentcloudapi.com \
  -H "X-TC-Action: DescribeRecordList" \
  -H "X-TC-Version: 2021-03-23" \
  -H "X-TC-Timestamp: 1551113065" \
  -H "Content-Type: application/json" \
  -H "Authorization: TC3-HMAC-SHA256 ..." \
  -d '{"Domain": "dnspod.cn", "Offset": 0, "Limit": 100}'
```

---

## 获取记录信息

### DescribeRecord

获取单条解析记录的详细信息。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordId | Integer | 是 | 记录 ID |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RecordInfo | RecordInfo | 记录信息 |
| RequestId | String | 请求 ID |

**响应示例**

```json
{
    "Response": {
        "RequestId": "ab4f1426-ea15-42ea-8183-dc1b44151166",
        "RecordInfo": {
            "Id": 162,
            "SubDomain": "www",
            "RecordType": "A",
            "RecordLine": "百度",
            "RecordLineId": "90=0",
            "Value": "129.23.32.32",
            "Weight": null,
            "MX": 0,
            "TTL": 10,
            "Enabled": 1,
            "MonitorStatus": "Ok",
            "Remark": "备注",
            "UpdatedOn": "2021-03-31 11:38:02",
            "DomainId": 62
        }
    }
}
```

---

## 添加记录

### CreateRecord

添加新的解析记录。

> 注意：新添加的解析记录存在短暂的索引延迟，如果查询不到新增记录，请在 30 秒后重试。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordType | String | 是 | 记录类型，通过 DescribeRecordType 获取 |
| RecordLine | String | 是 | 解析线路，通过 DescribeRecordLineList 获取 |
| Value | String | 是 | 记录值（IP/CNAME/MX 等） |
| SubDomain | String | 否 | 主机记录，默认 @ |
| RecordLineId | String | 否 | 解析线路 ID（优先级高于 RecordLine） |
| MX | Integer | 否 | MX 优先级，MX/HTTPS/SVCB 类型必填，范围 0-65535 |
| TTL | Integer | 否 | TTL，范围 1-604800 |
| Weight | Integer | 否 | 权重，0-100 整数，0 表示关闭 |
| Status | String | 否 | 初始状态：`ENABLE`/`DISABLE`，默认 ENABLE |
| Remark | String | 否 | 备注 |
| DnssecConflictMode | String | 否 | DNSSEC 开启时强制添加 CNAME/URL：`force` |
| GroupId | Integer | 否 | 记录分组 ID |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RecordId | Integer | 新增的记录 ID |
| RequestId | String | 请求 ID |

**响应示例**

```json
{
    "Response": {
        "RequestId": "ab4f1426-ea15-42ea-8183-dc1b44151166",
        "RecordId": 162
    }
}
```

**cURL 示例**

```bash
curl -X POST https://dnspod.tencentcloudapi.com \
  -H "X-TC-Action: CreateRecord" \
  -H "X-TC-Version: 2021-03-23" \
  -H "X-TC-Timestamp: 1551113065" \
  -H "Content-Type: application/json" \
  -H "Authorization: TC3-HMAC-SHA256 ..." \
  -d '{
    "Domain": "dnspod.cn",
    "RecordType": "A",
    "RecordLine": "默认",
    "Value": "200.200.200.200",
    "SubDomain": "www",
    "TTL": 600
  }'
```

---

## 修改记录

### ModifyRecord

修改已有的解析记录。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordId | Integer | 是 | 记录 ID |
| RecordType | String | 是 | 记录类型 |
| RecordLine | String | 是 | 解析线路 |
| Value | String | 是 | 记录值 |
| SubDomain | String | 否 | 主机记录，默认 @ |
| RecordLineId | String | 否 | 解析线路 ID（优先级高于 RecordLine） |
| MX | Integer | 否 | MX 优先级 |
| TTL | Integer | 否 | TTL |
| Weight | Integer | 否 | 权重 |
| Status | String | 否 | 状态：`ENABLE`/`DISABLE` |
| Remark | String | 否 | 备注（传空删除备注） |
| DnssecConflictMode | String | 否 | DNSSEC 开启时强制将其他记录修改为 CNAME/URL |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RecordId | Integer | 记录 ID |
| RequestId | String | 请求 ID |

---

## 删除记录

### DeleteRecord

删除指定的解析记录。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordId | Integer | 是 | 记录 ID |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 设置记录状态

### ModifyRecordStatus

启用或暂停解析记录。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordId | Integer | 是 | 记录 ID |
| Status | String | 是 | 状态：`ENABLE`/`DISABLE` |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 设置记录备注

### ModifyRecordRemark

设置或修改解析记录的备注信息。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordId | Integer | 是 | 记录 ID |
| Remark | String | 是 | 备注内容（传空删除备注） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RequestId | String | 请求 ID |

---

## 更新动态 DNS 记录

### ModifyDynamicDNS

更新动态 DNS 记录的 IP 地址。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordId | Integer | 是 | 记录 ID |
| Value | String | 是 | 新的记录值（IP地址） |
| SubDomain | String | 否 | 主机记录 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RecordId | Integer | 记录 ID |
| RequestId | String | 请求 ID |

---

## 修改记录可选字段

### ModifyRecordFields

只修改记录的某些可选字段。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordId | Integer | 是 | 记录 ID |
| FieldList.N | Array of KeyValue | 是 | 要修改的字段列表 |

**KeyValue 结构**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Key | String | 是 | 键，如 `ttl`/`remark` |
| Value | String | 否 | 值 |

---

## 添加 TXT 记录

### CreateTXTRecord

快速添加 TXT 记录。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| SubDomain | String | 是 | 主机记录 |
| Value | String | 是 | TXT 记录值 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RecordId | Integer | 记录 ID |
| RequestId | String | 请求 ID |

---

## 修改 TXT 记录

### ModifyTXTRecord

快速修改 TXT 记录。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordId | Integer | 是 | 记录 ID |
| Value | String | 是 | 新的 TXT 记录值 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| RecordId | Integer | 记录 ID |
| RequestId | String | 请求 ID |

---

## 获取等级允许的记录类型

### DescribeRecordType

获取指定等级支持的记录类型。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| DomainGrade | String | 是 | 域名等级代码 |

**旧套餐等级代码：**
| 代码 | 说明 |
|------|------|
| D_Free | 免费版 |
| D_Plus | 个人豪华版 |
| D_Extra | 企业 I 版 |
| D_Expert | 企业 II 版 |
| D_Ultra | 企业 III 版 |

**新套餐等级代码：**
| 代码 | 说明 |
|------|------|
| DP_Free | 新免费版 |
| DP_Plus | 个人专业版 |
| DP_Extra | 企业创业版 |
| DP_Expert | 企业标准版 |
| DP_Ultra | 企业旗舰版 |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| TypeList | Array of String | 记录类型列表 |
| RequestId | String | 请求 ID |

**响应示例**

```json
{
    "Response": {
        "RequestId": "ab4f1426-ea15-42ea-8183-dc1b44151166",
        "TypeList": [
            "A", "CNAME", "MX", "TXT", "NS", "SPF",
            "SRV", "CAA", "显性URL", "隐性URL"
        ]
    }
}
```

---

## 获取等级允许的线路

### DescribeRecordLineList

获取指定域名和等级支持的解析线路。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainGrade | String | 是 | 域名等级 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| LineList | Array of LineInfo | 线路列表 |
| LineGroupList | Array of LineGroupInfo | 线路分组列表 |
| RequestId | String | 请求 ID |

**响应示例**

```json
{
    "Response": {
        "LineGroupList": [
            {
                "LineId": "998=3",
                "Name": "分组2",
                "LineList": ["境外", "第3个_line", "第2个_line"],
                "Type": "user"
            },
            {
                "Name": "东北",
                "LineId": "15=1",
                "LineList": ["黑龙江移动", "黑龙江电信", "黑龙江联通"],
                "Type": "system"
            }
        ],
        "LineList": [
            {"Name": "默认", "LineId": "0"},
            {"Name": "境外", "LineId": "3=0"},
            {"Name": "境内", "LineId": "7=0"},
            {"Name": "电信", "LineId": "10=0"},
            {"Name": "联通", "LineId": "10=1"}
        ]
    }
}
```

---

## 获取解析记录筛选列表

### DescribeRecordFilterList

获取域名的解析记录筛选列表。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| Type | String | 否 | 筛选类型 |

---

## 判断是否有非默认 NS 记录

### DescribeRecordExistExceptDefaultNS

判断是否有除系统默认的 @-NS 记录之外的记录存在。

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |

**响应参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| Exist | Boolean | 是否存在 |
| RequestId | String | 请求 ID |

---

## 批量操作接口

### 批量添加记录

**CreateRecordBatch**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordList.N | Array of AddRecordBatch | 是 | 记录列表 |

**AddRecordBatch 结构**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| RecordType | String | 是 | 记录类型 |
| Value | String | 是 | 记录值 |
| SubDomain | String | 否 | 子域名，默认 @ |
| RecordLine | String | 否 | 解析线路 |
| RecordLineId | String | 否 | 线路 ID |
| MX | Integer | 否 | MX 优先级 |
| TTL | Integer | 否 | TTL，默认 600 |

**响应返回任务 ID**，需要配合 DescribeBatchTask 查询结果。

---

### 批量修改记录

**ModifyRecordBatch**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordList.N | Array of ModifyRecordItem | 是 | 记录列表 |
| ChangeType | String | 是 | 变更类型 |
| ChangeValue | String | 否 | 变更值 |

**ModifyRecordItem 结构**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| RecordId | Integer | 是 | 记录 ID |
| SubDomain | String | 否 | 子域名 |
| RecordType | String | 否 | 记录类型 |
| RecordLine | String | 否 | 解析线路 |
| Value | String | 否 | 记录值 |
| MX | Integer | 否 | MX 优先级 |
| TTL | Integer | 否 | TTL |
| Enabled | Integer | 否 | 状态 |

---

### 批量删除记录

**DeleteRecordBatch**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordList.N | Array of Integer | 是 | 记录 ID 列表 |

---

## 记录分组接口

### 创建记录分组

**CreateRecordGroup**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| GroupName | String | 是 | 分组名称 |

### 查询记录分组列表

**DescribeRecordGroupList**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |

### 修改记录分组

**ModifyRecordGroup**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| GroupId | Integer | 是 | 分组 ID |
| GroupName | String | 是 | 新分组名称 |

### 删除记录分组

**DeleteRecordGroup**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| GroupId | Integer | 是 | 分组 ID |

### 将记录添加到分组

**ModifyRecordToGroup**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| Domain | String | 是 | 域名 |
| DomainId | Integer | 否 | 域名 ID（优先级高于 Domain） |
| RecordIdList.N | Array of Integer | 是 | 记录 ID 列表 |
| GroupId | Integer | 是 | 分组 ID |

---

## 常见错误码

| 错误码 | 说明 |
|--------|------|
| FailedOperation.DomainRecordExist | 记录已存在 |
| FailedOperation.MustAddDefaultLineFirst | 请先添加默认线路记录 |
| InvalidParameter.SubdomainInvalid | 子域名不正确 |
| InvalidParameter.RecordTypeInvalid | 记录类型不正确 |
| InvalidParameter.RecordLineInvalid | 记录线路不正确 |
| InvalidParameter.RecordValueInvalid | 记录值不正确 |
| InvalidParameter.MxInvalid | MX 优先级不正确 |
| InvalidParameter.InvalidWeight | 权重不合法 |
| LimitExceeded.AAAACountLimit | AAAA 记录超出限制 |
| LimitExceeded.RecordTtlLimit | TTL 超出限制 |
| LimitExceeded.SrvCountLimit | SRV 记录超出限制 |
| ResourceNotFound.NoDataOfRecord | 记录列表为空 |