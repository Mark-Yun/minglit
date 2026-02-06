import 'package:freezed_annotation/freezed_annotation.dart';

part 'iamport_result_model.freezed.dart';
part 'iamport_result_model.g.dart';

/// Represents the result payload returned by Iamport.
@freezed
abstract class IamportResultModel with _$IamportResultModel {
  /// Creates an Iamport result model from raw fields.
  const factory IamportResultModel({
    @JsonKey(name: 'imp_uid') String? impUid,
    @JsonKey(name: 'merchant_uid') String? merchantUid,
    @JsonKey(name: 'success') @Default(false) bool success,
    @JsonKey(name: 'error_msg') String? errorMsg,
    @JsonKey(name: 'pg_provider') String? pgProvider,
    @JsonKey(name: 'pg_type') String? pgType,
  }) = _IamportResultModel;

  const IamportResultModel._();

  /// Creates a model from a JSON map.
  factory IamportResultModel.fromJson(Map<String, dynamic> json) =>
      _$IamportResultModelFromJson(json);

  /// Creates a model from a string-based result map.
  factory IamportResultModel.fromMap(Map<String, String> map) {
    // iamport_flutter returns Map<String, String>, need to convert boolean
    final successValue = map['success'];
    final isSuccess = successValue == 'true' || successValue == 'True';

    return IamportResultModel(
      impUid: map['imp_uid'],
      merchantUid: map['merchant_uid'],
      success: isSuccess,
      errorMsg: map['error_msg'],
      pgProvider: map['pg_provider'],
      pgType: map['pg_type'],
    );
  }
}
