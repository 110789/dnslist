# 项目架构隔离规范 (v1.0)

## 一、架构分层概述

项目采用三层架构设计，严格遵循单向依赖原则：

```
┌─────────────────────────────────────────────────────┐
│              通用工具层 (Utils)                     │
│  - 网络请求 (ApiClient)                              │
│  - 存储管理 (Storage)                               │
│  - 通用工具 (Utils)                                 │
│  仅提供无状态全局能力，不依赖其他层                  │
└─────────────────────────────────────────────────────┘
                        ↑
┌─────────────────────────────────────────────────────┐
│              核心框架层 (Core)                       │
│  - 路由导航 (Router)                                │
│  - 状态管理 (State)                                 │
│  - 服务抽象 (Service Registry)                       │
│  - UI组件 (UI Widgets)                               │
│  - 主题系统 (Theme)                                  │
│  - 配置管理 (Config)                                 │
│  - 刷新核心 (Refresh Core)                          │
│  不包含服务商逻辑，仅定义抽象接口                     │
└─────────────────────────────────────────────────────┘
                        ↑
┌─────────────────────────────────────────────────────┐
│              服务商驱动层 (Drivers)                  │
│  - CloudflareDriver                                 │
│  - DnsheDriver                                      │
│  - DnspodDriver                                     │
│  - ClouDNSDriver                                    │
│  - RainyunDriver                                    │
│  基于框架层抽象接口实现，完全独立、互不依赖           │
└─────────────────────────────────────────────────────┘
                        ↑
┌─────────────────────────────────────────────────────┐
│              业务服务层 (Services)                  │
│  - CredentialState (凭证状态管理)                   │
│  - NewDomainState (域名状态管理)                    │
│  - CredentialStorage (凭证存储)                      │
│  连接框架层与驱动层，协调业务逻辑                     │
└─────────────────────────────────────────────────────┘
```

## 二、各层职责边界

### 2.1 核心框架层 (Core)

**职责**：
- 全局状态管理 (State Provider, Theme Provider)
- 路由导航 (AppRouter)
- 服务抽象接口定义 (ServiceRegistry)
- UI基础组件 (MD3 Widgets, Adaptive Widgets)
- 主题设计系统 (Design System)
- 刷新核心逻辑 (Refresh Core)
- 全局配置 (AppConfig)

**禁止行为**：
- ❌ 直接引入服务商驱动
- ❌ 包含业务逻辑硬编码
- ❌ 调用工具层具体实现

**允许行为**：
- ✅ 定义抽象接口 (abstract class)
- ✅ 提供通用UI组件
- ✅ 实现框架层内部逻辑

### 2.2 服务商驱动层 (Drivers)

**职责**：
- 实现 `DriverInterface` 抽象接口
- 处理各服务商的API调用、数据解析、错误处理
- 构建服务商专属的UI元素
- 管理服务端点配置

**禁止行为**：
- ❌ 直接引用 `core/config/app_config.dart` 中的具体URL
- ❌ 直接引用 `core/theme/design_system.dart` 中的设计令牌
- ❌ 直接引用 `core/ui/md3_widgets.dart` 中的UI组件
- ❌ 依赖其他驱动实现

**允许行为**：
- ✅ 通过框架层抽象接口获取服务
- ✅ 定义驱动内部常量
- ✅ 使用纯Dart逻辑构建UI

### 2.3 通用工具层 (Utils)

**职责**：
- HTTP客户端封装 (ApiClient)
- 本地存储抽象 (Storage)
- 通用数据处理 (加密、格式化、校验)
- 驱动工具函数 (错误解析、常量定义)

**禁止行为**：
- ❌ 包含任何业务逻辑
- ❌ 依赖框架层具体实现
- ❌ 依赖驱动层代码
- ❌ 反向调用框架或驱动

**允许行为**：
- ✅ 提供无状态工具方法
- ✅ 封装第三方库调用
- ✅ 定义通用数据类型

### 2.4 业务服务层 (Services)

**职责**：
- 凭证状态管理 (CredentialState)
- 域名/DNS记录状态管理 (NewDomainState)
- 凭证持久化存储 (CredentialStorage)

**禁止行为**：
- ❌ 直接实例化驱动
- ❌ 包含UI渲染逻辑
- ❌ 处理服务商专属逻辑

**允许行为**：
- ✅ 通过 DriverFactory 获取驱动实例
- ✅ 管理业务数据状态
- ✅ 处理数据持久化

## 三、依赖关系规范

### 3.1 允许的依赖方向

```
Utils → Core → Services → Drivers
         ↓
       Pages
```

### 3.2 禁止的依赖方向

- ❌ Drivers → Core (具体实现)
- ❌ Core → Drivers
- ❌ Utils → Drivers
- ❌ Services → Utils (具体实现)
- ❌ 任何层之间的循环依赖

### 3.3 接口抽象原则

所有跨层交互必须通过抽象接口：

```dart
// 框架层定义抽象
abstract class NetworkService {
  Future<Map<String, dynamic>> get(String url, {Map<String, dynamic>? queryParameters});
  Future<Map<String, dynamic>> post(String url, {dynamic data});
}

// 工具层提供实现
class ApiClient implements NetworkService { ... }

// 驱动层使用抽象
class CloudflareDriver implements DriverInterface {
  void someMethod() {
    final networkService = ServiceRegistry.instance.networkService;
    // 使用抽象接口，不直接依赖ApiClient
  }
}
```

## 四、目录结构规范

```
lib/
├── core/                          # 核心框架层
│   ├── config/                    # 全局配置
│   │   └── app_config.dart
│   ├── router/                    # 路由导航
│   │   └── app_router.dart
│   ├── services/                  # 服务抽象
│   │   ├── service_registry.dart  # 服务注册器
│   │   └── framework_services_impl.dart
│   ├── state/                     # 状态管理
│   │   ├── state_provider.dart
│   │   ├── base_state.dart
│   │   └── theme_provider.dart
│   ├── refresh/                   # 刷新核心
│   │   ├── refresh_core.dart
│   │   └── refresh_helper.dart
│   ├── theme/                     # 主题系统
│   │   ├── app_theme.dart
│   │   ├── app_design_system.dart
│   │   └── design_system.dart
│   └── ui/                        # UI组件
│       ├── md3_widgets.dart
│       └── adaptive_widgets.dart
│
├── drivers/                       # 服务商驱动层
│   ├── interfaces/                # 驱动抽象接口
│   │   └── driver_interface.dart
│   ├── cloudflare/
│   │   └── cloudflare_driver.dart
│   ├── dnshe/
│   │   └── dnshe_driver.dart
│   ├── dnspod/
│   │   ├── dnspod_driver.dart
│   │   └── dnspod_signer.dart
│   ├── cloudns/
│   │   └── cloudns_driver.dart
│   ├── rainyun/
│   │   └── rainyun_driver.dart
│   ├── driver_factory.dart
│   ├── driver_manager.dart
│   ├── driver_registry.dart
│   └── drivers.dart
│
├── utils/                         # 通用工具层
│   ├── network/                   # 网络工具
│   │   ├── api_client.dart
│   │   └── network.dart
│   ├── storage/                  # 存储工具
│   │   ├── local_storage.dart
│   │   └── storage.dart
│   ├── driver/                   # 驱动工具
│   │   └── driver_utils.dart
│   └── toast_util.dart
│
├── services/                     # 业务服务层
│   ├── credential_state.dart
│   ├── credential_storage.dart
│   ├── credential_validation.dart
│   ├── new_domain_state.dart
│   └── services.dart
│
├── models/                       # 数据模型
│   ├── credential_model.dart
│   └── models.dart
│
├── pages/                        # 页面层
│   ├── home/
│   │   └── home_page.dart
│   ├── domains/
│   │   └── dns_records_page.dart
│   └── settings/
│       └── settings_page.dart
│
└── main.dart                     # 应用入口
```

## 五、驱动接口规范

### 5.1 DriverInterface 抽象接口

所有服务商驱动必须实现以下接口：

```dart
abstract class DriverInterface {
  // 提供者标识
  String get providerId;
  String get providerName;
  String get providerIcon;

  // 凭证验证
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials);

  // 域名操作
  Future<Map<String, dynamic>> getDomains({int page, int pageSize, Map<String, String>? filters});
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData);
  Future<Map<String, dynamic>> deleteDomain(String domainId);
  Future<Map<String, dynamic>> renewDomain(String domainId);

  // DNS记录操作
  Future<Map<String, dynamic>> getDnsRecords(String domainId, {int page, int pageSize, Map<String, String>? filters});
  Future<Map<String, dynamic>> createDnsRecord(String domainId, Map<String, dynamic> recordData);
  Future<Map<String, dynamic>> updateDnsRecord(String domainId, String recordId, Map<String, dynamic> recordData);
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId);

  // 功能支持
  bool get supportsAddDomain;
  bool get supportsDeleteDomain;
  bool get supportsRenewDomain;
  bool get supportsShowNameServers;

  // UI构建
  Widget buildDomainListItem(...);
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData);
  void showDomainListItemMenu(...);

  // 配置信息
  Map<String, String> getCredentialFields();
  List<String> getSupportedRecordTypes();
  String mapErrorCode(String code);
  String getAddDomainTitle();
  List<AddDomainField> getAddDomainFields();
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input);
}
```

### 5.2 驱动内部实现约束

驱动内部不得直接使用框架层具体实现：

```dart
// ❌ 错误 - 直接依赖框架
import '../../core/config/app_config.dart';
import '../../core/theme/design_system.dart';
import '../../core/ui/md3_widgets.dart';

// ✅ 正确 - 仅依赖抽象接口和工具层
import '../interfaces/driver_interface.dart';
import '../../utils/network/api_client.dart';
import '../../utils/driver/driver_utils.dart';
```

## 六、服务注册规范

### 6.1 ServiceRegistry 抽象定义

框架层定义抽象服务接口，业务层通过抽象使用：

```dart
abstract class NetworkService {
  String getBaseUrl(String providerId);
  Future<Map<String, dynamic>> get(String url, {Map<String, dynamic>? queryParameters, Map<String, String>? headers});
  Future<Map<String, dynamic>> post(String url, {dynamic data, Map<String, String>? headers});
  Future<Map<String, dynamic>> put(String url, {dynamic data, Map<String, String>? headers});
  Future<Map<String, dynamic>> delete(String url, {Map<String, String>? headers});
}

abstract class StorageService {
  Future<void> set(String key, dynamic value);
  Future<dynamic> get(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

abstract class ThemeService {
  Color getDnsTypeColor(String type);
  Color getStatusColor(String status);
  Color get successColor;
  // ... 更多抽象方法
}
```

### 6.2 服务初始化

```dart
void main() async {
  // 初始化服务注册表
  final localStorage = LocalStorage.instance;
  await localStorage.init();

  ServiceRegistry.instance.initialize(
    config: FrameworkConfig(...),
    themeService: ThemeServiceImpl(),
    networkService: NetworkServiceImpl(),
    storageService: StorageServiceImpl(localStorage),
  );

  // 初始化驱动注册表
  await DriverRegistry.initialize();
}
```

## 七、违规检测与修复

### 7.1 常见违规模式

1. **驱动层引用框架具体实现**
   ```dart
   // ❌ 违规
   import '../../core/config/app_config.dart';
   static const String _baseUrl = AppConfig.cloudflareBaseUrl;

   // ✅ 修复
   static const String _baseUrl = 'https://api.cloudflare.com/client/v4';
   ```

2. **驱动层引用框架UI组件**
   ```dart
   // ❌ 违规
   import '../../core/ui/md3_widgets.dart';
   DnsTtlTag(ttl: ttl)

   // ✅ 修复 - 在驱动内部实现UI构建逻辑
   _buildTtlTag(ttl)
   ```

3. **驱动层引用框架设计令牌**
   ```dart
   // ❌ 违规
   import '../../core/theme/design_system.dart';
   color: DnsDesignTokens.dnsTypeA

   // ✅ 修复 - 在驱动内部定义常量
   static const Color _typeColorA = Color(0xFF3B82F6);
   ```

4. **核心框架层引用驱动**
   ```dart
   // ❌ 违规
   import '../../drivers/driver_factory.dart';

   // ✅ 修复 - 使用抽象接口或延迟获取
   ```

### 7.2 架构隔离检查清单

- [ ] 驱动层未直接引用 `core/config/app_config.dart`
- [ ] 驱动层未直接引用 `core/theme/design_system.dart`
- [ ] 驱动层未直接引用 `core/ui/md3_widgets.dart`
- [ ] 核心框架层未直接引用任何驱动
- [ ] 工具层未包含业务逻辑
- [ ] 所有跨层调用通过抽象接口
- [ ] 无循环依赖
- [ ] 目录结构符合分层规范

## 八、扩展指南

### 8.1 新增服务商驱动

1. 在 `lib/drivers/{provider}/` 创建驱动文件
2. 实现 `DriverInterface` 抽象接口
3. 在 `driver_registry.dart` 注册驱动
4. 确保驱动内部不引用框架具体实现

### 8.2 新增工具方法

1. 在 `lib/utils/` 对应子目录创建文件
2. 确保方法无状态、通用化
3. 不包含任何业务逻辑
4. 工具层可被其他层单向依赖

### 8.3 新增框架服务

1. 在 `core/services/` 定义抽象接口
2. 在 `core/services/framework_services_impl.dart` 实现
3. 在 `ServiceRegistry` 中注册
4. 不包含任何服务商专属逻辑

## 九、版本历史

| 版本 | 日期 | 描述 |
|------|------|------|
| v1.0 | 2026-05-12 | 初始架构隔离规范 |

## 十、违规举报

如发现违反本规范的代码，请标记并通知架构负责人修复。