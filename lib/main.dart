import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/shopping_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/home_screen_provider.dart';
import 'providers/invite_screen_provider.dart';
import 'providers/add_item_screen_provider.dart';
import 'providers/custom_categories_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise SQLite for web via sqflite_common_ffi_web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingProvider()),
        ChangeNotifierProvider(create: (_) => CustomCategoriesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => HomeScreenProvider()),
        ChangeNotifierProvider(create: (_) => InviteScreenProvider()),
        ChangeNotifierProvider(create: (_) => AddItemScreenProvider()),
      ],
      child: const ShopShareApp(),
    ),
  );
}