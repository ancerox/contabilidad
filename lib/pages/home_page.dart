import 'package:contabilidad/consts.dart';
import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/pages/buy_screen.dart';
import 'package:contabilidad/pages/create_charge_screen.dart';
import 'package:contabilidad/pages/create_order.dart';
import 'package:contabilidad/pages/gasto_screen.dart';
import 'package:contabilidad/pages/history.dart';
import 'package:contabilidad/pages/save_data_page.dart';
import 'package:contabilidad/pages/stock_screen.dart';
import 'package:fl_chart/fl_chart.dart';
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
  final List<String> listOfActionsSVGs = [
    'assets/icons/compra.svg',
    'assets/icons/ordenes.svg',
    'assets/icons/cobro.svg',
    'assets/icons/money-cash-svgrepo-com.svg'
  ];
  final List<String> listOfActionsTexts = ['Compra', 'Orden', 'Cobro', 'Gasto'];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTimeRange? selectedDateRange;
  late Future<Map<String, double>>? totalesFuture;

  final List<DateTime> ventasDatesOrders = [];
  final List<double> totalVentasList = [];
  bool isvalue6digit = false;

  @override
  void initState() {
    super.initState();
    totalesFuture = _calcularTotales();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      totalesFuture = _calcularTotales(); // Refresh the future
    });
  }

  List<String> options1 = ['Option 1', 'Option 2', 'Option 3'];
  List<String> options2 = ['Option A', 'Option B', 'Option C'];

  bool limpiarFiltro = false;

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
                        MaterialPageRoute(builder: (_) => const BackupPage()))
                    .then((_) {
                  // Refresh the totals when coming back
                  setState(() {
                    totalesFuture = _calcularTotales();
                  });
                });
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
                                  ).then((_) {
                                    // Refresh the totals when coming back
                                    setState(() {
                                      totalesFuture = _calcularTotales();
                                    });
                                  });
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
                              // Uncomment and customize if needed
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
                              ).then((_) {
                                // Refresh the totals when coming back
                                setState(() {
                                  totalesFuture = _calcularTotales();
                                });
                              });
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
                            shrinkWrap: true,
                            itemCount: 4,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  quickActionsChoose(context, index);
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 7),
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
                      const SizedBox(height: 5),
                      Text(
                        'Resumen Financiero',
                        style: subtitles.copyWith(color: Colors.black),
                      ),
                      const SizedBox(height: 10),
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
                              totalesFuture =
                                  _calcularTotales(); // Refresh data
                              limpiarFiltro = true;
                            });
                          }
                        },
                        child: Row(
                          children: [
                            Text(
                              selectedDateRange == null
                                  ? 'Seleccionar intervalo de fechas'
                                  : '${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}',
                            ),
                            limpiarFiltro == true
                                ? TextButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedDateRange = null;
                                        totalesFuture =
                                            _calcularTotales(); // Actualiza los totales sin filtro
                                      });
                                    },
                                    child: const Text('Limpiar filtro'))
                                : Container()
                          ],
                        ),
                      ),
                      FutureBuilder<Map<String, double>>(
                        future: totalesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error al calcular los totales.'));
                          } else {
                            final totals = snapshot.data ??
                                {
                                  'ventas': 0.0,
                                  'costo': 0.0,
                                  'efectivo': 0.0,
                                  'gastos': 0.0,
                                  'puntoEquilibrio': 0.0,
                                };
                            final double totalVentas = totals['ventas']!;
                            final double totalCosto = totals['costo']!;
                            final double totalGanancias = totals['efectivo']!;
                            final double puntoDeEquilibrio =
                                totals['puntoEquilibrio']!;
                            final double totalGastos = totals['gastos'] ?? 0.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Statistics Section
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Statistics(
                                            icon:
                                                const Icon(Icons.attach_money),
                                            color: 0xff4CAF50,
                                            text: 'Ventas',
                                            percentage: totalVentas,
                                          ),
                                          Statistics(
                                            icon: const Icon(Icons.money_off),
                                            color: 0xff9C4CFD,
                                            text: 'Efectivo',
                                            percentage: totalGanancias,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Statistics(
                                            icon: const Icon(Icons.money),
                                            color: 0xffF85819,
                                            text: 'Gastos',
                                            percentage: totalGastos,
                                          ),
                                          Statistics(
                                              icon: const Icon(
                                                  Icons.shopping_cart),
                                              color: 0xffFFEA00,
                                              text: 'Costo ordenes',
                                              percentage: totalCosto),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Line Chart Section
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(
                                            0, 3), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ventas en las últimas 8 semanas',
                                        style: subtitles.copyWith(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 200,
                                        child: _buildLineChart(),
                                      ),
                                    ],
                                  ),
                                ),
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

  String formatNumberWithCommas(double number) {
    final formatter =
        NumberFormat('#,##0'); // Add commas and keep 2 decimal places
    return formatter.format(number);
  }

  /// Builds the Line Chart using fl_chart package
  Widget _buildLineChart() {
    if (ventasDatesOrders.isEmpty || totalVentasList.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar.'));
    }

    // Combine the date and sales lists
    List<MapEntry<DateTime, double>> combinedList = List.generate(
      ventasDatesOrders.length,
      (index) => MapEntry(ventasDatesOrders[index], totalVentasList[index]),
    );

    // Sort the list by DateTime
    combinedList.sort((a, b) => a.key.compareTo(b.key));

    // Get today's date
    DateTime now = DateTime.now();

// Calculate the start of the current week (assuming week starts on Monday)
    int daysToSubtract = now.weekday - DateTime.sunday;
    DateTime startOfCurrentWeek = now.subtract(Duration(days: daysToSubtract));

// Define the date 8 weeks ago from the start of the current week
    DateTime eightWeeksAgo =
        startOfCurrentWeek.subtract(const Duration(days: 56));

// Filter data within the last 8 weeks and aggregate it by week
// Filter data within the last 8 weeks and aggregate it by week
    Map<int, double> weeklyTotals = {};
    for (var entry in combinedList) {
      if (entry.key.isAfter(eightWeeksAgo) ||
          entry.key.isAtSameMomentAs(eightWeeksAgo)) {
        // Calculate the week number from the start of the current week
        int weekOfYear = (entry.key.difference(eightWeeksAgo).inDays ~/ 7);
        if (weeklyTotals.containsKey(weekOfYear)) {
          weeklyTotals[weekOfYear] = weeklyTotals[weekOfYear]! + entry.value;
        } else {
          weeklyTotals[weekOfYear] = entry.value;
        }
      }
    }
    // Create FlSpots from the aggregated weekly data
    // Create FlSpots from the aggregated weekly data
    List<FlSpot> spots = [];

// Ensure we have an entry for each of the 8 weeks (even if no sales were made)
    // Ensure we have an entry for each of the 8 weeks (even if no sales were made)
    for (int week = 0; week <= 7; week++) {
      if (weeklyTotals.containsKey(week)) {
        spots.add(FlSpot(week.toDouble(), weeklyTotals[week]!));
      } else {
        // No sales for this week, so we set the value to 0
        spots.add(FlSpot(week.toDouble(), 0));
      }
    }

    if (spots.isEmpty) {
      return const Center(
          child: Text('No hay datos en las últimas 8 semanas.'));
    }

    // Define min and max for X axis
    double minX = 0;
    double maxX = 7; // Should represent 0 to 7 for 8 weeks.
    // Define min and max for Y axis
    double minY = weeklyTotals.values.fold<double>(
        double.infinity, (prev, element) => element < prev ? element : prev);
    double maxY = weeklyTotals.values.fold<double>(double.negativeInfinity,
        (prev, element) => element > prev ? element : prev);

    minY = (minY > 0) ? 0 : minY;
    maxY = maxY + (maxY * 0.1); // Add 10% padding on top

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1, // 1 label per week
              getTitlesWidget: (value, meta) {
                DateTime currentDate = DateTime.now();

                // Step 2: Calculate the start of the current week (assuming weeks start on Monday)
                DateTime currentWeekStart =
                    currentDate.subtract(Duration(days: currentDate.weekday));

                // Step 3: Go back 8 weeks from the current week start
                DateTime weekStart = currentWeekStart
                    .subtract(Duration(days: (7 * (7 - value.toInt()))));

                // Step 4: Format the weekStart date for display
                String formattedDate = DateFormat('dd/MM').format(weekStart);

                // Step 5: Return the formatted date as a widget
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY - minY) / 5,
              getTitlesWidget: (value, meta) {
                isvalue6digit = value.toString().length > 5 ? true : false;
                // setState(() {});
                return Text(
                  "\$ ${formatNumberWithCommas(value)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 65,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            preventCurveOverShooting: true,
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [
                Color(0xff4CAF50),
                Color(0xff81C784),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: true,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.3),
                  Colors.green.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                DateTime weekStart =
                    eightWeeksAgo.add(Duration(days: spot.x.toInt() * 7));
                String formattedDate =
                    DateFormat('dd/MM/yyyy').format(weekStart);
                return LineTooltipItem(
                  '$formattedDate\n\$${spot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Future<Map<String, double>> _calcularTotales() async {
    final dataBase = Provider.of<DataBase>(context, listen: false);

    final orders = await dataBase.getAllOrdersWithProducts();
    double totalVentas = 0.0;
    double totalCostoOrdenes = 0.0;
    double totalEfectivo = 0.0;
    double totalGastos = 0.0;
    double totalInversion = 0.0;
    double sumatoriaCompra = 0.0;
    double totalProduccion = 0.0;

    // Clear previous data to avoid duplicates
    ventasDatesOrders.clear();
    totalVentasList.clear();

    if (selectedDateRange != null) {
      for (var order in orders) {
        if (order.productList != null && order.productList!.isNotEmpty) {
          final orderDate = parseDate(order.date);
          if (orderDate != null &&
              (orderDate.isAfter(selectedDateRange!.start
                      .subtract(const Duration(days: 1))) &&
                  orderDate.isBefore(
                      selectedDateRange!.end.add(const Duration(days: 1))))) {
            // Process order
            if (order.status == "Costo de orden") {
              final costos = order.totalCost;
              totalCostoOrdenes += costos;
            }
            if (order.status == "Pago" && order.margen.isNotEmpty) {
              final ventas = order.totalCost;
              DateTime? ventaDate = parseDate(order.date);
              if (ventaDate != null && ventas > 0) {
                ventasDatesOrders.add(ventaDate);
                totalVentasList.add(ventas);
              }
              totalVentas += ventas;
            }
            if (order.status == "Pago" && order.margen.isEmpty) {
              final inversion = order.totalCost;
              totalInversion += inversion;
            }

            if (order.status == "Gasto" && order.margen.isEmpty) {
              final gastos = order.totalCost;
              totalGastos += gastos;
            }

            if (order.status == "Compra" && order.margen.isNotEmpty) {
              final compra = order.totalCost;
              sumatoriaCompra += compra;
            }
            if (order.status == "Produccion" && order.margen.isNotEmpty) {
              final produccion = order.totalCost;
              totalProduccion += produccion;
            }
            totalEfectivo =
                (totalVentas + totalInversion + totalProduccion.abs()) -
                    sumatoriaCompra -
                    totalGastos;
          }
        }
      }
    } else {
      for (var order in orders) {
        if (order.status == "Costo de orden") {
          final costos = order.totalCost;
          totalCostoOrdenes += costos;
        }
        if (order.status == "Pago" && order.margen.isNotEmpty) {
          final ventas = order.totalCost;
          DateTime? ventaDate = parseDate(order.date);
          if (ventaDate != null && ventas > 0) {
            ventasDatesOrders.add(ventaDate);
            totalVentasList.add(ventas);
          }
          totalVentas += ventas;
        }
        if (order.status == "Pago" && order.margen.isEmpty) {
          final inversion = order.totalCost;
          totalInversion += inversion;
        }

        if (order.status == "Gasto" && order.margen.isEmpty) {
          final gastos = order.totalCost;
          totalGastos += gastos;
        }

        if (order.status == "Compra" && order.margen.isNotEmpty) {
          final compra = order.totalCost;
          sumatoriaCompra += compra;
        }
        if (order.status == "Produccion" && order.margen.isNotEmpty) {
          final produccion = order.totalCost;
          totalProduccion += produccion;
        }
        totalEfectivo = (totalVentas + totalInversion + totalProduccion.abs()) -
            sumatoriaCompra -
            totalGastos;
      }
    }

    final double puntoDeEquilibrio =
        totalCostoOrdenes != 0 ? totalCostoOrdenes : 0.0; // Equilibrium point

    return {
      'ventas': totalVentas,
      'costo': totalCostoOrdenes,
      'efectivo': totalEfectivo,
      'gastos': totalGastos,
      'puntoEquilibrio': puntoDeEquilibrio,
    };
  }

  DateTime? parseDate(String date) {
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
        ).then((_) {
          // Refresh the totals when coming back
          setState(() {
            totalesFuture = _calcularTotales();
          });
        });
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const CreateOrderScreen(
                    isEditPage: false,
                  )),
        ).then((_) {
          // Refresh the totals when coming back
          setState(() {
            totalesFuture = _calcularTotales();
          });
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AgregarCobroPage()),
        ).then((_) {
          // Refresh the totals when coming back
          setState(() {
            totalesFuture = _calcularTotales();
          });
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AgregarGastoPage()),
        ).then((_) {
          // Refresh the totals when coming back
          setState(() {
            totalesFuture = _calcularTotales();
          });
        });
        break;
      default:
        break;
    }
  }
}

class Statistics extends StatelessWidget {
  final Widget icon;
  final String text;
  final int color;
  final double percentage;

  const Statistics({
    required this.color,
    required this.text,
    required this.percentage,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      width: MediaQuery.of(context).size.width / 2.4, // Adjusted width
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.07,
            ),
            offset: const Offset(0, 0),
            blurRadius: 5,
          )
        ],
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: [
        //     const Color.fromARGB(255, 255, 255, 255).withOpacity(0.5),
        //     const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
        //     const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
        //   ],
        //   stops: const [0, 100, 100],
        // ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
        child: CustomPaint(
          painter: GradientPainter(padding: -5, widthPadding: -0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(
                      value: 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(color),
                      ),
                    ),
                  ),
                  const Text(
                    '\$',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                  ),
                ],
              ),
              Text(
                "\$${formatNumberWithCommas(percentage)}", // Format the percentage with commas
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end, // Align the text to the right
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatNumberWithCommas(double number) {
    final formatter =
        NumberFormat('#,##0'); // Add commas and keep 2 decimal places
    return formatter.format(number);
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
              child: SvgPicture.asset(
                icon,
                fit: BoxFit.contain,
                height: 30,
              ),
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

class GradientPainter extends CustomPainter {
  final double padding; // Padding for the height
  final double widthPadding; // New parameter for padding the width

  GradientPainter({
    this.padding = 0,
    this.widthPadding = 0,
  }); // Padding for height and width as parameters

  @override
  void paint(Canvas canvas, Size size) {
    // Reduce width and height by the respective padding values
    final double paddedWidth = size.width - widthPadding * 2;
    final double paddedHeight = size.height - padding * 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.025) // Black with 25% opacity
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 4); // Blur radius of 4

    // Define the rectangle and rounded rectangle for the shadow
    final startShadow = Offset(widthPadding, padding);
    final endShadow =
        Offset(paddedWidth + widthPadding, paddedHeight + padding);
    final rectShadow = Rect.fromPoints(startShadow, endShadow);
    final rRectShadow = RRect.fromRectAndRadius(
        rectShadow
            .shift(const Offset(0, 4)), // Offset Y by 4 to create shadow effect
        const Radius.circular(20));

    // Draw the shadow
    canvas.drawRRect(rRectShadow, shadowPaint);

    // Create the gradient for the stroke
    final gradient = LinearGradient(
      colors: [
        Colors.black,
        const Color.fromARGB(255, 8, 74, 74).withOpacity(0.7),
        const Color(0xff111919),
      ],
      begin: Alignment.centerLeft, // Start at center left
      end: Alignment.centerRight, // End at center right
    );

    final start = Offset(widthPadding, padding);
    final end = Offset(paddedWidth + widthPadding, paddedHeight + padding);
    final rect = Rect.fromPoints(start, end);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    final paint = Paint()
      ..strokeWidth = 0.01
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    // Draw the gradient stroke
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Adjust as needed if you plan to update the drawing
  }
}
