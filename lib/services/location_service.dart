import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _locations =>
      _firestore.collection('locations');

  // 👇 Check karo locationCode already exist to nahi karta
  Future<bool> locationCodeExists(String locationCode) async {
    final snapshot = await _locations
        .where('locationCode', isEqualTo: locationCode)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Location code "A-2-B5" se "A" nikalta hai (root rack)
  String getRootCode(String locationCode) {
    return locationCode.split('-').first;
  }

  // addLocation() method ko is se replace karo:
  Future<String> addLocation(LocationModel location) async {
    final exists = await locationCodeExists(location.locationCode);
    if (exists) {
      throw Exception(
        'Location code "${location.locationCode}" already exists',
      );
    }

    // 👇 STRICT HIERARCHY RULES
    if (location.type == 'Rack') {
      if (location.parentId != null) {
        throw Exception('A Rack cannot have a parent — it must be top-level');
      }
    } else if (location.type == 'Shelf') {
      if (location.parentId == null) {
        throw Exception('A Shelf must be placed inside a Rack');
      }
      final parent = await getLocation(location.parentId!);
      if (parent == null || parent.type != 'Rack') {
        throw Exception('A Shelf\'s parent must be a Rack');
      }
    } else if (location.type == 'Box') {
      if (location.parentId == null) {
        throw Exception('A Box must be placed inside a Shelf');
      }
      final parent = await getLocation(location.parentId!);
      if (parent == null || parent.type != 'Shelf') {
        throw Exception('A Box\'s parent must be a Shelf');
      }
    }

    final doc = await _locations.add(location.toFirestore());
    return doc.id;
  }

  Future<LocationModel?> getLocation(String locationId) async {
    final doc = await _locations.doc(locationId).get();
    if (!doc.exists) return null;
    return LocationModel.fromFirestore(doc);
  }

  Stream<List<LocationModel>> getLocations() {
    return _locations
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LocationModel.fromFirestore(doc))
              .toList(),
        );
  }

  // 👇 NAYA — sirf top-level locations (jaise Racks), jinka koi parent nahi
  Stream<List<LocationModel>> getRootLocations() {
    return _locations
        .where('parentId', isNull: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LocationModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<LocationModel>> getChildLocations(String parentId) {
    return _locations
        .where('parentId', isEqualTo: parentId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LocationModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateLocation(
    String locationId,
    Map<String, dynamic> data,
  ) async {
    await _locations.doc(locationId).update(data);
  }

  // 👇 UPDATED — delete se pehle check karo children to nahi hain
  Future<void> deleteLocation(String locationId) async {
    final childrenSnapshot = await _locations
        .where('parentId', isEqualTo: locationId)
        .limit(1)
        .get();

    if (childrenSnapshot.docs.isNotEmpty) {
      throw Exception(
        'Cannot delete: this location has sub-locations inside it',
      );
    }

    await _locations.doc(locationId).delete();
  }

  // Rack dhoondo uske locationCode se (jaise "A", "B", "C", "D")
  Future<LocationModel?> getRackByCode(String code) async {
    final snapshot = await _locations
        .where('locationCode', isEqualTo: code)
        .where('parentId', isNull: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return LocationModel.fromFirestore(snapshot.docs.first);
  }

  // 👇 NAYA — breadcrumb path (Rack A → Shelf 1 → Box 03)
  Future<List<LocationModel>> getFullPath(String locationId) async {
    final path = <LocationModel>[];
    String? currentId = locationId;

    while (currentId != null) {
      final loc = await getLocation(currentId);
      if (loc == null) break;
      path.insert(0, loc);
      currentId = loc.parentId;
    }

    return path;
  }
}
