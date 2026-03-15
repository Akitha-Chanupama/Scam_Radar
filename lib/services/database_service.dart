import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../models/scam_message.dart';
import '../models/scam_number.dart';
import '../models/community_report.dart';

class DatabaseService {
  final SupabaseClient _client;

  DatabaseService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  // ── Profiles ──

  Future<Profile?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data != null ? Profile.fromJson(data) : null;
  }

  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (updates.isNotEmpty && _userId != null) {
      await _client.from('profiles').update(updates).eq('id', _userId!);
    }
  }

  // ── Scam Messages ──

  Future<ScamMessage> insertScamMessage(ScamMessage message) async {
    final data = await _client
        .from('scam_messages')
        .insert(message.toJson())
        .select()
        .single();
    return ScamMessage.fromJson(data);
  }

  Future<List<ScamMessage>> getRecentScamMessages({int limit = 20}) async {
    final data = await _client
        .from('scam_messages')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map((e) => ScamMessage.fromJson(e)).toList();
  }

  Future<List<ScamMessage>> getUserScamMessages() async {
    if (_userId == null) return [];
    final data = await _client
        .from('scam_messages')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);
    return data.map((e) => ScamMessage.fromJson(e)).toList();
  }

  // ── Scam Numbers ──

  Future<String> reportScamNumber({
    required String phoneNumber,
    required String scamType,
    String? region,
    double? latitude,
    double? longitude,
  }) async {
    final result = await _client.rpc(
      'report_scam_number',
      params: {
        'p_phone_number': phoneNumber,
        'p_scam_type': scamType,
        'p_reported_by': _userId,
        'p_region': region,
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );
    return result as String;
  }

  Future<ScamNumber?> searchScamNumber(String phoneNumber) async {
    final data = await _client
        .from('scam_numbers')
        .select()
        .eq('phone_number', phoneNumber)
        .maybeSingle();
    return data != null ? ScamNumber.fromJson(data) : null;
  }

  Future<List<ScamNumber>> getTopReportedNumbers({int limit = 20}) async {
    final data = await _client
        .from('scam_numbers')
        .select()
        .order('reports_count', ascending: false)
        .limit(limit);
    return data.map((e) => ScamNumber.fromJson(e)).toList();
  }

  Future<List<ScamNumber>> getScamNumbersWithLocation() async {
    final data = await _client
        .from('scam_numbers')
        .select()
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);
    return data.map((e) => ScamNumber.fromJson(e)).toList();
  }

  // ── Community Reports ──

  Future<CommunityReport> insertCommunityReport(CommunityReport report) async {
    final data = await _client
        .from('community_reports')
        .insert(report.toJson())
        .select()
        .single();
    return CommunityReport.fromJson(data);
  }

  Future<List<CommunityReport>> getCommunityReports({
    int limit = 50,
    String? filterType,
  }) async {
    var query = _client.from('community_reports').select('''
      *,
      profiles!reporter_id(name),
      scam_messages(*),
      scam_numbers(*)
    ''');

    if (filterType != null) {
      query = query.eq('report_type', filterType);
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return data.map((e) => CommunityReport.fromJson(e)).toList();
  }

  Future<List<CommunityReport>> getUserReports() async {
    if (_userId == null) return [];
    final data = await _client
        .from('community_reports')
        .select('''
          *,
          profiles!reporter_id(name),
          scam_messages(*),
          scam_numbers(*)
        ''')
        .eq('reporter_id', _userId!)
        .order('created_at', ascending: false);
    return data.map((e) => CommunityReport.fromJson(e)).toList();
  }

  // ── Stats ──

  Future<Map<String, dynamic>> getScamStats() async {
    final result = await _client.rpc('get_scam_stats');
    return result as Map<String, dynamic>;
  }
}
