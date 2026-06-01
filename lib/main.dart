import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/database_helper.dart';
import 'data/sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Inicializa la base de datos local (crea tablas si es primera vez) y
  // arranca el SyncService que escucha cambios de conectividad.
  await DatabaseHelper.instance.database;
  await SyncService.instance.start();

  final prefs = await SharedPreferences.getInstance();
  final userDataString = prefs.getString('userData');
  Map<String, dynamic>? userData;
  if (userDataString != null) {
    userData = jsonDecode(userDataString);
  }

  runApp(MyApp(initialUserData: userData));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? initialUserData;

  const MyApp({super.key, this.initialUserData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Créditos Tarrillo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00236F), // Primary color from design
        ),
        useMaterial3: true,
      ),
      home: initialUserData != null ? HomeScreen(userData: initialUserData) : const LoginScreen(),
    );
  }
}
