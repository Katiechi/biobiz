import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// Service for uploading and managing files in Supabase Storage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    return _uploadImage(imageFile, 'profiles/$userId/profile_${_uuid.v4()}');
  }

  Future<String?> uploadLogo(XFile imageFile, String userId) async {
    return _uploadImage(imageFile, 'profiles/$userId/logo_${_uuid.v4()}');
  }

  Future<String?> uploadCoverImage(XFile imageFile, String userId) async {
    return _uploadImage(imageFile, 'profiles/$userId/cover_${_uuid.v4()}');
  }

  Future<String?> _uploadImage(XFile imageFile, String path) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.name.split('.').last.toLowerCase();
      final mimeType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
      final fullPath = '$path.$ext';

      await _supabase.storage.from('biobiz').uploadBinary(
        fullPath,
        bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );

      return _supabase.storage.from('biobiz').getPublicUrl(fullPath);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }
}
