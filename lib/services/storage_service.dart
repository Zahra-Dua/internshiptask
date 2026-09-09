// lib/services/storage_service.dart
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'component-images';

  // Ek image upload karo, public URL return karo
  Future<String> uploadImage({
    required XFile file,
    required String componentCode,
  }) async {
    final bytes = await file.readAsBytes();
    final extension = file.name.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '$componentCode/$fileName';

    await _supabase.storage
        .from(_bucketName)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from(_bucketName).getPublicUrl(path);
  }

  // Multiple images upload karo, sab URLs ki list return karo
  Future<List<String>> uploadImages({
    required List<XFile> files,
    required String componentCode,
  }) async {
    final urls = <String>[];
    for (var file in files) {
      final url = await uploadImage(file: file, componentCode: componentCode);
      urls.add(url);
    }
    return urls;
  }

  // Image delete karo (URL se path nikal ke)
  Future<void> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return;

      final path = segments.sublist(bucketIndex + 1).join('/');
      await _supabase.storage.from(_bucketName).remove([path]);
    } catch (_) {
      // Agar delete fail ho, silently ignore karo
    }
  }

  // Poore component ka folder delete karo (jab component khud delete ho)
  Future<void> deleteAllImagesForComponent(String componentCode) async {
    try {
      final files = await _supabase.storage
          .from(_bucketName)
          .list(path: componentCode);
      if (files.isEmpty) return;
      final paths = files.map((f) => '$componentCode/${f.name}').toList();
      await _supabase.storage.from(_bucketName).remove(paths);
    } catch (_) {
      // ignore
    }
  }
}
