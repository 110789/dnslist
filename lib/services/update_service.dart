import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../models/release_info.dart';
import '../utils/log/log.dart';

class UpdateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/${AppConfig.githubRepo}/releases/latest';

  final Dio _dio;
  CancelToken? _cancelToken;

  UpdateService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'Dlist/${AppConfig.appVersion}',
          },
        ));

  Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(_githubApiUrl);
      if (response.statusCode != 200) return null;

      final release = ReleaseInfo.fromJson(response.data as Map<String, dynamic>);
      final compareResult = ReleaseInfo.compareVersion(
        release.version,
        AppConfig.appVersion,
      );

      if (compareResult > 0) return release;
      return null;
    } catch (e, stack) {
      LogService.instance.error(
        module: 'update',
        className: 'UpdateService',
        methodName: 'checkForUpdate',
        action: '检查更新失败',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
      return null;
    }
  }

  ReleaseAsset? getPlatformAsset(ReleaseInfo release) {
    if (Platform.isAndroid) {
      final apks = release.assets.where((a) => a.name.endsWith('.apk'));
      return apks.isNotEmpty ? apks.first : null;
    }
    if (Platform.isWindows) {
      final installers = release.assets.where(
        (a) => a.name.endsWith('.zip') || a.name.endsWith('.msi') || a.name.endsWith('.exe'),
      );
      return installers.isNotEmpty ? installers.first : null;
    }
    return null;
  }

  Future<String> downloadRelease(
    ReleaseAsset asset, {
    required void Function(int received, int total) onProgress,
  }) async {
    _cancelToken = CancelToken();
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/${asset.name}';

    await _dio.download(
      asset.downloadUrl,
      savePath,
      cancelToken: _cancelToken,
      onReceiveProgress: (received, total) {
        onProgress(received, total);
      },
    );

    return savePath;
  }

  void cancelDownload() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  Future<bool> openFile(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final result = await OpenFilex.open(filePath);
        return result.type == ResultType.done;
      } else if (Platform.isWindows) {
        await Process.run(filePath, []);
        return true;
      }
      return false;
    } catch (e, stack) {
      LogService.instance.error(
        module: 'update',
        className: 'UpdateService',
        methodName: 'openFile',
        action: '打开安装文件失败',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
      return false;
    }
  }

  Future<void> openReleasePage() async {
    final uri = Uri.parse('${AppConfig.repoUrl}/releases');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
