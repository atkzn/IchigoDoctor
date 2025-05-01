// lib/notification_service.dart

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {

  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  //static final _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'reminder_channel', 'リマインダー通知',
    description: '水やり・追肥等のお知らせ',
    importance: Importance.high,
  );

  /// 1) 初期化: local + FCM
  static Future init() async {
    // タイムゾーン初期化
    tz_data.initializeTimeZones();

    // local 通知初期化
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {},
    );
    // チャンネル作成 (Android)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // FCM 通知初期化
    final fm = FirebaseMessaging.instance;
    await fm.requestPermission(
      alert: true, badge: true, sound: true, announcement: false,
    );
    // トピック購読（任意）
    await fm.subscribeToTopic('reminders');

    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) {
        showLocal(n.title, n.body);
      }
    });
  }

  /// 2) FCM 受信を local 通知で表示
  static Future showLocal(String? title, String? body) =>
      _flutterLocalNotificationsPlugin.show(
        0, title, body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id, _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );

  /// 3) 毎日同じ時刻にローカル通知をスケジュール
  static Future scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int id,
  }) =>
      _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstance(hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id, _channel.name,
            channelDescription: _channel.description,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day,
        hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }


  /// 任意日時に 1 回だけ通知
  static Future<void> schedule({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('care', 'Care'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }



}
