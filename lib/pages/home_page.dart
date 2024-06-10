import 'package:contabilidad/consts.dart';
import 'package:contabilidad/pages/buy_screen.dart';
import 'package:contabilidad/pages/create_charge_screen.dart';
import 'package:contabilidad/pages/create_order.dart';
import 'package:contabilidad/pages/history.dart';
import 'package:contabilidad/pages/pending_screen.dart';
import 'package:contabilidad/pages/stock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final listOfActionsSVGs = [
    'assets/icons/compra.svg',
    'assets/icons/ordenes.svg',
    'assets/icons/cobro.svg'
  ];
  final listOfActionsTexts = ['Compra', 'Orden', 'Cobro'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = MediaQuery.of(context).size.width;
            double cardWidth = (screenWidth - 40) / 2;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset('assets/icons/ep_menu.svg'),
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
                                    builder: (context) => const HistoryScreen(),
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
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PendingScreen(),
                                  ),
                                );
                              },
                              child: CardWidget(
                                isFull: false,
                                icon: 'assets/icons/pendientes.svg',
                                count: 2,
                                title: "Ordernes pendientes",
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.topRight,
                                  colors: [
                                    Color(0xffF32FDF),
                                    Color(0xffF32FDF),
                                  ],
                                ),
                                width: cardWidth,
                              ),
                            ),
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
                      child: ListView.builder(
                        itemCount: 3,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              quickActionsChoose(context, index);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: QuickActions(
                                icon: listOfActionsSVGs[index],
                                subtitle: listOfActionsTexts[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Estadísticas',
                      style: subtitles.copyWith(color: Colors.black),
                    ),
                    const SizedBox(height: 15),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Statistics(
                          color: 0xff9C4CFD,
                          text: 'Total\ngenerado',
                        ),
                        Statistics(
                          color: 0xff0EB200,
                          text: "Ganancias",
                        ),
                        Statistics(
                          color: 0xffF85819,
                          text: "Perdidas",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void quickActionsChoose(context, int index) {
    switch (index) {
      case 0:
        // Navegar a la primera pantalla (Asumiendo PaymentScreen)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentScreen()),
        );
        break;
      case 1:
        // Navegar a la segunda pantalla (CreateOrder)
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const CreateOrderScreen(
                    isEditPage: false,
                  )),
        );
        break;
      case 2:
        // Navegar a la segunda pantalla (CreateOrder)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AgregarCobroPage()),
        );
        break;
      // Agrega más casos si necesitas más pantallas
      default:
        // Opción por defecto, en caso de que necesites manejar índices fuera del rango esperado
        // Podrías mostrar un mensaje o navegar a una pantalla de error aquí.
        break;
    }
  }
}

class Statistics extends StatelessWidget {
  final String text;
  final int color;

  const Statistics({
    required this.color,
    required this.text,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(color),
                    ),
                  ),
                ),
                const Positioned(
                  top: 20,
                  right: 20,
                  child: Text(
                    '00',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
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
      height: isFull ? 175 : 82,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: gradient,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: isFull ? 25 : 15,
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
            right: isFull ? 0 : 40,
            left: isFull ? 27 : null,
            top: isFull ? 65 : 15,
            child: const Text(
              '0',
              style: subtitles,
            ),
          ),
          Positioned(
            bottom: isFull ? 50 : 10,
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
