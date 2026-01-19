import 'package:flutter/material.dart';

/// **Identification Provider Interface**
///
/// Defines the contract for platform-specific identity verification.
abstract class IdentificationProvider {
  /// Initiates the identity verification process.
  ///
  /// Returns the `imp_uid` (Portone verification ID) if successful,
  /// or null if cancelled/failed.
  ///
  /// [context]: BuildContext for showing dialogs or navigation (Mobile).
  /// [merchantUid]: Unique ID for this transaction.
  /// [userPhone]: (Optional) Pre-fill user phone number.
  Future<String?> verify({
    required BuildContext context,
    required String merchantUid,
    String? userPhone,
    String? userName,
  });
}
