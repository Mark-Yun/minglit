import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// **Ticket Crypto Utility**
///
/// Uses Ed25519 for secure ticket signing and verification.
/// This allows offline QR code display on user apps and secure online
/// validation on partner apps.
class TicketCrypto {
  /// Ed25519 signing algorithm instance.
  final algorithm = Ed25519();

  /// Generates a new Ed25519 KeyPair.
  /// Used primarily for server setup or testing.
  Future<SimpleKeyPair> generateKeyPair() async {
    return algorithm.newKeyPair();
  }

  /// Signs the [payload] string using the [keyPair].
  /// Returns a Base64 encoded signature.
  Future<String> sign(String payload, SimpleKeyPair keyPair) async {
    final message = utf8.encode(payload);
    final keyPairData = await keyPair.extract();
    final signature = await algorithm.sign(message, keyPair: keyPairData);
    return base64Url.encode(signature.bytes);
  }

  /// Verifies the [payload] against the [signatureBase64] using the
  /// [publicKey].
  Future<bool> verify(
    String payload,
    String signatureBase64,
    SimplePublicKey publicKey,
  ) async {
    try {
      final message = utf8.encode(payload);
      final signatureBytes = base64Url.decode(signatureBase64);
      final signature = Signature(signatureBytes, publicKey: publicKey);

      return algorithm.verify(message, signature: signature);
    } on Object {
      return false;
    }
  }
}

/// **Ticket KeyPair Result**
/// Used to keep private and public keys together during generation.
class TicketKeyPair {
  /// Creates a key pair container.
  TicketKeyPair({required this.privateKey, required this.publicKey});

  /// Private key used for signing.
  final SimpleKeyPairData privateKey;

  /// Public key used for verification.
  final SimplePublicKey publicKey;
}
