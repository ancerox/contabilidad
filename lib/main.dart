import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/pages/history.dart';
import 'package:contabilidad/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pay/pay.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform); // Initialize Firebase before running the app
  initializeDateFormatting("es_ES");
  scheduleDailyBackup();
  runApp(const MyApp());
}

Stream<void> backupStream() async* {
  while (true) {
    await Future.delayed(const Duration(hours: 24));
    var now = DateTime.now();
    if (now.hour == 23 && now.minute == 59) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await performBackup();
      String currentTime = DateTime.now().toString();
      await prefs.setString('lastBackupTime', currentTime);
    }
    // Emit an event after every backup check
  }
}

void scheduleDailyBackup() {
  backupStream().listen((_) {
    // Nothing needed here as the stream handles the backup
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
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const AccessCheckerScreen(), // Access check added here
      ),
    );
  }
}

class AccessCheckerScreen extends StatefulWidget {
  const AccessCheckerScreen({super.key});

  @override
  _AccessCheckerScreenState createState() => _AccessCheckerScreenState();
}

class _AccessCheckerScreenState extends State<AccessCheckerScreen> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> accessStream;

  @override
  void initState() {
    super.initState();
    accessStream = FirebaseFirestore.instance
        .collection('access')
        .doc('3ANSo2ladkNe2hwdpvvt') // Replace with your actual document ID
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: accessStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ); // Show a loading screen while checking access
        }

        try {
          if (snapshot.hasError) {
            throw snapshot.error!;
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(
              body: Container(
                color: Colors.white,
              ), // Show a white screen if access is denied or an error occurs
            );
          }

          bool access = snapshot.data!.data()?['IsAccess'] ?? false;
          if (!access) {
            return Scaffold(
              body: Container(
                color: Colors.white,
              ), // Show a white screen if access is denied
            );
          } else {
            return const SubscriptionScreen(); // Proceed to the actual app if access is granted
          }
        } catch (e) {
          print("Error in access stream: $e");
          return const Scaffold(
            body: Center(
              child: Text(
                'An error occurred while checking access.',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          );
        }
      },
    );
  }
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  PaymentConfiguration? _paymentConfiguration;

  @override
  void initState() {
    super.initState();
    _loadPaymentConfiguration();
  }

  Future<void> _loadPaymentConfiguration() async {
    final config = await PaymentConfiguration.fromAsset('payment_profile.json');
    setState(() {
      _paymentConfiguration = config;
    });
  }

  final _paymentItems = const [
    PaymentItem(
      label: 'Total',
      amount: '59.99',
      status: PaymentItemStatus.final_price,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.indigo],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(
                'Contabilidad',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const Column(
                children: [
                  FeatureCard(
                    icon: Icons.attach_money_rounded,
                    title: 'Realiza cobros y pagos fácilmente',
                  ),
                  FeatureCard(
                    icon: Icons.inventory_rounded,
                    title: 'Gestión de órdenes e inventario en un solo lugar',
                  ),
                  FeatureCard(
                    icon: Icons.bar_chart_rounded,
                    title:
                        'Analiza tus ganancias y pérdidas con gráficas detalladas',
                  ),
                  FeatureCard(
                    icon: Icons.pie_chart_rounded,
                    title:
                        'Monitorea hacia dónde van tus gastos: servicios, materia prima, mano de obra y más',
                  ),
                  FeatureCard(
                    icon: Icons.insert_chart_rounded,
                    title:
                        'Accede a informes personalizados para optimizar tu negocio',
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HomePage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Prueba 30 Días Gratis',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _paymentConfiguration == null
                  ? const CircularProgressIndicator()
                  : GooglePayButton(
                      paymentConfiguration: _paymentConfiguration!,
                      paymentItems: _paymentItems,
                      type: GooglePayButtonType.pay,
                      margin: const EdgeInsets.only(top: 15.0),
                      onPaymentResult: (paymentResult) {
                        // Handle payment result here
                        print(paymentResult);
                      },
                      loadingIndicator: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const FeatureCard({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5,
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.indigo,
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
