import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadComponentImage({
    required File imageFile,
    required String componentId,
  }) async {
    final ref = _storage
        .ref()
        .child('components')
        .child(componentId)
        .child('image.jpg');

    await ref.putFile(imageFile);

    return await ref.getDownloadURL();
  }

  Future<void> deleteComponentImage(String componentId) async {
    final ref = _storage
        .ref()
        .child('components')
        .child(componentId)
        .child('image.jpg');

    try {
      await ref.delete();
    } catch (_) {
      // Image may not exist.
    }
  }
}
