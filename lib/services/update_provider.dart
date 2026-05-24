import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../models/release_info.dart';
import 'update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  available,
  noUpdate,
  downloading,
  downloaded,
  error,
}

class UpdateProvider extends ChangeNotifier {
  final UpdateService _service;

  UpdateStatus _status = UpdateStatus.idle;
  ReleaseInfo? _releaseInfo;
  String? _downloadedFilePath;
  String _errorMessage = '';
  double _progress = 0;

  UpdateProvider({UpdateService? service})
      : _service = service ?? UpdateService();

  UpdateStatus get status => _status;
  ReleaseInfo? get releaseInfo => _releaseInfo;
  String get errorMessage => _errorMessage;
  double get progress => _progress;
  String get currentVersion => AppConfig.appVersion;
  bool get isChecking => _status == UpdateStatus.checking;
  bool get isDownloading => _status == UpdateStatus.downloading;
  bool get hasUpdate => _status == UpdateStatus.available;

  Future<void> checkForUpdate() async {
    _status = UpdateStatus.checking;
    _errorMessage = '';
    _releaseInfo = null;
    notifyListeners();

    final release = await _service.checkForUpdate();

    if (release != null) {
      _releaseInfo = release;
      _status = UpdateStatus.available;
    } else {
      _status = UpdateStatus.noUpdate;
    }
    notifyListeners();
  }

  Future<void> downloadUpdate() async {
    if (_releaseInfo == null) return;

    final asset = _service.getPlatformAsset(_releaseInfo!);
    if (asset == null) {
      _status = UpdateStatus.error;
      _errorMessage = 'No suitable download found for this platform';
      notifyListeners();
      return;
    }

    _status = UpdateStatus.downloading;
    _progress = 0;
    _downloadedFilePath = null;
    notifyListeners();

    try {
      final filePath = await _service.downloadRelease(
        asset,
        onProgress: (received, total) {
          if (total > 0) {
            _progress = received / total;
          }
          notifyListeners();
        },
      );
      _downloadedFilePath = filePath;
      _progress = 1.0;
      _status = UpdateStatus.downloaded;
      notifyListeners();
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> installUpdate() async {
    if (_downloadedFilePath == null) return false;

    final success = await _service.openFile(_downloadedFilePath!);
    if (success) {
      reset();
    }
    return success;
  }

  void cancelDownload() {
    _service.cancelDownload();
    _status = UpdateStatus.idle;
    _progress = 0;
    notifyListeners();
  }

  void openReleasePage() {
    _service.openReleasePage();
  }

  void reset() {
    _status = UpdateStatus.idle;
    _releaseInfo = null;
    _downloadedFilePath = null;
    _errorMessage = '';
    _progress = 0;
    notifyListeners();
  }
}
