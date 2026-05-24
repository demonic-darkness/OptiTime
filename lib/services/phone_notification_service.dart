// lib/services/phone_notification_service.dart

import 'package:flutter/services.dart';

class PhoneNotificationService {
  static const MethodChannel _channel =
      MethodChannel('optitime/notifications');

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'id': id,
        'title': title,
        'body': body,
      });
    } on PlatformException {
      // Android nativo puede no estar disponible en todas las plataformas.
    } on MissingPluginException {
      // En web/iOS/escritorio solo se guarda el historial interno.
    }
  }
}
