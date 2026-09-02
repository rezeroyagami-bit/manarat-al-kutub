import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase_config.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const ManaratApp());
}

class ManaratApp extends StatelessWidget {
  const ManaratApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'منارة الكتب',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4B3F72),
      ),
      home: const AppShell(),
    );
  }
}
