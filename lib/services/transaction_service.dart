import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');

  Future<String> addTransaction(TransactionModel transaction) async {
    final doc = await _transactions.add(transaction.toFirestore());

    return doc.id;
  }

  Future<TransactionModel?> getTransaction(String transactionId) async {
    final doc = await _transactions.doc(transactionId).get();

    if (!doc.exists) {
      return null;
    }

    return TransactionModel.fromFirestore(doc);
  }

  Stream<List<TransactionModel>> getAllTransactions() {
    return _transactions
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _transactions
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }
}
