import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_model.dart';

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection('auditLogs');

  Future<String> addLog(AuditLogModel log) async {
    final doc = await _logs.add(log.toFirestore());

    return doc.id;
  }

  Stream<List<AuditLogModel>> getLogs() {
    return _logs
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<AuditLogModel>> getUserLogs(String userId) {
    return _logs
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogModel.fromFirestore(doc))
              .toList(),
        );
  }
}
