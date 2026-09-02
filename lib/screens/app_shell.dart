import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'favorites_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Book> books = [];
  bool loading = true;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      final result = await _supabaseService.getBooks();

      if (mounted) {
        setState(() {
          books = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screens = [
      HomeScreen(
        books: books,
        onTheme: () {},
      ),
      LibraryScreen(books: books),
      FavoritesScreen(books: books),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'المكتبة',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'المفضلة',
          ),
        ],
      ),
    );
  }
}
