import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ToastUtil {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static void show({
    required BuildContext context,
    required String message,
    bool isSuccess = true,
    int duration = 2500,
    double? errorCode,
  }) {
    if (_isShowing && _overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    }

    final overlayState = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 50;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSuccess 
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.95)
                    : const Color(0xFFF44336).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  if (errorCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '状态码: ${errorCode.toInt()}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _isShowing = true;
    overlayState.insert(_overlayEntry!);

    Future.delayed(Duration(milliseconds: duration), () {
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isShowing = false;
      }
    });
  }

  static void showSuccess(BuildContext context, String message, {double? errorCode}) {
    show(context: context, message: message, isSuccess: true, errorCode: errorCode);
  }

  static void showError(BuildContext context, String message, {double? errorCode}) {
    HapticFeedback.mediumImpact();
    show(context: context, message: message, isSuccess: false, errorCode: errorCode);
  }
}