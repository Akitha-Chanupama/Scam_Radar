import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scam_message.dart';
import '../models/community_report.dart';
import '../services/database_service.dart';
import '../services/scam_detector.dart';
import 'auth_provider.dart';

enum AnalysisStatus { idle, analyzing, result, error }

class AnalysisState {
  final AnalysisStatus status;
  final ScamResult? result;
  final String? messageText;
  final String? error;

  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.result,
    this.messageText,
    this.error,
  });
}

class ScamMessagesNotifier extends StateNotifier<AnalysisState> {
  final ScamDetector _detector;
  final DatabaseService _db;
  final String? _userId;

  ScamMessagesNotifier(this._detector, this._db, this._userId)
      : super(const AnalysisState());

  void analyzeMessage(String text) {
    state = AnalysisState(
      status: AnalysisStatus.analyzing,
      messageText: text,
    );

    try {
      final result = _detector.analyzeMessage(text);
      state = AnalysisState(
        status: AnalysisStatus.result,
        result: result,
        messageText: text,
      );
    } catch (e) {
      state = AnalysisState(
        status: AnalysisStatus.error,
        messageText: text,
        error: e.toString(),
      );
    }
  }

  Future<void> reportMessage() async {
    if (state.result == null || state.messageText == null) return;
    final userId = _userId;
    if (userId == null) return;

    final message = ScamMessage(
      userId: userId,
      messageText: state.messageText!,
      scamScore: state.result!.score,
      reasons: state.result!.reasons,
      isReported: true,
      createdAt: DateTime.now(),
    );

    final saved = await _db.insertScamMessage(message);

    // Also create a community report
    await _db.insertCommunityReport(
      CommunityReport(
        reporterId: userId,
        reportType: 'message',
        scamMessageId: saved.id,
        description:
            'Scam score: ${saved.scamScore}% — ${saved.reasons.join(', ')}',
        createdAt: DateTime.now(),
      ),
    );
  }

  void reset() {
    state = const AnalysisState();
  }
}

// ── Providers ──

final scamDetectorProvider = Provider<ScamDetector>((ref) => ScamDetector());

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(ref.watch(supabaseClientProvider));
});

final scamMessagesProvider =
    StateNotifierProvider<ScamMessagesNotifier, AnalysisState>((ref) {
  return ScamMessagesNotifier(
    ref.watch(scamDetectorProvider),
    ref.watch(databaseServiceProvider),
    ref.watch(authProvider).user?.id,
  );
});

final recentScamMessagesProvider =
    FutureProvider<List<ScamMessage>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getRecentScamMessages(limit: 10);
});
