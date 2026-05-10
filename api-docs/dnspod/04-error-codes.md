# DNSPod API v3 - 错误码

## 错误响应格式

调用 API 接口失败时，返回结果中包含 Error 字段：

```json
{
    "Response": {
        "Error": {
            "Code": "AuthFailure.SignatureFailure",
            "Message": "The provided credentials could not be validated."
        },
        "RequestId": "ed93f3cb-f35e-473f-b9f3-0d451b8b79c6"
    }
}
```

| 字段 | 说明 |
|------|------|
| Error.Code | 错误码 |
| Error.Message | 错误信息（可能随业务更新而变化） |
| RequestId | 请求唯一 ID，用于问题定位 |

---

## 公共错误码

以下错误码为所有业务可能出现的通用错误：

| 错误码 | 说明 |
|--------|------|
| ActionOffline | 接口已下线 |
| AuthFailure.InvalidAuthorization | 请求头部的 Authorization 不符合腾讯云标准 |
| AuthFailure.InvalidSecretId | 密钥非法（不是云 API 密钥类型） |
| AuthFailure.MFAFailure | MFA 错误 |
| AuthFailure.SecretIdNotFound | 密钥不存在 |
| AuthFailure.SignatureExpire | 签名过期，Timestamp 和服务器时间相差超过 5 分钟 |
| AuthFailure.SignatureFailure | 签名错误 |
| AuthFailure.TokenFailure | Token 错误 |
| AuthFailure.UnauthorizedOperation | 请求未授权 |
| DryRunOperation | DryRun 操作成功 |
| FailedOperation | 操作失败 |
| InternalError | 内部错误 |
| InvalidAction | 接口不存在 |
| InvalidParameter | 参数错误 |
| InvalidParameterValue | 参数取值错误 |
| InvalidRequest | 请求 body 格式错误 |
| IpInBlacklist | IP 地址在黑名单中 |
| IpNotInWhitelist | IP 地址不在白名单中 |
| LimitExceeded | 超过配额限制 |
| MissingParameter | 缺少参数 |
| NoSuchProduct | 产品不存在 |
| NoSuchVersion | 接口版本不存在 |
| RequestLimitExceeded | 请求次数超过频率限制 |
| RequestLimitExceeded.GlobalRegionUinLimitExceeded | 主账号超过频率限制 |
| RequestLimitExceeded.IPLimitExceeded | IP 限频 |
| RequestLimitExceeded.UinLimitExceeded | 主账号限频 |
| RequestSizeLimitExceeded | 请求包超过限制大小 |
| ResourceInUse | 资源被占用 |
| ResourceInsufficient | 资源不足 |
| ResourceNotFound | 资源不存在 |
| ResourceUnavailable | 资源不可用 |
| ResponseSizeLimitExceeded | 返回包超过限制大小 |
| ServiceUnavailable | 当前服务暂时不可用 |
| UnauthorizedOperation | 未授权操作 |
| UnknownParameter | 未知参数错误 |
| UnsupportedOperation | 操作不支持 |
| UnsupportedProtocol | 请求协议错误，只支持 GET 和 POST |
| UnsupportedRegion | 接口不支持所传地域 |

---

## 业务错误码

### 账户相关错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| FailedOperation.AccountIsLocked | 账户已被锁定 | 联系客服解锁 |
| FailedOperation.NotRealNamedUser | 未实名认证 | 完成实名认证后重试 |
| InvalidParameter.AccountIsBanned | 账号已被封禁 | 联系客服处理 |
| FailedOperation.LoginAreaNotAllowed | 账号异地登录被拒绝 | 确认登录环境 |
| FailedOperation.LoginFailed | 登录失败 | 检查账号密码是否正确 |
| FailedOperation.LoginTimeout | 登录超时 | 重新登录 |

### 认证相关错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| AuthFailure | CAM 签名/鉴权错误 | 检查密钥和签名是否正确 |
| InvalidParameter.LoginTokenIdError | Token 的 ID 不正确 | 检查 Token 参数 |
| InvalidParameter.LoginTokenNotExists | Token 不存在 | 检查 Token 参数 |
| InvalidParameter.LoginTokenValidateFailed | Token 验证失败 | 重新获取 Token |
| InvalidParameter.RequestIpLimited | IP 非法，请求被拒绝 | 检查请求 IP |
| LimitExceeded.FailedLoginLimitExceeded | 登录失败次数过多被封禁 | 等待解封或联系客服 |

### 域名相关错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| FailedOperation.DomainExists | 域名已在列表中 | 无需重复添加 |
| FailedOperation.DomainOwnedByOtherUser | 域名被其他账号添加 | 可在域名列表中取回 |
| FailedOperation.DomainIsLocked | 锁定域名不能操作 | 先解锁域名 |
| FailedOperation.DomainIsSpam | 封禁域名不能操作 | 联系客服处理 |
| FailedOperation.DomainIsVip | VIP 域名不能进行此操作 | 检查操作是否允许 |
| FailedOperation.DomainNotInService | 域名未使用 DNSPod 服务 | 无法获取解析量数据 |
| FailedOperation.NotDomainOwner | 域名不在您的名下 | 检查域名归属 |
| FailedOperation.DomainIsKeyDomain | 域名为重点保护资源禁止删除 | 联系客户经理 |
| FailedOperation.DomainInEnterpriseMailAccount | 域名属于企业邮用户 | 无法操作 |
| FailedOperation.DomainIsEnterpriseType | 域名已升级为企业套餐但位于个人账号 | 联系销售 |
| FailedOperation.DomainIsPersonalType | 域名已升级为个人套餐但位于企业账号 | 联系销售 |
| InvalidParameter.DomainInvalid | 域名格式不正确 | 输入主域名，如 dnspod.cn |
| InvalidParameter.DomainIdInvalid | 域名编号不正确 | 检查 DomainId 参数 |
| InvalidParameter.DomainNotReged | 域名未注册 | 先注册域名 |
| InvalidParameter.DomainNotEffective | 域名未生效 | 等待域名生效 |
| InvalidParameter.DomainInBlackList | 域名涉及违法违规黑名单 | 无法操作 |
| InvalidParameter.DomainIsAliaser | 此域名是其他域名的别名 | 检查域名 |
| InvalidParameter.DomainIsMyAlias | 此域名是自己域名的别名 | 检查域名 |
| InvalidParameter.DomainDuplicated | 一个任务里不能存在相同的域名 | 去除重复域名 |
| InvalidParameter.DomainNotAllowedLock | 暂停域名不支持锁定 | 先恢复域名 |
| InvalidParameter.DomainNotAllowedModifyRecords | 生效中/失效中的域名不允许变更解析记录 | 等待域名状态恢复 |
| InvalidParameter.DomainNotBeian | 域名未备案无法添加 URL 记录 | 完成备案或使用其他记录类型 |
| InvalidParameter.DomainIsModifyingDns | 域名已有同类型操作未完成 | 等待操作完成 |
| InvalidParameter.DomainTaskNotFinished | 存在进行中的任务 | 等待任务完成 |
| InvalidParameter.DomainTooLong | 域名过长 | 检查域名格式 |
| InvalidParameter.DomainTypeInvalid | 域名类型错误 | 检查域名 |
| InvalidParameterValue.DomainGradeInvalid | 域名等级不正确 | 检查等级参数 |
| InvalidParameterValue.DomainNotExists | 域名有误 | 重新输入正确的域名 |
| LimitExceeded.DomainAliasCountExceeded | 别名数量已达限制 | 无法继续添加别名 |
| LimitExceeded.TooManyInvalidDomains | 无效域名过多 | 正确配置 DNS 后重试 |
| OperationDenied.DomainOwnerAllowedOnly | 仅域名所有者可操作 | 使用所有者账号 |

### 记录相关错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| FailedOperation.DomainRecordExist | 记录已存在 | 无需重复添加 |
| FailedOperation.MustAddDefaultLineFirst | 请先添加默认线路的解析记录 | 先添加默认线路记录 |
| FailedOperation.DNSSECIncompleteClosed | DNSSEC 未完全关闭不允许添加 URL | 先关闭 DNSSEC |
| FailedOperation.DNSSECAddCnameError | DNSSEC 开启时不允许添加 URL | 先关闭 DNSSEC |
| FailedOperation.TencentCloudForbid | tencentyun.com 不允许新增子域名 | 使用其他域名 |
| InvalidParameter.SubdomainInvalid | 子域名不正确 | 检查子域名格式 |
| InvalidParameter.RecordTypeInvalid | 记录类型不正确 | 使用 DescribeRecordType 获取可用类型 |
| InvalidParameter.RecordLineInvalid | 记录线路不正确 | 使用 DescribeRecordLineList 获取可用线路 |
| InvalidParameter.RecordValueInvalid | 记录值不正确 | 检查记录值格式 |
| InvalidParameter.RecordValueLengthInvalid | 解析记录值过长 | 缩短记录值 |
| InvalidParameter.RecordIdInvalid | 记录编号错误 | 检查 RecordId 参数 |
| InvalidParameter.MxInvalid | MX 优先级不正确 | 范围 0-65535 |
| InvalidParameter.InvalidWeight | 权重不合法 | 范围 0-100 |
| InvalidParameter.UrlValueIllegal | URL 内容不符合 DNSPod 解析服务条款 | 修改 URL 内容 |
| LimitExceeded.AAAACountLimit | AAAA 记录数量超出限制 | 减少 AAAA 记录 |
| LimitExceeded.AtNsRecordLimit | @ 的 NS 记录只能设置为默认线路 | 使用默认线路 |
| LimitExceeded.NsCountLimit | NS 记录数量超出限制 | 减少 NS 记录 |
| LimitExceeded.RecordTtlLimit | 记录的 TTL 值超出限制 | 使用有效范围内的 TTL |
| LimitExceeded.SrvCountLimit | SRV 记录数量超出限制 | 减少 SRV 记录 |
| LimitExceeded.SubdomainLevelLimit | 子域名级数超出限制 | 减少子域名层级 |
| LimitExceeded.SubdomainRollLimit | 子域名负载均衡数量超出限制 | 减少负载均衡记录 |
| LimitExceeded.SubdomainWcardLimit | 泛解析级数超出限制 | 减少泛解析层级 |
| LimitExceeded.HiddenUrlExceeded | 套餐不支持隐性 URL 转发或数量已达上限 | 升级套餐 |
| LimitExceeded.UrlCountLimit | 显性 URL 转发数量已达上限 | 升级套餐 |
| OperationDenied.IPInBlacklistNotAllowed | 不允许添加黑名单中的 IP | 使用其他 IP |
| ResourceNotFound.NoDataOfRecord | 记录列表为空 | 检查域名和筛选条件 |

### 套餐相关错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| FailedOperation.InsufficientBalance | 账户余额不足 | 充值后重试 |
| FailedOperation.ContainsPersonalVip | 账户包含个人豪华域名不能直接升级 | 联系销售 |
| FailedOperation.AuthLogUnsupport | 当前套餐版本不支持流量分析 | 升级套餐 |
| InvalidParameter.NewPackageTypeInvalid | 新套餐类型无效 | 检查套餐类型 |
| InvalidParameter.TimeSpanInvalid | 时长无效 | 检查时长参数 |
| InvalidParameter.GoodsTypeInvalid | 商品类型无效 | 检查商品类型 |
| InvalidParameter.GoodsNumInvalid | 商品数量无效 | 检查数量参数 |
| LimitExceeded.CustomLineLimited | 自定义线路个数超过限制 | 购买更多自定义线路 |
| ResourcesSoldOut | 资源售罄 | 选择其他资源 |

### 订单相关错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| FailedOperation.OrderCanNotPay | 不能付款此订单 | 检查订单状态 |
| FailedOperation.OrderHasPaid | 订单已经付过款 | 检查订单 |
| FailedOperation.VerifyingBillExists | 域名已提交订单正在审核中 | 等待审核完成 |
| InvalidParameter.BillNumberInvalid | 订单号码不正确 | 检查订单号 |
| InvalidParameter.InvalidDealName | 订单号格式不正确 | 检查订单号 |
| InvalidParameter.IllegalNewDeal | 订单存在冲突或参数有误 | 重新购买 |
| OperationDenied.CancelBillNotAllowed | 此订单不能取消 | 检查订单状态 |
| InvalidParameter.DnsDealDomainUpgraded | 域名已升级无法完成下单 | 检查域名状态 |
| InvalidParameter.DnsDealLocked | 已有未完成订单 | 先完成原订单 |

### 权限相关错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| OperationDenied.AccessDenied | 没有权限执行此操作 | 申请权限 |
| OperationDenied.NoPermissionToOperateDomain | 当前域名无权限 | 返回域名列表 |
| OperationDenied.NotAdmin | 不是管理用户 | 使用管理账号 |
| OperationDenied.NotAgent | 不是代理用户 | 使用代理账号 |
| OperationDenied.NotManagedUser | 不是名下用户 | 使用名下账号 |
| OperationDenied.NotResourceOwner | 没有权限操作此资源 | 检查资源归属 |
| OperationDenied.NotOrderOwner | 没有权限操作此订单 | 使用订单所有者账号 |
| OperationDenied.VipDomainAllowed | 企业用户的域名需要升级到 VIP 才能解析 | 升级套餐 |

### 线路相关错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| InvalidParameter.LineFormatInvalid | 线路格式不正确 | 检查线路参数 |
| InvalidParameter.LineNameInvalid | 线路名称长度不能超过 17 个字符 | 缩短线路名称 |
| InvalidParameter.LineNameOccupied | 线路名已被使用 | 使用其他名称 |
| InvalidParameter.LineGroupNotSupported | 线路不存在或不支持分组 | 检查线路 |
| InvalidParameter.LineGroupOverCounted | 线路分组已达数量上限 | 删除部分分组 |
| InvalidParameter.LineOverCounted | 最多选择 120 个线路 | 减少线路数量 |
| InvalidParameter.LineNotSelected | 至少选择一个线路 | 选择线路 |
| InvalidParameter.LineInAnotherGroup | 线路已存在于其他分组中 | 移动或删除线路 |
| InvalidParameter.LineInUse | 线路正在使用无法修改 | 先移除使用记录 |
| InvalidParameter.DefaultLineNotSelfdefined | 默认线路无法进行自定义分组 | 使用其他线路 |
| InvalidParameter.CopiedLineGroupDuplicated | 复制的线路已存在 | 使用其他线路 |
| InvalidParameter.GroupNameEmpty | 分组名为空 | 输入分组名 |
| InvalidParameter.GroupNameExists | 同名分组已存在 | 使用其他名称 |
| InvalidParameter.GroupNameInvalid | 分组名为 1-17 个字符 | 调整分组名长度 |
| InvalidParameter.GroupNameOccupied | 分组名已被占用 | 使用其他名称 |
| InvalidParameter.IpAlreadyExist | IP 已存在 | 检查 IP 配置 |
| InvalidParameter.InvalidIp | IP 段格式不正确 | 检查 IP 格式 |
| InvalidParameter.IpArea | 线路不存在或已删除 | 检查线路 |
| OperationDenied.DeleteUsingRecordLineNotAllowed | 线路正在使用无法删除 | 先移除使用记录 |
| OperationDenied.EditUsingRecordLineNotAllowed | 线路正在使用无法编辑 | 先移除使用记录 |

### 操作限制错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| FailedOperation.FrequencyLimit | 操作过于频繁 | 稍后重试 |
| FailedOperation.UnknowError | 操作未响应 | 稍后重试 |
| FailedOperation.FunctionNotAllowedApply | 功能暂停申请 | 稍后重试 |
| InvalidParameter.OperateFailed | 操作失败 | 稍后重试 |
| InvalidParameter.OperationIsTooFrequent | 操作过于频繁 | 1 分钟后重试 |
| RequestLimitExceeded.BatchTaskLimit | IP 添加任务过多 | 每个小时最多 80 个任务 |
| RequestLimitExceeded.CreateDomainLimit | 短时间内添加大量域名 | 控制添加频率 |
| InvalidParameter.ActionSuccess | 操作已成功完成 | 无需处理 |
| InvalidParameter.ActionInvalid | 无效的操作 | 检查操作类型 |
| InvalidParameter.BatchTaskCountLimit | 超过单个账号批量任务数并发上限 4 个 | 等待任务完成 |
| InvalidParameter.BatchTaskNotExist | 任务不存在 | 检查任务 ID |
| InvalidParameter.BatchLimitUndo | 有批量任务未执行完成 | 等待任务完成 |

### 其他错误

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| FailedOperation.GetWhoisFailed | 获取不到域名信息 | 检查域名或稍后重试 |
| FailedOperation.FileNotExist | 文件不存在或未生成 | 等待文件生成 |
| InvalidParameter.EmailInvalid | 邮箱地址不正确 | 检查邮箱格式 |
| InvalidParameter.EmailNotVerified | 账户未通过邮箱验证 | 完成邮箱验证 |
| InvalidParameter.EmailSame | 域名已在该账号下 | 使用其他账号 |
| InvalidParameter.MobileNotVerified | 账户未通过手机验证 | 完成手机验证 |
| InvalidParameter.UserNotExists | 用户不存在 | 检查用户信息 |
| InvalidParameter.UserAreaInvalid | 对方账户非国内站用户 | 使用国内账号 |
| InvalidParameter.QcloudUinInvalid | 用户 UIN 无效 | 检查 UIN |
| InvalidParameter.TransferAccountIsBanned | 目标账号已被封禁 | 使用其他账号 |
| InvalidParameter.UserAlreadyLocked | 账号已被锁定 | 联系客服 |
| InvalidParameter.OtherAccountUnrealName | 对方账号未实名认证 | 对方完成实名认证 |
| InvalidParameter.SharedUsersUnrealName | 共享用户包含未实名用户 | 移除未实名用户 |
| InvalidParameter.RemarkTooLong | 备注过长 | 缩短备注 |
| InvalidParameter.ShareUserExists | 共享记录已存在 | 检查共享设置 |
| InvalidParameter.UnLockCodeExpired | 解锁代码已失效 | 重新获取解锁代码 |
| InvalidParameter.UnLockCodeInvalid | 解锁代码不正确 | 检查解锁代码 |
| InvalidParameter.AcquireHashExists | 域名正在取回中 | 等待取回完成 |
| InvalidParameter.PtrInvalidPublicIp | 无效的 IP 地址 | 检查 IP |
| InvalidParameter.PtrIpNotOwner | 不是该 IP 的所有者 | 使用自己的 IP |
| InvalidParameter.ResultMoreThan500 | 搜索结果大于 500 条 | 增加关键字 |
| InvalidParameter.OffsetInvalid | 分页起始数量错误 | 检查 Offset 参数 |
| InvalidParameter.NoAuthorityToSrcDomain | 不是源域名所有者 | 使用域名所有者账号 |
| InvalidParameter.NoAuthorityToTheGroup | 分组不属于当前域名 | 检查分组归属 |
| InvalidParameter.QuhuiTxtNotMatch | TXT 记录无法匹配 | 确认记录值 |
| InvalidParameter.QuhuiTxtRecordWait | TXT 记录未设置或未生效 | 稍后重试 |
| OperationDenied.MonitorCallbackNotEnabled | 域名等级不支持 D 监控通知回调 | 升级套餐 |
| OperationDenied.PersonalCouponNotAllowed | 此礼券为个人礼券 | 使用企业礼券 |
| OperationDenied.ResourceAlreadyBind | 资源已绑定 | 解除绑定后重试 |
| OperationDenied.ResourceNotAllowRenew | 资源不允许续费 | 检查资源状态 |
| OperationDenied.ResourceAlreadyBind | 资源已绑定 | 解除绑定后重试 |
| ResourceNotFound.NoDataOfDomain | 域名列表为空 | 添加域名 |
| ResourceNotFound.NoDataOfDomainAlias | 没有域名别名 | 添加别名 |
| ResourceNotFound.NoDataOfGift | 还没有礼券 | 领取礼券 |
| InvalidParameterValue.LimitInvalid | 分页长度数量错误 | 检查 Limit 参数 |
| InvalidParameterValue.UserIdInvalid | 用户编号不正确 | 检查用户 ID |