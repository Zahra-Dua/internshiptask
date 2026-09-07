import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/component_model.dart';

class ComponentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _components =>
      _firestore.collection('components');

  // 👇 Check karo componentCode already exist to nahi karta
  Future<bool> componentCodeExists(String componentCode) async {
    final doc = await _components.doc(componentCode).get();
    return doc.exists;
  }

  // 👇 Ab componentCode hi Document ID hai
  Future<void> addComponent(ComponentModel component) async {
    final exists = await componentCodeExists(component.componentCode);
    if (exists) {
      throw Exception(
        'Component code "${component.componentCode}" already exists',
      );
    }

    await _components.doc(component.componentCode).set(component.toFirestore());
  }

  Future<ComponentModel?> getComponent(String componentId) async {
    final doc = await _components.doc(componentId).get();
    if (!doc.exists) return null;
    return ComponentModel.fromFirestore(doc);
  }

  Stream<List<ComponentModel>> getComponents() {
    return _components
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ComponentModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateComponent(
    String componentId,
    Map<String, dynamic> data,
  ) async {
    await _components.doc(componentId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComponent(String componentId) async {
    await _components.doc(componentId).delete();
  }

  Future<List<ComponentModel>> searchComponents(String query) async {
    final snapshot = await _components.orderBy('name').get();
    final searchQuery = query.toLowerCase();

    return snapshot.docs
        .map((doc) => ComponentModel.fromFirestore(doc))
        .where(
          (component) =>
              component.name.toLowerCase().contains(searchQuery) ||
              component.componentCode.toLowerCase().contains(searchQuery) ||
              component.partNumber.toLowerCase().contains(searchQuery),
        )
        .toList();
  }
}
