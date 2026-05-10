# DNSPod API v3 - 数据结构

## 用户信息 (UserInfo)

获取账户信息接口返回的用户信息结构。

| 字段 | 类型 | 说明 |
|------|------|------|
| Id | Integer | 用户 ID |
| UserId | Integer | 用户 ID（与 Id 相同） |
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

**示例：**
```json
{
    "Id": 123456,
    "UIN": 123456,
    "Email": "user@example.com",
    "EmailVerified": "yes",
    "Nick": "nickname",
    "Status": "enabled",
    "Telephone": "138****8888",
    "TelephoneVerified": "yes",
    "UserGrade": "DP_Free",
    "AllowTransferIn": false,
    "FreeNs": ["v4u4f.dnspod.net", "c6b8q.dnspod.net"]
}
```

---

## 域名信息 (DomainInfo)

获取单个域名详情返回的信息结构。

| 字段 | 类型 | 说明 |
|------|------|------|
| DomainId | Integer | 域名 ID |
| Domain | String | 域名 |
| Punycode | String | 域名的 Punycode 格式 |
| Grade | String | 域名等级代码，如 `DP_FREE` |
| GradeLevel | Integer | 域名等级代号 |
| GradeTitle | String | 域名等级名称，如 `免费版` |
| Status | String | 域名状态：`ENABLE` / `PAUSE` / `SPAM` |
| GroupId | Integer | 域名分组 ID |
| IsMark | String | 是否星标：`yes` / `no` |
| TTL | Integer | TTL 值（秒） |
| CnameSpeedup | String | CNAME 加速状态 |
| Remark | String | 域名备注 |
| DNSStatus | String | DNS 状态，正常为空，错误为 `dnserror` |
| DnspodNsList | Array of String | DNSPod 分配的 NS 列表 |
| ActualNsList | Array of String | 域名实际使用的 NS 列表 |
| RecordCount | Integer | 域名下记录数量 |
| UserId | Integer | 用户 ID |
| IsVip | String | 是否 VIP：`yes` / `no` |
| Owner | String | 域名所有者账号 |
| OwnerNick | String | 域名所有者昵称 |
| Uin | String | 腾讯云 UIN |
| CreatedOn | String | 创建时间 |
| UpdatedOn | String | 最后更新时间 |
| VipStartAt | String | VIP 开始时间 |
| VipEndAt | String | VIP 结束时间 |
| VipAutoRenew | String | VIP 自动续费：`default` / `yes` / `no` |
| VipResourceId | String | VIP 资源 ID |
| IsGracePeriod | String | 是否在宽限期 |
| VipBuffered | String | 是否在缓冲期 |
| IsSubDomain | Boolean | 是否子域名 |
| TagList | Array of [TagItem](#TagItem) | 域名标签列表 |
| SearchEnginePush | String | 搜索引擎推送状态 |
| SlaveDNS | String | 是否开启辅助 DNS |

---

## 域名列表项 (DomainListItem)

获取域名列表中每个域名的信息结构。

| 字段 | 类型 | 说明 |
|------|------|------|
| DomainId | Integer | 域名 ID |
| Name | String | 域名原始格式 |
| Status | String | 域名状态：`ENABLE` / `PAUSE` / `SPAM` |
| TTL | Integer | 默认 TTL 值（秒） |
| CNAMESpeedup | String | CNAME 加速：`ENABLE` / `DISABLE` |
| DNSStatus | String | DNS 设置状态，错误为 `DNSERROR` |
| Grade | String | 域名等级代码 |
| GradeLevel | Integer | 域名等级序号 |
| GradeTitle | String | 套餐名称 |
| GroupId | Integer | 域名分组 ID |
| IsVip | String | 是否 VIP：`YES` / `NO` |
| Punycode | String | Punycode 编码格式 |
| EffectiveDNS | Array of String | 有效 DNS 服务器 |
| SearchEnginePush | String | 搜索引擎推送：`YES` / `NO` |
| Remark | String | 域名备注 |
| CreatedOn | String | 添加时间 |
| UpdatedOn | String | 更新时间 |
| Owner | String | 域名所属账号 |
| VipStartAt | String | VIP 开始时间 |
| VipEndAt | String | VIP 结束时间 |
| VipAutoRenew | String | VIP 自动续费 |
| RecordCount | Integer | 记录数量 |
| TagList | Array of [TagItem](#TagItem) | 标签列表 |

---

## 域名统计信息 (DomainCountInfo)

域名列表统计信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| DomainTotal | Integer | 符合条件的域名数量 |
| AllTotal | Integer | 用户可查看的所有域名数量 |
| MineTotal | Integer | 用户账号添加的域名数量 |
| ShareTotal | Integer | 共享给用户的域名数量 |
| VipTotal | Integer | 付费域名数量 |
| PauseTotal | Integer | 暂停的域名数量 |
| ErrorTotal | Integer | DNS 设置错误的域名数量 |
| LockTotal | Integer | 锁定的域名数量 |
| SpamTotal | Integer | 封禁的域名数量 |
| VipExpire | Integer | 30天内即将到期的域名数量 |
| ShareOutTotal | Integer | 分享给其他人的域名数量 |
| GroupTotal | Integer | 指定分组内的域名数量 |

---

## 解析记录信息 (RecordInfo)

获取单条记录详情返回的信息结构。

| 字段 | 类型 | 说明 |
|------|------|------|
| Id | Integer | 记录 ID |
| SubDomain | String | 子域名（主机记录） |
| RecordType | String | 记录类型 |
| RecordLine | String | 解析线路 |
| RecordLineId | String | 解析线路 ID |
| Value | String | 记录值 |
| Weight | Integer | 权重（0-100） |
| MX | Integer | MX 优先级 |
| TTL | Integer | TTL 值（秒） |
| Enabled | Integer | 是否启用：`1` / `0` |
| MonitorStatus | String | 监控状态 |
| Remark | String | 记录备注 |
| UpdatedOn | String | 更新时间 |
| DomainId | Integer | 域名 ID |

---

## 解析记录列表项 (RecordListItem)

获取解析记录列表中每条记录的信息结构。

| 字段 | 类型 | 说明 |
|------|------|------|
| RecordId | Integer | 记录 ID |
| Name | String | 记录名称（主机记录） |
| Type | String | 记录类型 |
| Line | String | 解析线路 |
| LineId | String | 解析线路 ID |
| Value | String | 记录值 |
| TTL | Integer | TTL 值（秒） |
| MX | Integer | MX 优先级（MX 记录有效） |
| Weight | Integer | 权重 |
| Status | String | 记录状态：`ENABLE` / `DISABLE` |
| MonitorStatus | String | 监控状态 |
| UpdatedOn | String | 更新时间 |
| Remark | String | 记录备注 |
| DefaultNS | Boolean | 是否为系统默认 NS 记录 |

---

## 记录数量统计 (RecordCountInfo)

记录列表统计信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| SubdomainCount | Integer | 子域名数量 |
| TotalCount | Integer | 总记录数 |
| ListCount | Integer | 当前返回记录数 |

---

## 线路信息 (LineInfo)

解析线路信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| Name | String | 线路名称 |
| LineId | String | 线路 ID |

---

## 线路分组信息 (LineGroupInfo)

线路分组信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| LineId | String | 分组 ID |
| Name | String | 分组名称 |
| LineList | Array of String | 线路列表 |
| Type | String | 分组类型：`system` / `user` |

---

## 标签项 (TagItem)

标签信息结构。

| 字段 | 类型 | 说明 |
|------|------|------|
| TagKey | String | 标签键 |
| TagValue | String | 标签值 |

---

## 域名别名信息 (DomainAliasInfo)

域名别名信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| Id | Integer | 域名别名 ID |
| DomainAlias | String | 域名别名 |
| Status | Integer | 别名状态：1-DNS不正确；2-正常；3-封禁 |

---

## 域名共享信息 (DomainShareInfo)

域名共享信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| ShareTo | String | 共享目标账号 |
| Mode | String | 共享模式：`rw`（可读写）/ `r`（只读） |
| Status | String | 共享状态：`enabled` / `pending` |

---

## 域名分组信息 (GroupInfo)

域名分组信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| GroupId | Integer | 分组 ID |
| GroupName | String | 分组名称 |
| GroupType | String | 分组类型 |
| Size | Integer | 分组内域名数量 |

---

## 套餐列表项 (PackageListItem)

套餐信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| Domain | String | 绑定的域名 |
| Type | String | 套餐类型 |
| Value | String | 套餐值 |
| StartTime | String | 开始时间 |
| EndTime | String | 结束时间 |

---

## 套餐配置项 (PackageDetailItem)

套餐配置详情。

| 字段 | 类型 | 说明 |
|------|------|------|
| Name | String | 配置名称 |
| Value | String | 配置值 |

---

## 自定义线路信息 (CustomLineInfo)

自定义线路详情。

| 字段 | 类型 | 说明 |
|------|------|------|
| DomainId | Integer | 域名 ID |
| Name | String | 自定义线路名称 |
| Area | String | 自定义线路 IP 段 |
| UseCount | Integer | 已使用 IP 段个数 |
| MaxCount | Integer | 允许使用最大个数 |

---

## 记录分组信息 (RecordGroupInfo)

记录分组信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| GroupId | Integer | 分组 ID |
| GroupName | String | 分组名称 |
| GroupType | String | 分组类型 |

---

## 解析量统计信息 (DomainAnalyticsInfo)

解析量统计查询信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| DnsFormat | String | 统计格式：`DATE`（按天）/ `HOUR`（按小时） |
| DnsTotal | Integer | 解析量总计 |
| Domain | String | 域名 |
| StartDate | String | 统计周期开始时间 |
| EndDate | String | 统计周期结束时间 |

---

## 解析量数据项 (DomainAnalyticsDetail)

解析量统计数据。

| 字段 | 类型 | 说明 |
|------|------|------|
| Num | Integer | 当前统计维度解析量小计 |
| DateKey | String | 按天统计时的日期 |
| HourKey | Integer | 按小时统计时的小时数（0-23） |

---

## 安全信息 (SecurityInfo)

安全信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| SecurityStatus | String | 安全状态 |
| DroneLockLeftTime | Integer | 锁定剩余时间 |

---

## 批量添加域名返回结构 (CreateDomainBatchDetail)

| 字段 | 类型 | 说明 |
|------|------|------|
| RecordList | Array | 见 RecordInfoBatch |
| Id | Integer | 任务编号 |
| Domain | String | 域名 |
| DomainGrade | String | 域名等级 |
| ErrMsg | String | 错误信息 |
| Status | String | 任务运行状态 |
| Operation | String | 操作类型 |

---

## 批量添加记录返回结构 (CreateRecordBatchDetail)

| 字段 | 类型 | 说明 |
|------|------|------|
| RecordList | Array | 见 RecordInfoBatch |
| Id | Integer | 任务编号 |
| Domain | String | 域名 |
| DomainGrade | String | 域名等级 |
| DomainId | Integer | 域名 ID |
| ErrMsg | String | 错误信息 |
| Status | String | 任务运行状态 |
| Operation | String | 操作类型 |

---

## 批量任务记录信息 (BatchRecordInfo)

| 字段 | 类型 | 说明 |
|------|------|------|
| RecordId | Integer | 记录 ID |
| SubDomain | String | 子域名 |
| RecordType | String | 记录类型 |
| RecordLine | String | 解析线路 |
| Value | String | 记录值 |
| TTL | Integer | TTL 值 |
| Status | String | 记录添加状态 |
| Operation | String | 操作类型 |
| ErrMsg | String | 错误信息 |
| Id | Integer | 列表中的 ID |
| Enabled | Integer | 生效状态 |
| MX | Integer | MX 权重 |
| Weight | Integer | 权重 |
| Remark | String | 备注信息 |

---

## WHOIS 信息 (WhoisInfo)

域名 WHOIS 信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| Domain | String | 域名 |
| Registrar | String | 注册商 |
| Registrant | String | 注册人 |
| NameServers | Array of String | 名称服务器 |
| CreatedDate | String | 创建日期 |
| ExpiryDate | String | 到期日期 |
| UpdatedDate | String | 更新日期 |
| Status | String | 域名状态 |
| DNSSEC | String | DNSSEC 状态 |
| Contacts | [WhoisContact](#WhoisContact) | 联系人信息 |

---

## WHOIS 联系信息 (WhoisContact)

| 字段 | 类型 | 说明 |
|------|------|------|
| Registrant | [WhoisContactAddress](#WhoisContactAddress) | 注册人信息 |
| Administrative | [WhoisContactAddress](#WhoisContactAddress) | 管理员信息 |
| Technical | [WhoisContactAddress](#WhoisContactAddress) | 技术联系人 |

---

## WHOIS 联系地址 (WhoisContactAddress)

| 字段 | 类型 | 说明 |
|------|------|------|
| Name | String | 姓名 |
| Company | String | 公司 |
| Country | String | 国家 |
| Province | String | 省份 |
| City | String | 城市 |
| Street | String | 街道地址 |
| PostalCode | String | 邮政编码 |
| Phone | String | 电话 |
| Fax | String | 传真 |
| Email | String | 邮箱 |

---

## 快照配置 (SnapshotConfig)

快照配置信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| Status | String | 快照状态：`enabled` / `disabled` |
| Period | String | 快照周期 |
| KeepDays | Integer | 保留天数 |

---

## 快照信息 (SnapshotInfo)

快照信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| Id | Integer | 快照 ID |
| CreateTime | String | 创建时间 |
| Status | String | 状态 |
| DomainId | Integer | 域名 ID |
| Type | String | 类型 |

---

## 锁信息 (LockInfo)

域名锁定信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| DomainId | Integer | 域名 ID |
| LockCode | String | 解锁代码 |
| LockEnd | String | 锁定结束时间 |

---

## 记录状态枚举值

| 状态值 | 说明 |
|--------|------|
| ENABLE | 记录生效 |
| DISABLE | 记录暂停 |

---

## 域名状态枚举值

| 状态值 | 说明 |
|--------|------|
| ENABLE | 正常 |
| PAUSE | 暂停 |
| SPAM | 封禁 |

---

## 域名等级枚举值

### 旧套餐

| 等级代码 | 说明 |
|----------|------|
| D_Free | 免费版 |
| D_Plus | 个人豪华版 |
| D_Extra | 企业 I 版 |
| D_Expert | 企业 II 版 |
| D_Ultra | 企业 III 版 |

### 新套餐

| 等级代码 | 说明 |
|----------|------|
| DP_Free | 新免费版 |
| DP_Plus | 个人专业版 |
| DP_Extra | 企业创业版 |
| DP_Expert | 企业标准版 |
| DP_Ultra | 企业旗舰版 |

---

## 记录类型

| 类型 | 说明 |
|------|------|
| A | IPv4 地址记录 |
| AAAA | IPv6 地址记录 |
| CNAME | 别名记录 |
| MX | 邮件交换记录 |
| TXT | 文本记录 |
| NS | 名称服务器记录 |
| SRV | 服务定位器记录 |
| CAA | CA 授权验证记录 |
| SPF | 发送方策略框架 |
| HTTPS | HTTPS 记录 |
| SVCB | 服务绑定记录 |
| 显性URL | 显性 URL 转发 |
| 隐性URL | 隐性 URL 转发 |