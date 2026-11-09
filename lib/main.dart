import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/security/database_key.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureSqlCipher();
  runApp(const ProviderScope(child: NearShareApp()));
}
