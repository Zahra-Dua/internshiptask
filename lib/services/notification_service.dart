// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Future<void> createNotification(NotificationModel notification) async {
    await _notifications.add(notification.toFirestore());
  }

  Stream<List<NotificationModel>> getRecentNotifications({int limit = 30}) {
    return _notifications
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => NotificationModel.fromFirestore(d)).toList(),
        );
  }
}
