import 'dart:developer';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:naengjang/core/ingredient/ingredient_state.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// 알림 서비스 초기화
  Future<void> init() async {
    if (_isInitialized) return;

    // 지원하지 않는 플랫폼 체크
    if (!Platform.isIOS && !Platform.isAndroid) {
      log('Notifications not supported on this platform', name: 'NotificationService');
      return;
    }

    try {
      // 타임존 초기화
      tz.initializeTimeZones();
      try {
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        // 시뮬레이터 등에서 타임존을 가져올 수 없는 경우 기본값 사용
        log('Failed to get local timezone, using Asia/Seoul: $e', name: 'NotificationService');
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      }

      // Android 설정
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 설정
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      _isInitialized = true;
      log('NotificationService initialized', name: 'NotificationService');
    } catch (e) {
      log('NotificationService init failed: $e', name: 'NotificationService');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    log('Notification tapped: ${response.payload}', name: 'NotificationService');
    // TODO: 알림 탭 시 해당 재료 상세 페이지로 이동
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    if (!_isInitialized) return false;

    try {
      if (Platform.isIOS) {
        final result = await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? false;
      } else if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final result = await android?.requestNotificationsPermission();
        return result ?? false;
      }
    } catch (e) {
      log('requestPermission failed: $e', name: 'NotificationService');
    }
    return false;
  }

  /// 재료의 만료 알림 예약 (3일 전, 1일 전)
  Future<void> scheduleExpiryNotifications(Ingredient ingredient) async {
    if (!_isInitialized) return;

    final expiryDate = ingredient.expiryDate ?? ingredient.useByDate;
    if (expiryDate == null) return;

    // 기존 알림 취소
    await cancelNotifications(ingredient.id);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    // 3일 전 알림
    final threeDaysBefore = expiry.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(today)) {
      await _scheduleNotification(
        id: _generateNotificationId(ingredient.id, 3),
        title: '소비기한 임박 알림',
        body: '${ingredient.name}의 소비기한이 3일 남았습니다.',
        scheduledDate: threeDaysBefore.add(const Duration(hours: 9)), // 오전 9시
        payload: ingredient.id,
      );
    }

    // 1일 전 알림
    final oneDayBefore = expiry.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(today)) {
      await _scheduleNotification(
        id: _generateNotificationId(ingredient.id, 1),
        title: '소비기한 임박 알림',
        body: '${ingredient.name}의 소비기한이 내일입니다!',
        scheduledDate: oneDayBefore.add(const Duration(hours: 9)), // 오전 9시
        payload: ingredient.id,
      );
    }

    // 당일 알림
    if (expiry.isAfter(today) || expiry.isAtSameMomentAs(today)) {
      final expiryNotificationTime = expiry.add(const Duration(hours: 9));
      if (expiryNotificationTime.isAfter(now)) {
        await _scheduleNotification(
          id: _generateNotificationId(ingredient.id, 0),
          title: '소비기한 만료',
          body: '${ingredient.name}의 소비기한이 오늘입니다!',
          scheduledDate: expiryNotificationTime,
          payload: ingredient.id,
        );
      }
    }

    log('Scheduled notifications for ${ingredient.name}', name: 'NotificationService');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      '소비기한 알림',
      channelDescription: '재료 소비기한 만료 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    log('Notification scheduled: $title at $scheduledDate (id: $id)', name: 'NotificationService');
  }

  /// 재료의 알림 취소
  Future<void> cancelNotifications(String ingredientId) async {
    if (!_isInitialized) return;

    // 3일 전, 1일 전, 당일 알림 모두 취소
    await _plugin.cancel(_generateNotificationId(ingredientId, 3));
    await _plugin.cancel(_generateNotificationId(ingredientId, 1));
    await _plugin.cancel(_generateNotificationId(ingredientId, 0));
    log('Cancelled notifications for $ingredientId', name: 'NotificationService');
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    await _plugin.cancelAll();
    log('All notifications cancelled', name: 'NotificationService');
  }

  /// 모든 재료에 대해 알림 재설정
  Future<void> rescheduleAllNotifications(List<Ingredient> ingredients) async {
    if (!_isInitialized) return;

    await cancelAllNotifications();

    for (final ingredient in ingredients) {
      await scheduleExpiryNotifications(ingredient);
    }

    log('Rescheduled notifications for ${ingredients.length} ingredients', name: 'NotificationService');
  }

  /// 재료 ID와 일수로 고유한 알림 ID 생성
  int _generateNotificationId(String ingredientId, int daysBefore) {
    // UUID를 정수로 변환 (해시코드 사용)
    final baseId = ingredientId.hashCode.abs() % 100000000;
    return baseId * 10 + daysBefore;
  }
}
