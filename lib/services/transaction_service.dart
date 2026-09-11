// lib/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');

  Future<void> logTransaction(TransactionModel transaction) async {
    await _transactions.add(transaction.toFirestore());
  }

  // Sab transactions, sabse naye pehle
  Stream<List<TransactionModel>> getAllTransactions({int limit = 50}) {
    return _transactions
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => TransactionModel.fromFirestore(d)).toList(),
        );
  }

  // Ek component ki history
  Stream<List<TransactionModel>> getTransactionsForComponent(
    String componentId, {
    int limit = 20,
  }) {
    return _transactions
        .where('componentId', isEqualTo: componentId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => TransactionModel.fromFirestore(d)).toList(),
        );
  }

  // Ek specific user (Lab Staff) ki apni history
  Stream<List<TransactionModel>> getTransactionsForUser(
    String userId, {
    int limit = 50,
  }) {
    return _transactions
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => TransactionModel.fromFirestore(d)).toList(),
        );
  }

  // Ye method existing TransactionService class ke andar add karo:

  Future<int> cleanupOrphanedTransactions() async {
    final txnSnapshot = await _transactions.get();
    final componentsSnapshot = await _firestore.collection('components').get();

    final validComponentIds = componentsSnapshot.docs.map((d) => d.id).toSet();

    final orphanedDocs = txnSnapshot.docs
        .where((doc) => !validComponentIds.contains(doc.data()['componentId']))
        .toList();

    if (orphanedDocs.isEmpty) return 0;

    final batch = _firestore.batch();
    for (var doc in orphanedDocs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    return orphanedDocs.length;
  }
}
