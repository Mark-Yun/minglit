import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/storage_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const FileOptions());
  });

  late MockSupabaseClient mockClient;
  late MockSupabaseStorageClient mockStorage;
  late MockStorageFileApi mockStorageFileApi;
  late StorageRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockStorage = MockSupabaseStorageClient();
    mockStorageFileApi = MockStorageFileApi();

    when(() => mockClient.storage).thenReturn(mockStorage);
    when(() => mockStorage.from(any())).thenReturn(mockStorageFileApi);

    repository = StorageRepository(supabase: mockClient);
  });

  group('StorageRepository', () {
    group('uploadBytes', () {
      test('throws when upload fails', () async {
        final testBytes = Uint8List.fromList([1, 2, 3]);
        const bucket = 'bug-report-attachments';

        when(
          () => mockStorageFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenThrow(Exception('Upload failed'));

        expect(
          () => repository.uploadBytes(
            bytes: testBytes,
            bucket: bucket,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
