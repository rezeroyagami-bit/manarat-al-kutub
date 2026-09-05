import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book.dart';
import '../models/magazine_issue.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Book>> getBooks() async {
    final response = await _client
        .from('books')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Book.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> validateKitaraActivationCode(String code) async {
    final response = await _client.rpc(
      'validate_kitara_activation_code',
      params: {'p_code': code},
    );
    return response == true;
  }

  Future<int> getCoinBalance(String deviceId) async {
    final response = await _client.rpc(
      'get_kitara_coin_balance',
      params: {'p_device_id': deviceId},
    );
    return response is int ? response : int.tryParse(response.toString()) ?? 0;
  }

  Future<int> awardCoin(String deviceId) async {
    final response = await _client.rpc(
      'award_kitara_coin',
      params: {'p_device_id': deviceId},
    );
    return response is int ? response : int.tryParse(response.toString()) ?? 0;
  }

  Future<List<MagazineIssue>> getMagazineIssues(String magazineId) async {
    final response = await _client
        .from('magazine_issues')
        .select()
        .eq('magazine_id', magazineId)
        .order('issue_number', ascending: true);

    return (response as List)
        .map((item) => MagazineIssue.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> getMagazineByName(String name) async {
    final response = await _client
        .from('magazines')
        .select()
        .eq('name', name)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getMagazines() async {
    final response = await _client
        .from('magazines')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getNewsTicker() async {
    final response = await _client
        .from('news_ticker')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }
}
