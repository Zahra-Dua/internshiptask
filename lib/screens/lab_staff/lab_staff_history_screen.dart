// lib/screens/lab_staff/lab_staff_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class LabStaffHistoryScreen extends StatelessWidget {
  const LabStaffHistoryScreen({super.key});

  static const Color primaryColor = Color(0xFF6C63FF);

  Color _colorFor(TransactionType t) {
    switch (t) {
      case TransactionType.issue:
        return Colors.orange;
      case TransactionType.returned:
        return Colors.green;
      case TransactionType.restock:
        return Colors.blue;
      case TransactionType.damage:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.purple;
    }
  }

  IconData _iconFor(TransactionType t) {
    switch (t) {
      case TransactionType.issue:
        return Icons.arrow_upward;
      case TransactionType.returned:
        return Icons.arrow_downward;
      case TransactionType.restock:
        return Icons.add_box_outlined;
      case TransactionType.damage:
        return Icons.warning_amber;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';

    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }

    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userModel?.id;
    final service = TransactionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('My History'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<TransactionModel>>(
              stream: service.getTransactionsForUser(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final txns = snapshot.data ?? [];

                if (txns.isEmpty) {
                  return const Center(
                    child: Text(
                      'You haven\'t made any transactions yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: txns.length,
                  itemBuilder: (context, index) {
                    final t = txns[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _colorFor(t.type).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconFor(t.type),
                              color: _colorFor(t.type),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t.quantity} × ${t.componentName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),

                                Text(
                                  '${t.locationCode} • ${_timeAgo(t.timestamp)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),

                                // Notes / Purpose
                                if (t.notes != null && t.notes!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '"${t.notes}"',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Text(
                            TransactionModel.typeToString(t.type).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _colorFor(t.type),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
