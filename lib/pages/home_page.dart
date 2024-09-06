import 'package:contabilidad/consts.dart';
import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/pages/buy_screen.dart';
import 'package:contabilidad/pages/create_charge_screen.dart';
import 'package:contabilidad/pages/create_order.dart';
import 'package:contabilidad/pages/history.dart';
import 'package:contabilidad/pages/save_data_page.dart';
import 'package:contabilidad/pages/stock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final listOfActionsSVGs = [
    'assets/icons/compra.svg',
    'assets/icons/ordenes.svg',
    'assets/icons/cobro.svg'
  ];
  final listOfActionsTexts = ['Compra', 'Orden', 'Cobro'];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTimeRange? selectedDateRange;
  @override
  void initState() {
    // TODO: implement initState
    didChangeDependencies();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Configuración',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BackupPage()));
              },
              child: const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Datos'),
              ),
            ),
          ],
        ),
      ),
      key: _scaffoldKey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = MediaQuery.of(context).size.width;
              double cardWidth = (screenWidth - 40) / 2;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: SvgPicture.asset('assets/icons/ep_menu.svg'),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HistoryScreen(),
                                    ),
                                  );
                                },
                                child: CardWidget(
                                  isFull: false,
                                  icon: 'assets/icons/ventas.svg',
                                  count: 2,
                                  title: "Historial de ventas",
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.topRight,
                                    colors: [
                                      Color(0xff5100FF),
                                      Color(0xff9F72FF),
                                    ],
                                  ),
                                  width: cardWidth,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // GestureDetector(
                              //   onTap: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder: (context) =>
                              //             const PendingScreen(),
                              //       ),
                              //     );
                              //   },
                              //   child: CardWidget(
                              //     isFull: false,
                              //     icon: 'assets/icons/pendientes.svg',
                              //     count: 2,
                              //     title: "Órdenes pendientes",
                              //     gradient: const LinearGradient(
                              //       begin: Alignment.centerLeft,
                              //       end: Alignment.topRight,
                              //       colors: [
                              //         Color(0xffF32FDF),
                              //         Color(0xffF32FDF),
                              //       ],
                              //     ),
                              //     width: cardWidth,
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StockScreen(),
                                ),
                              );
                            },
                            child: CardWidget(
                              isFull: true,
                              icon: 'assets/icons/inventario.svg',
                              count: 2,
                              title: "Manejo inventario",
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.topRight,
                                colors: [
                                  Color(0xff04AFD3),
                                  Color(0xff04AFD3),
                                ],
                              ),
                              width: screenWidth - cardWidth - 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Acciones rápidas',
                        style: subtitles.copyWith(color: Colors.black),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 130,
                        child: Center(
                          child: ListView.builder(
                            itemCount: 3,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  quickActionsChoose(context, index);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: QuickActions(
                                    icon: listOfActionsSVGs[index],
                                    subtitle: listOfActionsTexts[index],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Estadísticas',
                        style: subtitles.copyWith(color: Colors.black),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () async {
                          final pickedDateRange = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDateRange != null) {
                            setState(() {
                              selectedDateRange = pickedDateRange;
                            });
                          }
                        },
                        child: Text(
                          selectedDateRange == null
                              ? 'Seleccionar intervalo de fechas'
                              : '${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}',
                        ),
                      ),
                      const SizedBox(height: 15),
                      FutureBuilder<Map<String, double>>(
                        future: _calcularTotales(context),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return const Text('Error al calcular los totales.');
                          } else {
                            final totals = snapshot.data ??
                                {
                                  'ventas': 0.0,
                                  'costo': 0.0,
                                  'ganancias': 0.0,
                                };
                            final totalVentas = totals['ventas']!;
                            final totalCosto = totals['costo']!;
                            final totalGanancias = totals['ganancias']!;
                            final puntoDeEquilibrio =
                                totals['puntoEquilibrio']!;

                            return Column(
                              children: [
                                Center(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Statistics(
                                              color: 0xff9C4CFD,
                                              text:
                                                  'Ingresos \n\$${totalVentas.toStringAsFixed(2)}',
                                              percentage: totalVentas > 0
                                                  ? (totalVentas / 1000)
                                                      .clamp(0.0, 1.0)
                                                  : 0.0,
                                            ),
                                            Statistics(
                                              color: 0xff0EB200,
                                              text:
                                                  'Ganancias \n\$${totalGanancias.toStringAsFixed(2)}',
                                              percentage: totalGanancias > 0
                                                  ? (totalGanancias / 500)
                                                      .clamp(0.0, 1.0)
                                                  : 0.0,
                                            ),
                                            Statistics(
                                              color: 0xffF85819,
                                              text:
                                                  'Gastos \n\$${totalCosto.toStringAsFixed(2)}',
                                              percentage: totalCosto > 0
                                                  ? (totalCosto / 800)
                                                      .clamp(0.0, 1.0)
                                                  : 0.0,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Punto de equilibrio',
                                        style: subtitles.copyWith(
                                            color: Colors.black),
                                      ),
                                      const SizedBox(height: 10),
                                      LinearProgressIndicator(
                                        value: puntoDeEquilibrio.clamp(0.0,
                                            1.0), // Ajusta el valor entre 0 y 1
                                        backgroundColor: Colors.grey[300],
                                        color: Colors
                                            .blue, // Cambia el color según tu preferencia
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${(puntoDeEquilibrio * 100).toStringAsFixed(2)}%',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<Map<String, double>> _calcularTotales(BuildContext context) async {
    final dataBase = Provider.of<DataBase>(context, listen: false);
    final orders = await dataBase.getAllOrdersWithProducts();

    double totalVentas = 0.0;
    double totalCosto = 0.0;
    double totalGanancias = 0.0;

    if (selectedDateRange != null) {
      for (var order in orders) {
        if (order.status == "Pago") {
          if (order.productList != null && order.productList!.isNotEmpty) {
            final orderDate = _parseDate(order.date);
            if (orderDate != null &&
                orderDate.isAfter(selectedDateRange!.start) &&
                orderDate.isBefore(selectedDateRange!.end)) {
              for (var product in order.productList!) {
                final ventas = product.quantity!.value * product.unitPrice;
                final costo = product.quantity!.value * product.cost;
                final ganancia = ventas - costo;

                totalVentas += ventas;
                totalCosto += costo;
                totalGanancias += ganancia;
              }
            }
          } else {
            totalVentas += order.totalCost;
            totalGanancias += order.totalCost;
          }
        }
      }
    } else {
      for (var order in orders) {
        if (order.status == "Pago") {
          if (order.productList != null && order.productList!.isNotEmpty) {
            for (var product in order.productList!) {
              final ventas = order.totalCost;
              final costo = product.quantity!.value * product.cost;
              final ganancia = ventas - costo;

              totalVentas += ventas;
              totalCosto += costo;
              totalGanancias += ganancia;
            }
          } else {
            totalVentas += order.totalCost;
            totalGanancias += order.totalCost;
          }
        }
      }
    }

    final puntoDeEquilibrio = totalCosto != 0
        ? totalCosto
        : 0.0; // Si no hay costo, el punto de equilibrio es 0.

    return {
      'ventas': totalVentas,
      'costo': totalCosto,
      'ganancias': totalGanancias,
      'puntoEquilibrio': puntoDeEquilibrio,
    };
  }

  DateTime? _parseDate(String date) {
    try {
      return DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS").parse(date);
    } catch (e) {
      try {
        return DateFormat("MM/dd/yyyy").parse(date);
      } catch (e) {
        print("Error al analizar la fecha: $date - $e");
        return null;
      }
    }
  }

  void quickActionsChoose(context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const CreateOrderScreen(
                    isEditPage: false,
                  )),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AgregarCobroPage()),
        );
        break;
      default:
        break;
    }
  }
}

class Statistics extends StatelessWidget {
  final String text;
  final int color;
  final double percentage;

  const Statistics({
    required this.color,
    required this.text,
    required this.percentage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        border: Border.all(width: 1.5, color: const Color(0xffD0A6FA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(color),
                    ),
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FittedBox(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  final String icon;
  final String subtitle;

  const QuickActions({
    required this.icon,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 40,
              child: SvgPicture.asset(icon),
            ),
            const Positioned(
              right: -5,
              bottom: -5,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xffC145FE),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class CardWidget extends StatelessWidget {
  final String title;
  final int count;
  final Gradient gradient;
  final String icon;
  final bool isFull;
  final double width;

  const CardWidget({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.isFull,
    required this.gradient,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 175,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: gradient,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 25,
            child: CircleAvatar(
              maxRadius: 16.0,
              backgroundColor: Colors.white,
              child: SvgPicture.asset(
                icon,
                height: 20,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            child: Text(
              title,
              style: subtitles.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
