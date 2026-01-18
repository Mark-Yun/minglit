import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ticket_wallet_repository.g.dart';

@riverpod
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
}

@riverpod
TicketWalletRepository ticketWalletRepository(Ref ref) {
  return TicketWalletRepository(ref.watch(secureStorageProvider));
}

/// **Ticket Wallet Repository**
/// 
/// Manages offline ticket storage using secure local storage.
class TicketWalletRepository {
  TicketWalletRepository(this._storage);
  final FlutterSecureStorage _storage;

  static const String _keyPrefix = 'ticket_';

  /// Saves a [TicketToken] to secure storage.
  Future<void> saveTicket(TicketToken token) async {
    final key = '$_keyPrefix${token.ticketId}';
    final value = jsonEncode(token.toJson());
    await _storage.write(key: key, value: value);
  }

  /// Retrieves a [TicketToken] by ID.
  Future<TicketToken?> getTicket(String ticketId) async {
    final key = '$_keyPrefix$ticketId';
    final value = await _storage.read(key: key);
    if (value == null) return null;
    
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return TicketToken.fromJson(json);
    } on Object catch (e) {
      Log.e('Failed to parse ticket token from storage', e);
      return null;
    }
  }
  /// Deletes a ticket from storage.
  Future<void> deleteTicket(String ticketId) async {
    final key = '$_keyPrefix$ticketId';
    await _storage.delete(key: key);
  }

  /// Lists all saved tickets (IDs).
  Future<List<String>> listAllTicketIds() async {
    final all = await _storage.readAll();
    return all.keys
        .where((key) => key.startsWith(_keyPrefix))
        .map((key) => key.replaceFirst(_keyPrefix, ''))
        .toList();
  }
}
