import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book.dart';
import '../models/magazine_issue.dart';

class SupabaseService {
  final SupabaseClient _client =
      Supabase.instance.client;

  Future<List<Book>> getBooks() async {
    final response = await _client
        .from('books')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => Book.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<bool> validateBookAccess({
    required String bookId,
    required String code,
  }) async {
    final response = await _client.rpc(
      'validate_book_access',
      params: {
        'p_book_id': bookId,
        'p_code': code,
      },
    );

    return response == true;
  }

  Future<List<MagazineIssue>> getMagazineIssues(
    String magazineId,
  ) async {
    final response = await _client
        .from('magazine_issues')
        .select()
        .eq('magazine_id', magazineId)
        .order('issue_number', ascending: true);

    return (response as List)
        .map(
          (item) => MagazineIssue.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>?> getMagazineByName(
    String name,
  ) async {
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
        .map(
          (item) => item as Map<String, dynamic>,
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getNewsTicker() async {
    final response = await _client
        .from('news_ticker')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .map(
          (item) => item as Map<String, dynamic>,
        )
        .toList();
  }
}
