import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/recivo_inventario.dart';
import 'package:contabilidad/widget/item_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  double? _amount;
  int passedIndex = 0;
  late DataBase dataBaseProvider;
  final _controller = TextEditingController();

  final Map<int, TextEditingController> _costControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  Map<int, ValueNotifier<int>> productQuantities = {};
  ValueNotifier<bool> isCheckoutButtonEnabled = ValueNotifier(false);
  Map<ProductModel, int> selectedProducts = {};
  final TextEditingController costCTRController = TextEditingController();
  final TextEditingController quantityCTRController = TextEditingController();

  @override
  void initState() {
    super.initState();

    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    getProducts();
  }

  void _updateCheckoutButtonState() {
    isCheckoutButtonEnabled.value =
        selectedProducts.values.any((quantity) => quantity > 0);
    final totalQuantity = productQuantities.values
        .fold(0, (int sum, notifier) => sum + notifier.value);
    isCheckoutButtonEnabled.value = totalQuantity > 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    _costControllers.forEach((_, controller) => controller.dispose());
    _quantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void getProducts() async {
    var products = await dataBaseProvider.obtenerProductos();
    for (int i = 0; i < products.length; i++) {
      productQuantities[i] = ValueNotifier<int>(0);
    }
    for (int i = 0; i < products.length; i++) {
      _costControllers[i] = TextEditingController();
      _quantityControllers[i] = TextEditingController();
      productQuantities[i] = ValueNotifier<int>(0);
    }
    setState(() {});
  }

  bool _isCheckoutEnabled() {
    int totalQuantity = productQuantities.values
        .fold(0, (sum, notifier) => sum + notifier.value);
    return totalQuantity > 1;
  }

  void _updateSelectedProductQuantity(
      ProductModel product, int change, bool isOverwrite) {
    final currentQuantity = selectedProducts[product] ?? 0;

    int updatedQuantity = currentQuantity + change;
    if (isOverwrite) {
      updatedQuantity = change;
    }

    if (updatedQuantity <= 0) {
      selectedProducts.remove(product);
    } else {
      selectedProducts[product] = updatedQuantity;
    }

    _updateCheckoutButtonState();
  }

  @override
  Widget build(BuildContext context) {
    // It seems like you had an accidental FutureBuilder duplication here. I've removed the incorrect one.
    return FutureBuilder<List<ProductModel>>(
      future: dataBaseProvider
          .obtenerProductos(), // Make sure databaseProvider is defined and correct
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final products = snapshot.data ?? [];
          return Scaffold(
            appBar: AppBar(
              title: const Text("Escoge un producto"),
            ),
            body: products.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(
                        20.0), // Añade padding alrededor del texto
                    margin: const EdgeInsets.all(
                        20.0), // Añade margen alrededor del Container
                    decoration: BoxDecoration(
                      color: Colors
                          .white, // Define el color de fondo del Container
                      borderRadius: BorderRadius.circular(
                          20.0), // Define los bordes redondeados
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey
                              .withOpacity(0.5), // Color de la sombra
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(
                              0, 3), // Cambios de posición de la sombra
                        ),
                      ],
                    ),
                    child: const Text(
                      "Aún no has agregado ningún producto a tu inventario",
                      textAlign:
                          TextAlign.center, // Centra el texto horizontalmente
                      style: TextStyle(
                        fontSize: 16.0, // Tamaño del texto
                        color: Colors.black, // Color del texto
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Container(
                          child: ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              if (!productQuantities.containsKey(index)) {
                                productQuantities[index] =
                                    ValueNotifier<int>(0);
                              }
                              final costController = _costControllers[index] ??
                                  TextEditingController();

                              final quantityController =
                                  _quantityControllers[index] ??
                                      TextEditingController();

                              costController.text =
                                  products[index].cost.toString();

                              passedIndex = index;
                              // quantityController.text =
                              //     products[index].amount.toString();

                              // Make sure 'Item' widget is defined or replace it with an appropriate widget
                              return GestureDetector(
                                onTap: () async {
                                  // Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //         builder: (_) => CheckoutScreen(
                                  //               product: products[index],
                                  //             )));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Item(
                                    costOnChange: (String value) {
                                      if (value != "") {
                                        products[index].cost =
                                            double.parse(value);
                                      }
                                    },
                                    quantityOnChange: (String value) {
                                      if (value == "") {
                                        return;
                                      }
                                      productQuantities[index]!.value =
                                          int.parse(value);
                                      _updateCheckoutButtonState();

                                      _updateSelectedProductQuantity(
                                          products[index],
                                          int.parse(quantityController.text),
                                          true);
                                    },
                                    quantityCTRController: quantityController,
                                    costCTRController: costController,
                                    cost: products[index].cost,
                                    quantity: productQuantities[index]!,
                                    minus: () {
                                      if (productQuantities[index]!.value ==
                                          0) {
                                        return;
                                      }
                                      productQuantities[index]!.value--;
                                      _updateCheckoutButtonState();
                                      _updateSelectedProductQuantity(
                                          products[index], -1, false);
                                    },
                                    plus: () {
                                      productQuantities[index]!.value++;
                                      _updateCheckoutButtonState();
                                      _updateSelectedProductQuantity(
                                          products[index], 1, false);
                                    },
                                    hasTrailing: true,
                                    magnitud: products[index].unit,
                                    amount: products[index].amount,
                                    name: products[index].name,
                                    precio: products[index].unitPrice,
                                    imagePath: products[index].file!,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(20),
                        width: double.infinity, // Ancho del botón
                        height: 70, // Alto del botón
                        child: ValueListenableBuilder(
                          valueListenable: isCheckoutButtonEnabled,
                          builder: (context, value, child) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 108, 40, 123),
                                textStyle: const TextStyle(fontSize: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: value
                                  ? () {
                                      Map<int, double> idCostMap = {};
                                      selectedProducts
                                          .forEach((product, quantity) {
                                        idCostMap[product.id!] = product.cost;
                                      });

                                      dataBaseProvider
                                          .updateMultipleProductCosts(
                                              idCostMap);
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ReceiptPage(
                                                  selectedProducts:
                                                      selectedProducts)));
                                    }
                                  : null,
                              child: const Text(
                                "Finalizar Compra",
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
          );
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
