import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'storage_repository.g.dart';

/// Provides the [StorageRepository].
@Riverpod(keepAlive: true)
StorageRepository storageRepository(Ref ref) {
  return StorageRepository();
}

/// **Storage Repository**
///
/// Handles generic file upload operations to Supabase Storage.
class StorageRepository {
  /// Creates a [StorageRepository] with a Supabase client.
  StorageRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Uploads a file to Supabase Storage and returns the public URL.
  ///
  /// [file]: The file to upload (XFile from image_picker/file_picker).
  /// [bucket]: Target bucket name
  /// (e.g., 'party-assets', 'verification-proofs').
  /// [pathPrefix]: Optional folder path prefix (e.g., 'partner_123').
  /// If provided, the file will be saved as `bucket/pathPrefix/uuid.ext`.
  Future<String> uploadFile({
    required XFile file,
    required String bucket,
    String? pathPrefix,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final extension =
          p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
      // Generate a unique filename
      final filename = '${const Uuid().v4()}$extension';
      final fullPath = pathPrefix != null ? '$pathPrefix/$filename' : filename;

      Log.d('Uploading file to $bucket/$fullPath...');

      await _supabase.storage.from(bucket).uploadBinary(
            fullPath,
            bytes,
            fileOptions: FileOptions(
              contentType: file.mimeType,
            ),
          );

      final url = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      Log.d('✅ Upload success: $url');
      return url;
    } catch (e, st) {
      Log.e('❌ [StorageRepo] Upload failed', e, st);
      rethrow;
    }
  }

  /// Uploads raw bytes to Supabase Storage and returns the public URL.
  ///
  /// [bytes]: The raw bytes to upload.
  /// [bucket]: Target bucket name (e.g., 'bug-report-attachments').
  /// [pathPrefix]: Optional folder path prefix.
  /// [contentType]: MIME type of the content (default: 'image/png').
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String bucket,
    String? pathPrefix,
    String contentType = 'image/png',
    String extension = '.png',
  }) async {
    try {
      final filename = '${const Uuid().v4()}$extension';
      final fullPath = pathPrefix != null ? '$pathPrefix/$filename' : filename;

      Log.d('Uploading bytes to $bucket/$fullPath...');

      await _supabase.storage.from(bucket).uploadBinary(
            fullPath,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      final url = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      Log.d('✅ Upload bytes success: $url');
      return url;
    } catch (e, st) {
      Log.e('❌ [StorageRepo] uploadBytes failed', e, st);
      rethrow;
    }
  }

  /// Deletes a file from storage.
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      Log.d('✅ File deleted: $bucket/$path');
    } catch (e, st) {
      Log.e('❌ [StorageRepo] Delete failed', e, st);
      rethrow;
    }
  }
}
