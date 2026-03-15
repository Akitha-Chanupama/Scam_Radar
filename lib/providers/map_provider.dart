import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scam_number.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

final mapScamNumbersProvider = FutureProvider<List<ScamNumber>>((ref) async {
  final db = DatabaseService(ref.watch(supabaseClientProvider));
  return db.getScamNumbersWithLocation();
});
