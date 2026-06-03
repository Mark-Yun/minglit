import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:minglit_kit/src/utils/image_utils.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'storage_repository.g.dart';

/// Provides the [StorageRepository].
@Riverpod(keepAlive: true)
StorageRepository storageRepository(Ref ref) {
  return StorageRepository(supabase: ref.watch(supabaseClientProvider));
}

/// **Storage Repository**
///
/// Handles generic file upload operations to Supabase Storage.
class StorageRepository {
  /// Creates a [StorageRepository] with a Supabase client.
  StorageRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  static const Set<String> _signedUploadBuckets = {
    'verification-proofs',
    'partner-proofs',
    'party-assets',
  };

  final SupabaseClient _supabase;

  /// Uploads a file to Supabase Storage.
  ///
  /// Covered private buckets return the stored path. Public buckets return the
  /// public URL.
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
      final rawBytes = await file.readAsBytes();
      final extension = _extensionForFile(file);
      // Fix #1230: GPS/EXIF 메타데이터 유출 방지 — 업로드 전 재인코딩으로 완전 제거
      final bytes = stripExifAndReencode(rawBytes, filename: file.name);
      // Generate a unique filename
      final filename = '${const Uuid().v4()}$extension';
      final fullPath = pathPrefix != null ? '$pathPrefix/$filename' : filename;
      final contentType = file.mimeType ?? _contentTypeForExtension(extension);

      Log.d('Uploading file to $bucket/$fullPath...');

      if (_signedUploadBuckets.contains(bucket)) {
        return await _uploadSignedBytes(
          bytes: bytes,
          bucket: bucket,
          pathPrefix: pathPrefix,
          contentType: contentType,
          extension: extension,
        );
      }

      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            fullPath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
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

      if (_signedUploadBuckets.contains(bucket)) {
        return await _uploadSignedBytes(
          bytes: bytes,
          bucket: bucket,
          pathPrefix: pathPrefix,
          contentType: contentType,
          extension: extension,
        );
      }

      await _supabase.storage
          .from(bucket)
          .uploadBinary(
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

  Future<String> _uploadSignedBytes({
    required Uint8List bytes,
    required String bucket,
    required String contentType,
    required String extension,
    String? pathPrefix,
  }) async {
    final presign = await _supabase.functions.invoke(
      'storage-upload',
      body: {
        'action': 'presign',
        'bucket': bucket,
        'path_prefix': pathPrefix,
        'declared_size': bytes.length,
        'mime': contentType,
        'extension': extension,
      },
    );
    if (presign.status != 200 || presign.data is! Map) {
      throw Exception(_functionError(presign, 'Storage presign failed'));
    }

    final presignData = (presign.data as Map).cast<String, dynamic>();
    final uploadId = presignData['upload_id'] as String;
    final path = presignData['path'] as String;
    final token = presignData['token'] as String;

    try {
      await _supabase.storage
          .from(bucket)
          .uploadBinaryToSignedUrl(
            path,
            token,
            bytes,
            FileOptions(contentType: contentType),
          );
    } catch (_) {
      await _abortSignedUpload(uploadId);
      rethrow;
    }

    final complete = await _supabase.functions.invoke(
      'storage-upload',
      body: {
        'action': 'complete',
        'upload_id': uploadId,
      },
    );
    if (complete.status != 200 || complete.data is! Map) {
      throw Exception(_functionError(complete, 'Storage complete failed'));
    }

    final completeData = (complete.data as Map).cast<String, dynamic>();
    if (completeData['status'] == 'rejected') {
      throw Exception(
        completeData['rejection_reason'] ?? 'Storage upload rejected',
      );
    }

    final publicUrl = completeData['public_url'] as String?;
    return publicUrl ?? (completeData['path'] as String? ?? path);
  }

  Future<void> _abortSignedUpload(String uploadId) async {
    try {
      await _supabase.functions.invoke(
        'storage-upload',
        body: {
          'action': 'abort',
          'upload_id': uploadId,
        },
      );
    } on Object {
      // Best effort: the active upload expires server-side if abort fails.
    }
  }

  static String _functionError(FunctionResponse response, String fallback) {
    final data = response.data;
    if (data is Map) {
      return (data['error'] as String?) ?? fallback;
    }
    return fallback;
  }

  static String _contentTypeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  static String _extensionForFile(XFile file) {
    final pathExtension = p.extension(file.path);
    if (pathExtension.isNotEmpty) {
      return pathExtension;
    }

    final nameExtension = p.extension(file.name);
    if (nameExtension.isNotEmpty) {
      return nameExtension;
    }

    return '.jpg';
  }
}
