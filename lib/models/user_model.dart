import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String employeeId;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  // Firestore → Dart Object
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      employeeId: data['employeeId'] ?? '',
      role: data['role'] ?? 'lab_staff',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Dart Object → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'employeeId': employeeId,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // 👇 ye naya add karna hai
  bool get isAdmin => role == 'admin';
  bool get isLabStaff => role == 'lab_staff';
}
