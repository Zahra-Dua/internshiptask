// lib/services/audit_log_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_model.dart';

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection('auditLogs');

  Future<void> logAction(AuditLogModel log) async {
    await _logs.add(log.toFirestore());
  }

  Stream<List<AuditLogModel>> getAllLogs({int limit = 100}) {
    return _logs
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => AuditLogModel.fromFirestore(d)).toList());
  }

  Stream<List<AuditLogModel>> getLogsForEntity(
    String entityType,
    String entityId,
  ) {
    return _logs
        .where('entityType', isEqualTo: entityType)
        .where('entityId', isEqualTo: entityId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AuditLogModel.fromFirestore(d)).toList());
  }
}
