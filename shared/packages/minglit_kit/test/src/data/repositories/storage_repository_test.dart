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
  late MockFunctionsClient mockFunctions;
  late StorageRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockStorage = MockSupabaseStorageClient();
    mockStorageFileApi = MockStorageFileApi();
    mockFunctions = MockFunctionsClient();

    when(() => mockClient.storage).thenReturn(mockStorage);
    when(() => mockClient.functions).thenReturn(mockFunctions);
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

        await expectLater(
          repository.uploadBytes(
            bytes: testBytes,
            bucket: bucket,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('uses signed upload flow for covered private bucket', () async {
        final testBytes = Uint8List.fromList([1, 2, 3]);
        final responses = <FunctionResponse>[
          FunctionResponse(
            status: 200,
            data: {
              'upload_id': 'upload-1',
              'path': 'user-1/file.jpg',
              'token': 'token-1',
            },
          ),
          FunctionResponse(
            status: 200,
            data: {
              'upload_id': 'upload-1',
              'path': 'user-1/file.jpg',
              'status': 'completed',
              'public_url': null,
            },
          ),
        ];

        when(
          () => mockFunctions.invoke(
            'storage-upload',
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => responses.removeAt(0));
        when(
          () => mockStorageFileApi.uploadBinaryToSignedUrl(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => 'user-1/file.jpg');

        final result = await repository.uploadBytes(
          bytes: testBytes,
          bucket: 'partner-proofs',
          pathPrefix: 'user-1',
          contentType: 'image/jpeg',
          extension: '.jpg',
        );

        expect(result, 'user-1/file.jpg');
        verify(
          () => mockStorageFileApi.uploadBinaryToSignedUrl(
            'user-1/file.jpg',
            'token-1',
            testBytes,
            any(),
          ),
        ).called(1);

        final bodies = verify(
          () => mockFunctions.invoke(
            'storage-upload',
            body: captureAny(named: 'body'),
          ),
        ).captured.cast<Map<String, dynamic>>();
        expect(bodies[0]['action'], 'presign');
        expect(bodies[0]['bucket'], 'partner-proofs');
        expect(bodies[0]['path_prefix'], 'user-1');
        expect(bodies[0]['declared_size'], testBytes.length);
        expect(bodies[1]['action'], 'complete');
        expect(bodies[1]['upload_id'], 'upload-1');
      });

      test('aborts signed upload reservation when upload fails', () async {
        final testBytes = Uint8List.fromList([1, 2, 3]);
        final responses = <FunctionResponse>[
          FunctionResponse(
            status: 200,
            data: {
              'upload_id': 'upload-1',
              'path': 'user-1/file.jpg',
              'token': 'token-1',
            },
          ),
          FunctionResponse(
            status: 200,
            data: {
              'upload_id': 'upload-1',
              'path': 'user-1/file.jpg',
              'status': 'aborted',
            },
          ),
        ];

        when(
          () => mockFunctions.invoke(
            'storage-upload',
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => responses.removeAt(0));
        when(
          () => mockStorageFileApi.uploadBinaryToSignedUrl(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenThrow(Exception('upload failed'));

        await expectLater(
          repository.uploadBytes(
            bytes: testBytes,
            bucket: 'partner-proofs',
            pathPrefix: 'user-1',
            contentType: 'image/jpeg',
            extension: '.jpg',
          ),
          throwsA(isA<Exception>()),
        );

        final bodies = verify(
          () => mockFunctions.invoke(
            'storage-upload',
            body: captureAny(named: 'body'),
          ),
        ).captured.cast<Map<String, dynamic>>();
        expect(bodies[0]['action'], 'presign');
        expect(bodies[1]['action'], 'abort');
        expect(bodies[1]['upload_id'], 'upload-1');
      });

      test('uses staging upload bucket for public signed bucket', () async {
        final testBytes = Uint8List.fromList([1, 2, 3]);
        final responses = <FunctionResponse>[
          FunctionResponse(
            status: 200,
            data: {
              'upload_id': 'upload-1',
              'bucket': 'party-assets',
              'path': 'partner-1/hero.jpg',
              'upload_bucket': 'party-assets-pending',
              'upload_path': 'partner-1/hero.jpg',
              'final_path': 'partner-1/hero.jpg',
              'token': 'token-1',
              'public_url': null,
            },
          ),
          FunctionResponse(
            status: 200,
            data: {
              'upload_id': 'upload-1',
              'bucket': 'party-assets',
              'path': 'partner-1/hero.jpg',
              'status': 'completed',
              'public_url':
                  'https://storage.test/object/public/party-assets/partner-1/hero.jpg',
            },
          ),
        ];

        when(
          () => mockFunctions.invoke(
            'storage-upload',
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => responses.removeAt(0));
        when(
          () => mockStorageFileApi.uploadBinaryToSignedUrl(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => 'partner-1/hero.jpg');

        final result = await repository.uploadBytes(
          bytes: testBytes,
          bucket: 'party-assets',
          pathPrefix: 'partner-1',
          contentType: 'image/jpeg',
          extension: '.jpg',
        );

        expect(
          result,
          'https://storage.test/object/public/party-assets/partner-1/hero.jpg',
        );
        verify(() => mockStorage.from('party-assets-pending')).called(1);
        verify(
          () => mockStorageFileApi.uploadBinaryToSignedUrl(
            'partner-1/hero.jpg',
            'token-1',
            testBytes,
            any(),
          ),
        ).called(1);
      });
    });
  });
}
