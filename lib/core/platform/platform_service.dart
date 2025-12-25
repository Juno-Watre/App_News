import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('personal_news_brief/platform');

  // 在浏览器中打开URL
  static Future<void> openUrl(String url) async {
    try {
      await _channel.invokeMethod('openUrl', {'url': url});
    } on PlatformException catch (e) {
      debugPrint('打开URL失败: ${e.message}');
      rethrow;
    }
  }

  // 分享文本
  static Future<void> shareText(String title, String text) async {
    try {
      await _channel.invokeMethod('shareText', {
        'title': title,
        'text': text,
      });
    } on PlatformException catch (e) {
      debugPrint('分享失败: ${e.message}');
      rethrow;
    }
  }

  // 检查是否有应用可以处理URL
  static Future<bool> canOpenUrl(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('canOpenUrl', {'url': url});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('检查URL处理能力失败: ${e.message}');
      return false;
    }
  }

  // 获取应用版本信息
  static Future<Map<String, String>> getAppInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<String, dynamic>>('getAppInfo');
      return Map<String, String>.from(result ?? {});
    } on PlatformException catch (e) {
      debugPrint('获取应用信息失败: ${e.message}');
      return {};
    }
  }

  // 创建桌面快捷方式（仅Android）
  static Future<void> createShortcut(String id, String shortLabel, String longLabel) async {
    try {
      await _channel.invokeMethod('createShortcut', {
        'id': id,
        'shortLabel': shortLabel,
        'longLabel': longLabel,
      });
    } on PlatformException catch (e) {
      debugPrint('创建快捷方式失败: ${e.message}');
      rethrow;
    }
  }

  // 检查通知权限
  static Future<bool> hasNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasNotificationPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('检查通知权限失败: ${e.message}');
      return false;
    }
  }

  // 请求通知权限
  static Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('请求通知权限失败: ${e.message}');
      return false;
    }
  }

  // 显示通知
  static Future<void> showNotification(
    int id,
    String title,
    String content, {
    String? payload,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'id': id,
        'title': title,
        'content': content,
        'payload': payload,
      });
    } on PlatformException catch (e) {
      debugPrint('显示通知失败: ${e.message}');
      rethrow;
    }
  }

  // 获取设备信息
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<String, dynamic>>('getDeviceInfo');
      return Map<String, String>.from(result ?? {});
    } on PlatformException catch (e) {
      debugPrint('获取设备信息失败: ${e.message}');
      return {};
    }
  }

  // 检查网络连接状态
  static Future<bool> isNetworkConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>('isNetworkConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('检查网络连接失败: ${e.message}');
      return true; // 默认假设有网络连接
    }
  }
}