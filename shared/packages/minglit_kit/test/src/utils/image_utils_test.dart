import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:minglit_kit/src/utils/image_utils.dart';

void main() {
  group('stripExifAndReencode', () {
    /// 1x1 흰색 픽셀 JPEG 바이트를 생성하는 헬퍼
    Uint8List makeMinimalJpeg() {
      final image = img.Image(width: 1, height: 1)
        ..setPixelRgba(0, 0, 255, 255, 255, 255);
      return Uint8List.fromList(img.encodeJpg(image));
    }

    /// 1x1 흰색 픽셀 PNG 바이트를 생성하는 헬퍼
    Uint8List makeMinimalPng() {
      final image = img.Image(width: 1, height: 1)
        ..setPixelRgba(0, 0, 255, 255, 255, 255);
      return Uint8List.fromList(img.encodePng(image));
    }

    test('JPEG 이미지를 처리하면 비어있지 않은 결과를 반환한다', () {
      final input = makeMinimalJpeg();
      final result = stripExifAndReencode(input, filename: 'photo.jpg');
      expect(result.isNotEmpty, isTrue);
    });

    test('PNG 파일명이면 PNG 시그니처로 재인코딩한다', () {
      final input = makeMinimalPng();
      final result = stripExifAndReencode(input, filename: 'photo.png');

      // PNG 시그니처: 0x89 0x50 0x4E 0x47 ('P' 'N' 'G')
      expect(result.length, greaterThan(4));
      expect(result[0], equals(0x89));
      expect(result[1], equals(0x50));
      expect(result[2], equals(0x4E));
      expect(result[3], equals(0x47));
    });

    test('JPEG 파일명이면 JPEG 시그니처로 재인코딩한다', () {
      final input = makeMinimalJpeg();
      final result = stripExifAndReencode(input, filename: 'photo.jpg');

      // JPEG 시그니처: 0xFF 0xD8
      expect(result.length, greaterThan(2));
      expect(result[0], equals(0xFF));
      expect(result[1], equals(0xD8));
    });

    test('확장자 없는 파일명은 JPEG로 재인코딩한다', () {
      final input = makeMinimalJpeg();
      final result = stripExifAndReencode(input, filename: 'photo');

      expect(result[0], equals(0xFF));
      expect(result[1], equals(0xD8));
    });

    test('filename 생략 시 JPEG로 재인코딩한다', () {
      final input = makeMinimalJpeg();
      final result = stripExifAndReencode(input);
      expect(result[0], equals(0xFF));
      expect(result[1], equals(0xD8));
    });

    test('재인코딩 결과가 여전히 유효한 이미지로 디코딩된다', () {
      final input = makeMinimalJpeg();
      final result = stripExifAndReencode(input, filename: 'photo.jpg');

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1));
      expect(decoded.height, equals(1));
    });

    test('재인코딩 후 EXIF GPS 필드가 비어있다 (EXIF 제거 확인)', () {
      // EXIF가 없는 기본 이미지를 재인코딩하면 gpsIfd가 비어야 한다
      final input = makeMinimalJpeg();
      final result = stripExifAndReencode(input, filename: 'photo.jpg');

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(
        decoded!.exif.gpsIfd.isEmpty,
        isTrue,
        reason: '재인코딩 후 GPS EXIF 데이터가 없어야 한다',
      );
    });

    test('빈 바이트 입력은 원본을 그대로 반환한다 (디코딩 실패 시 안전 처리)', () {
      final input = Uint8List(0);
      final result = stripExifAndReencode(input, filename: 'photo.jpg');
      expect(result, equals(input));
    });

    test('유효하지 않은 이미지 바이트는 원본을 그대로 반환한다', () {
      final input = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      final result = stripExifAndReencode(input, filename: 'photo.jpg');
      expect(result, equals(input));
    });

    test('jpegQuality 파라미터가 유효한 JPEG 출력을 생성한다', () {
      final input = makeMinimalJpeg();

      final defaultResult = stripExifAndReencode(
        input,
        filename: 'photo.jpg',
      );
      final highQualityResult = stripExifAndReencode(
        input,
        filename: 'photo.jpg',
        jpegQuality: 95,
      );

      // 둘 다 유효한 JPEG 시그니처를 가져야 한다
      expect(defaultResult[0], equals(0xFF));
      expect(highQualityResult[0], equals(0xFF));
      // 둘 다 디코딩 가능해야 한다
      expect(img.decodeImage(defaultResult), isNotNull);
      expect(img.decodeImage(highQualityResult), isNotNull);
    });
  });
}
