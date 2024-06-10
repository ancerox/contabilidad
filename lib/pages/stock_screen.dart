import 'dart:io';

import 'package:contabilidad/consts.dart'; // Asegúrate de que este archivo exista y tenga las constantes necesarias
import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/date_range.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/crate_product_screen.dart';
import 'package:contabilidad/widget/item_widget.dart'; // Asegúrate de que este archivo exista y tenga el widget necesario
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  ValueNotifier<List<ProductModel>> products = ValueNotifier([]);
  DataBase? dataBaseProvider;
  ValueNotifier<String> selectedItemNotifier = ValueNotifier('En venta');
  final List<String> items = ["En venta", "En alquiler", "Otros"];
  double totalAmount = 0;
  Map<DateTime, bool> availability = {};
  late List<ProductModel> productsOutStock;

  @override
  void initState() {
    super.initState();
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    dataBaseProvider!.addListener(updateProducts);
    getProducts();
  }

  @override
  void dispose() {
    dataBaseProvider!.removeListener(updateProducts);
    super.dispose();
  }

  void updateProducts() {
    getProducts();
  }

  void getProducts() async {
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    products.value = await dataBaseProvider!.obtenerProductos();
    products.value = products.value
        .where((product) =>
            product.productCategory.contains(selectedItemNotifier.value))
        .toList();
    productsOutStock =
        products.value.where((product) => product.amount == 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<ProductModel>>(
                future: dataBaseProvider!.obtenerProductos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ValueListenableBuilder(
                    valueListenable: selectedItemNotifier,
                    builder: (context, String selectedItem, child) {
                      totalAmount = snapshot.data!.fold(
                          0,
                          (double sum, current) =>
                              sum + current.unitPrice * current.amount);

                      return Column(children: [
                        Text(
                          "Manejo de inventario",
                          style: subtitles.copyWith(color: Colors.black),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: [
                            CardWidget(
                              inventary: "\$ $totalAmount DOP",
                              title: "Monto de inventario total",
                              count: 1,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xff994AFC),
                                  Color(0xffDC59FD),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OutOfStockScreen(
                                          productsOutStock: productsOutStock),
                                    ));
                              },
                              child: CardWidget(
                                inventary: productsOutStock.length.toString(),
                                title: "Productos vendidos",
                                count: 1,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff40BCFE),
                                    Color(0xff0C60FF),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const CreateProductPage(
                                            isEditPage: false,
                                          ))).then((_) => getProducts());
                            },
                            child: const CustomButtom(
                              text: "Añadir producto",
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Lista de productos disponibles",
                                  style:
                                      subtitles.copyWith(color: Colors.black),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Container(
                                  height: 30,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    border: Border.all(
                                      width: 1.5,
                                      color: const Color(0xffD0A6FA),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${products.value.length}",
                                      style: subtitles.copyWith(
                                        color: const Color(0xffA338FF),
                                        fontSize: 19,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 45,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 30),
                                itemBuilder: (context, index) {
                                  bool isSelected =
                                      selectedItem == items[index];
                                  return GestureDetector(
                                    onTap: () {
                                      selectedItemNotifier.value = items[index];
                                      getProducts();
                                    },
                                    child: Container(
                                      height: 40,
                                      width: MediaQuery.of(context).size.width *
                                          0.25,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color.fromARGB(
                                                255, 222, 184, 255)
                                            : const Color(0xfff5ecfd),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          items[index],
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      ]);
                    },
                  );
                }),
            ValueListenableBuilder<List<ProductModel>>(
              valueListenable: products,
              builder: (context, productList, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ListView.builder(
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      var product = productList[index];

                      return Slidable(
                        key: Key(product.id.toString()),
                        startActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) => _confirmDelete(
                                  context, product, dataBaseProvider!),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Borrar',
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => CreateProductPage(
                                          isEditPage: true,
                                          product: product,
                                        ))).then((_) {
                              setState(() {
                                getProducts();
                              });
                            });
                          },
                          child: selectedItemNotifier.value == "En alquiler"
                              ? Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TableCalendar(
                                        enabledDayPredicate: (day) {
                                          for (var range
                                              in product.datesNotAvailable!) {
                                            if (range.start != null &&
                                                range.end != null &&
                                                (day.isAfter(range.start!
                                                        .subtract(
                                                            const Duration(
                                                                days: 1))) &&
                                                    day.isBefore(range.end!.add(
                                                        const Duration(
                                                            days: 1))))) {
                                              return false;
                                            }
                                          }
                                          return true;
                                        },
                                        headerStyle: const HeaderStyle(
                                          formatButtonVisible: false,
                                          titleCentered: true,
                                        ),
                                        calendarFormat: CalendarFormat.week,
                                        focusedDay: DateTime.now(),
                                        firstDay: DateTime.utc(2010, 10, 16),
                                        lastDay: DateTime.utc(2030, 3, 14),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        16, 16, 16, 8),
                                                    child: Text(
                                                      product.name,
                                                      style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.deepPurple,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Row(
                                                    children: [
                                                      isCurrentDateOutsideRanges(
                                                              product
                                                                  .datesNotAvailable!)
                                                          ? const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                            )
                                                          : const Icon(
                                                              Icons
                                                                  .timer_off_sharp,
                                                              color: Colors.red,
                                                            ),
                                                      Text(
                                                        isCurrentDateOutsideRanges(
                                                                product
                                                                    .datesNotAvailable!)
                                                            ? 'Disponible hoy'
                                                            : "No disponible hasta ${DateFormat('EEEE d MMMM', 'es_ES').format(product.datesNotAvailable![0].end!)}",
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          color: isCurrentDateOutsideRanges(
                                                                  product
                                                                      .datesNotAvailable!)
                                                              ? Colors.green
                                                              : Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: product.file == 'none'
                                                  ? const Image(
                                                      width: 80,
                                                      image: AssetImage(
                                                          'assets/icons/icon.jpeg'),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Image.file(
                                                      File(product.file!),
                                                      width: 80,
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : Item(
                                  subProducts: product.subProduct,
                                  magnitud: product.unit,
                                  cost: product.cost,
                                  amount: product.amount,
                                  name: product.name,
                                  precio: product.unitPrice,
                                  imagePath: product.file!,
                                ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool isCurrentDateOutsideRanges(List<DateRange> dateRanges) {
    DateTime now = DateTime.now();

    for (var range in dateRanges) {
      if (range.start != null && range.end != null) {
        if (now.isAfter(range.start!) && now.isBefore(range.end!)) {
          return false;
        }
      }
    }

    return true;
  }

  void _confirmDelete(
      BuildContext context, ProductModel product, DataBase database) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
              '¿Estás seguro de que deseas borrar ${product.name} de tu lista de productos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                database.deleteProduct(product.id!);
                Navigator.of(context).pop();
              },
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
  }
}

class CustomButtom extends StatelessWidget {
  final String text;

  const CustomButtom({
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [
            Color(0xffF00A85),
            Color(0xffDA59E9),
          ],
        ),
      ),
      child: Center(
        child: Text(text, style: subtitles.copyWith(fontSize: 15)),
      ),
    );
  }
}

class OutOfStockScreen extends StatelessWidget {
  final List<ProductModel> productsOutStock;

  const OutOfStockScreen({super.key, required this.productsOutStock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Productos Agotados"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: productsOutStock.isEmpty
            ? const Center(child: Text("No hay productos agotados"))
            : ListView.builder(
                itemCount: productsOutStock.length,
                itemBuilder: (context, index) {
                  var product = productsOutStock[index];
                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Image.file(
                        File(product.file!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      subtitle: Text(
                        "Precio: \$${product.unitPrice}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
