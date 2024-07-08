import 'package:contabilidad/database/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Database'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Access the DataBase provider and perform the backup
                await Provider.of<DataBase>(context, listen: false)
                    .backupDatabase();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Database backed up successfully!')),
                );
              },
              child: const Text('Backup Now'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // Access the DataBase provider and load data from a JSON file
                await Provider.of<DataBase>(context, listen: false)
                    .loadDataFromJson();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Data loaded from JSON file successfully!')),
                );
              },
              child: const Text('Load Data from JSON'),
            ),
          ],
        ),
      ),
    );
  }
}
