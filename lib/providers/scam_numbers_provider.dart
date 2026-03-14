import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scam_number.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

class ScamNumbersNotifier extends StateNotifier<AsyncValue<List<ScamNumber>>> {
  final DatabaseService _db;

  ScamNumbersNotifier(this._db) : super(const AsyncValue.loading()) {
    loadTopReported();
  }

  Future<void> loadTopReported() async {
    state = const AsyncValue.loading();
    try {
      final numbers = await _db.getTopReportedNumbers(limit: 20);
      state = AsyncValue.data(numbers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ScamNumber?> searchNumber(String phoneNumber) async {
    return _db.searchScamNumber(phoneNumber);
  }

  Future<void> reportNumber({
    required String phoneNumber,
    required String scamType,
    String? region,
    double? latitude,
    double? longitude,
  }) async {
    await _db.reportScamNumber(
      phoneNumber: phoneNumber,
      scamType: scamType,
      region: region,
      latitude: latitude,
      longitude: longitude,
    );
    await loadTopReported();
  }
}

// ── Providers ──

final scamNumbersProvider =
    StateNotifierProvider<ScamNumbersNotifier, AsyncValue<List<ScamNumber>>>(
        (ref) {
  return ScamNumbersNotifier(
    DatabaseService(ref.watch(supabaseClientProvider)),
  );
});
