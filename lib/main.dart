import 'dart:async';

import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  initializeDateFormatting("es_ES");
  scheduleDailyBackup();
  runApp(const MyApp());
}

void scheduleDailyBackup() {
  Timer.periodic(const Duration(hours: 24), (timer) async {
    var now = DateTime.now();
    if (now.hour == 23 && now.minute == 59) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await performBackup();
      String currentTime = DateTime.now().toString();
      await prefs.setString('lastBackupTime', currentTime);
    }
  });
}

Future<void> performBackup() async {
  // Assuming DataBase instance is initialized here
  DataBase dataBase = DataBase();
  await dataBase.backupDatabase();
  // You can also add additional logging or feedback here if needed
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DataBase(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: HomePage(),
      ),
    );
  }
}
