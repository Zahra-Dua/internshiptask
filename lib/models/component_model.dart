// lib/models/component_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ComponentModel {
  final String id;
  final String name;
  final String componentCode;
  final String type;
  final String manufacturer;
  final String partNumber;
  final String abcdClass;
  final String description;
  final int minimumStock;
  final List<String> imageUrls; // 👈 CHANGED: single imageUrl -> list
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ComponentModel({
    required this.id,
    required this.name,
    required this.componentCode,
    required this.type,
    required this.manufacturer,
    required this.partNumber,
    required this.abcdClass,
    required this.description,
    required this.minimumStock,
    this.imageUrls = const [], // 👈 default empty list
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ComponentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return ComponentModel(
      id: doc.id,
      name: data['name'] ?? '',
      componentCode: data['componentCode'] ?? '',
      type: data['type'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      partNumber: data['partNumber'] ?? '',
      abcdClass: data['abcdClass'] ?? '',
      description: data['description'] ?? '',
      minimumStock: data['minimumStock'] ?? 0,
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : const [],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'componentCode': componentCode,
      'type': type,
      'manufacturer': manufacturer,
      'partNumber': partNumber,
      'abcdClass': abcdClass,
      'description': description,
      'minimumStock': minimumStock,
      'imageUrls': imageUrls,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
