import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// EXIF 메타데이터(GPS 포함)를 제거하고 재인코딩한 이미지 바이트를 반환한다.
///
/// 디코딩 → 재인코딩 과정에서 EXIF/XMP/IPTC 메타데이터가 모두 제거된다.
/// PNG 파일은 PNG로, 그 외(JPEG 등)는 JPEG로 재인코딩한다.
///
/// 디코딩에 실패한 경우(지원하지 않는 포맷 등) 원본 [bytes]를 그대로 반환한다.
///
/// [bytes] 원본 이미지 바이트
/// [filename] 확장자 판별에 사용할 파일 이름 (예: 'photo.png')
/// [jpegQuality] JPEG 재인코딩 품질 (1–100, 기본값 85)
///
/// Fix #1230: GPS/EXIF 메타데이터 유출 방지 — 업로드 전 재인코딩으로 완전 제거
Uint8List stripExifAndReencode(
  Uint8List bytes, {
  String filename = '',
  int jpegQuality = 85,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } on Object {
    // 디코딩 중 예외 발생: 지원하지 않는 포맷이거나 손상된 파일. 원본 반환.
    return bytes;
  }
  if (decoded == null) {
    // 디코딩 실패: 지원하지 않는 포맷이거나 손상된 파일. 원본 반환.
    return bytes;
  }

  final ext = p.extension(filename).toLowerCase();
  if (ext == '.png') {
    return Uint8List.fromList(img.encodePng(decoded));
  }
  return Uint8List.fromList(img.encodeJpg(decoded, quality: jpegQuality));
}
