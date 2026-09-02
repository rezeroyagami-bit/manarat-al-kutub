import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Book>> getBooks() async {
    final response = await _client
        .from('books')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Book.fromMap(item))
        .toList();
  }
}
