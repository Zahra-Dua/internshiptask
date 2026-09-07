import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String id;
  final String name;
  final String type;
  final String? parentId;
  final String locationCode;
  final bool isActive;
  final DateTime? createdAt;

  LocationModel({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    required this.locationCode,
    required this.isActive,
    this.createdAt,
  });

  factory LocationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return LocationModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      parentId: data['parentId'],
      locationCode: data['locationCode'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'parentId': parentId,
      'locationCode': locationCode,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}