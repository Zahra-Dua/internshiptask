import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_model.dart';

class SupplierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _suppliers =>
      _firestore.collection('suppliers');

  Future<String> addSupplier(SupplierModel supplier) async {
    final doc = await _suppliers.add(supplier.toFirestore());

    return doc.id;
  }

  Future<SupplierModel?> getSupplier(String supplierId) async {
    final doc = await _suppliers.doc(supplierId).get();

    if (!doc.exists) {
      return null;
    }

    return SupplierModel.fromFirestore(doc);
  }

  Stream<List<SupplierModel>> getSuppliers() {
    return _suppliers
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupplierModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateSupplier(
    String supplierId,
    Map<String, dynamic> data,
  ) async {
    await _suppliers.doc(supplierId).update(data);
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _suppliers.doc(supplierId).delete();
  }
}
