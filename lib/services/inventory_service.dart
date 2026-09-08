// lib/services/inventory_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _inventory =>
      _firestore.collection('inventory');

  String _docId(String componentId, String locationId) =>
      '${componentId}_$locationId';

  // Naya stock add karo — agar record already exist karta hai to quantity + karo
  Future<void> addStock({
    required String componentId,
    required String locationId,
    required int quantity,
  }) async {
    final docId = _docId(componentId, locationId);
    final docRef = _inventory.doc(docId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (snapshot.exists) {
        final currentQty = (snapshot.data()?['quantity'] ?? 0) as int;
        transaction.update(docRef, {
          'quantity': currentQty + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'componentId': componentId,
          'locationId': locationId,
          'quantity': quantity,
          'damagedQuantity': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Stock nikalo (issue karna) — quantity se zyada nahi nikal sakte
  Future<void> removeStock({
    required String componentId,
    required String locationId,
    required int quantity,
  }) async {
    final docId = _docId(componentId, locationId);
    final docRef = _inventory.doc(docId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('No stock found at this location');
      }

      final currentQty = (snapshot.data()?['quantity'] ?? 0) as int;

      if (quantity > currentQty) {
        throw Exception('Not enough stock. Available: $currentQty');
      }

      transaction.update(docRef, {
        'quantity': currentQty - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Damaged quantity mark karo
  Future<void> markDamaged({
    required String componentId,
    required String locationId,
    required int damagedQty,
  }) async {
    final docId = _docId(componentId, locationId);
    final docRef = _inventory.doc(docId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('No stock record found');
      }

      final currentDamaged = (snapshot.data()?['damagedQuantity'] ?? 0) as int;
      transaction.update(docRef, {
        'damagedQuantity': currentDamaged + damagedQty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Ek component ki total quantity (sab locations mila ke)
  Future<int> getTotalQuantityForComponent(String componentId) async {
    final snapshot = await _inventory
        .where('componentId', isEqualTo: componentId)
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['quantity'] ?? 0) as int;
    }
    return total;
  }

  // Ek component ke sab inventory records (kis-kis location pe hai)
  Stream<List<InventoryModel>> getInventoryForComponent(String componentId) {
    return _inventory
        .where('componentId', isEqualTo: componentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InventoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Ek location pe kya-kya rakha hai
  Stream<List<InventoryModel>> getInventoryForLocation(String locationId) {
    return _inventory
        .where('locationId', isEqualTo: locationId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InventoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Poori inventory (Admin overview ke liye)
  Stream<List<InventoryModel>> getAllInventory() {
    return _inventory.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => InventoryModel.fromFirestore(doc))
          .toList(),
    );
  }

  // Ye method existing InventoryService class ke andar add karo:

  // Ek location se dusri location mein quantity move karo (atomic transaction)
  Future<void> transferStock({
    required String componentId,
    required String fromLocationId,
    required String toLocationId,
    required int quantity,
  }) async {
    if (fromLocationId == toLocationId) {
      throw Exception('Source and destination cannot be the same');
    }

    final fromDocId = _docId(componentId, fromLocationId);
    final toDocId = _docId(componentId, toLocationId);
    final fromRef = _inventory.doc(fromDocId);
    final toRef = _inventory.doc(toDocId);

    await _firestore.runTransaction((transaction) async {
      final fromSnapshot = await transaction.get(fromRef);

      if (!fromSnapshot.exists) {
        throw Exception('No stock found at source location');
      }

      final fromQty = (fromSnapshot.data()?['quantity'] ?? 0) as int;
      if (quantity > fromQty) {
        throw Exception('Not enough stock to transfer. Available: $fromQty');
      }

      final toSnapshot = await transaction.get(toRef);

      // Source se ghatao
      transaction.update(fromRef, {
        'quantity': fromQty - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Destination mein badhao (ya naya record banao)
      if (toSnapshot.exists) {
        final toQty = (toSnapshot.data()?['quantity'] ?? 0) as int;
        transaction.update(toRef, {
          'quantity': toQty + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(toRef, {
          'componentId': componentId,
          'locationId': toLocationId,
          'quantity': quantity,
          'damagedQuantity': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Low stock components dhoondo (minimumStock se compare baad mein UI layer mein hoga)
  Future<InventoryModel?> getInventoryRecord(
    String componentId,
    String locationId,
  ) async {
    final doc = await _inventory.doc(_docId(componentId, locationId)).get();
    if (!doc.exists) return null;
    return InventoryModel.fromFirestore(doc);
  }
}
