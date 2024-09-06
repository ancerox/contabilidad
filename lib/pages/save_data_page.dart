import 'dart:async';

import 'package:contabilidad/database/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  _BackupPageState createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  String? lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
    _scheduleDailyBackup();
  }

  Future<void> _loadLastBackupTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      lastBackupTime = prefs.getString('lastBackupTime');
    });
  }

  Future<void> _updateLastBackupTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentTime = DateTime.now().toString();
    await prefs.setString('lastBackupTime', currentTime);
    setState(() {
      lastBackupTime = currentTime;
    });
  }

  void _scheduleDailyBackup() {
    // Programa el backup a las 11:59 PM todos los días
    Timer.periodic(const Duration(hours: 24), (timer) {
      var now = DateTime.now();
      if (now.hour == 23 && now.minute == 59) {
        _performBackup();
      }
    });
  }

  Future<void> _performBackup() async {
    await Provider.of<DataBase>(context, listen: false)
        .backupDatabase()
        .then((e) {});

    await _updateLastBackupTime().then((value) {});
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copia de Seguridad de la Base de Datos'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (lastBackupTime != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Última copia de seguridad: $lastBackupTime',
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.backup),
                label: const Text('Realizar copia ahora'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                  textStyle: const TextStyle(fontSize: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () async {
                  await _performBackup();
                },
              ),
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_download),
                label: const Text('Cargar datos desde JSON'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 15.0),
                  textStyle: const TextStyle(fontSize: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () async {
                  await Provider.of<DataBase>(context, listen: false)
                      .loadDataFromJson();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            '¡Datos cargados desde el archivo JSON con éxito!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
