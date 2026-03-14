import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_report.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class FeedState {
  final List<CommunityReport> reports;
  final bool isLoading;
  final String? filterType; // null = all, 'message', 'number'
  final String? error;

  const FeedState({
    this.reports = const [],
    this.isLoading = false,
    this.filterType,
    this.error,
  });

  FeedState copyWith({
    List<CommunityReport>? reports,
    bool? isLoading,
    String? filterType,
    String? error,
    bool clearFilter = false,
  }) =>
      FeedState(
        reports: reports ?? this.reports,
        isLoading: isLoading ?? this.isLoading,
        filterType: clearFilter ? null : (filterType ?? this.filterType),
        error: error,
      );
}

class CommunityFeedNotifier extends StateNotifier<FeedState> {
  final DatabaseService _db;
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  CommunityFeedNotifier(this._db, this._client) : super(const FeedState()) {
    loadReports();
    _subscribeToRealtime();
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reports = await _db.getCommunityReports(
        limit: 50,
        filterType: state.filterType,
      );
      state = state.copyWith(reports: reports, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String? type) {
    if (type == state.filterType) return;
    state = state.copyWith(filterType: type, clearFilter: type == null);
    loadReports();
  }

  void _subscribeToRealtime() {
    _channel = _client
        .channel('community_reports_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'community_reports',
          callback: (payload) async {
            // Reload the feed to get joined data
            await loadReports();

            // Show notification
            try {
              final newReport = payload.newRecord;
              final type = newReport['report_type'] as String? ?? 'scam';
              NotificationService().showScamAlert(
                title: 'New Scam Report',
                body: 'A new $type scam has been reported in the community.',
              );
            } catch (_) {
              // Notification failure shouldn't crash the app
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ── Providers ──

final communityFeedProvider =
    StateNotifierProvider<CommunityFeedNotifier, FeedState>((ref) {
  return CommunityFeedNotifier(
    DatabaseService(ref.watch(supabaseClientProvider)),
    ref.watch(supabaseClientProvider),
  );
});
