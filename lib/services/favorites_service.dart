import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'kitara_favorites';

  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<bool> isFavorite(String bookId) async {
    final favorites = await getFavorites();
    return favorites.contains(bookId);
  }

  Future<void> toggleFavorite(String bookId) async {
    final prefs = await SharedPreferences.getInstance();

    final favorites =
        prefs.getStringList(_key)?.toSet() ?? <String>{};

    if (favorites.contains(bookId)) {
      favorites.remove(bookId);
    } else {
      favorites.add(bookId);
    }

    await prefs.setStringList(
      _key,
      favorites.toList(),
    );
  }

  Future<void> removeFavorite(String bookId) async {
    final prefs = await SharedPreferences.getInstance();

    final favorites =
        prefs.getStringList(_key)?.toSet() ?? <String>{};

    favorites.remove(bookId);

    await prefs.setStringList(
      _key,
      favorites.toList(),
    );
  }

  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
