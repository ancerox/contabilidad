import 'package:contabilidad/consts.dart';
import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class ChooseComponentScreen extends StatefulWidget {
  const ChooseComponentScreen({super.key});

  @override
  State<ChooseComponentScreen> createState() => _ChooseComponentScreenState();
}

class _ChooseComponentScreenState extends State<ChooseComponentScreen> {
  ValueNotifier<String> selectedItemNotifier = ValueNotifier('Materia prima');
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');
  late TextEditingController _searchController;
  late DataBase dabataseProvider;
  ValueNotifier<List<ProductModel>> products =
      ValueNotifier<List<ProductModel>>([]);
  final Map<int, TextEditingController> _quantityControllers = {};
  ValueNotifier<int> quantity = ValueNotifier<int>(0);
  final List<int> _selectedSubProductIds = [];
  bool hasPurchases = false;
  List<ProductModel> componetsProducts = [];

  @override
  void initState() {
    getProducts();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
    super.initState();
  }

  void getProducts() async {
    dabataseProvider = Provider.of<DataBase>(context, listen: false);
    var productList = await dabataseProvider.obtenerProductos();

    products.value = productList
        .where((product) =>
            product.productType.contains(selectedItemNotifier.value))
        .toList();
    for (int i = 0; i < products.value.length; i++) {
      _quantityControllers[i] = TextEditingController(text: "0");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<List<ProductModel>>(
        valueListenable: products,
        builder: (context, sortedComoditiesList, child) {
          sortedComoditiesList = sortedComoditiesList
              .where((product) =>
                  product.productType.contains(selectedItemNotifier.value))
              .toList();

          return SafeArea(
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar producto',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      for (var option in [
                        'Materia prima',
                        'Gasto adminis',
                        'Servicios'
                      ])
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedItemNotifier.value = option;

                              getProducts();
                            });
                          },
                          child: Container(
                            height: 40,
                            width: 110,
                            padding: const EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: selectedItemNotifier.value == option
                                  ? const Color.fromARGB(255, 165, 75, 175)
                                  : const Color.fromARGB(255, 83, 69,
                                      84), // Color de fondo de cada opción
                            ),
                            child: Center(
                              child: Text(
                                option,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white), // Texto blanco
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  // color: Colors.black,
                  height: size(context).height * 0.7,
                  child: FutureBuilder<List<ProductModel>>(
                    future: dabataseProvider.obtenerProductos(),
                    builder: (context, snap) {
                      return ValueListenableBuilder<String>(
                          valueListenable: _searchTextNotifier,
                          builder: (context, value, child) {
                            if (snap.connectionState == ConnectionState.done) {
                              var products = snap.data ?? [];

                              products = sortedComoditiesList;
                              // List<ProductModel> listProducts =

                              if (dabataseProvider
                                  .selectedCommodities.value.isNotEmpty) {
                                // Create a Map with product IDs as keys and products as values
                                Map<int, ProductModel> productMap = {
                                  for (var item in products) item.id!: item
                                };

                                // Update the map with selected commodities, replacing existing items with the same ID
                                for (var item in dabataseProvider
                                    .selectedCommodities.value) {
                                  productMap[item.id!] = item;
                                }

                                // Convert the map values back to a list
                                List<ProductModel> mixedList =
                                    productMap.values.toList();

                                // Update the products list
                                products = mixedList;
                                componetsProducts =
                                    dabataseProvider.selectedCommodities.value;
                              }

                              products = products.where((product) {
                                return product.name
                                    .toLowerCase()
                                    .contains(value.toLowerCase());
                              }).toList();

                              return ListView.builder(
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final quantityController =
                                      _quantityControllers[index] ??
                                          TextEditingController();
                                  bool isSelected = _selectedSubProductIds
                                      .contains(products[index]
                                          .id); // Verifica si el producto está seleccionado

                                  final product = products[index];
                                  product.quantity ??= ValueNotifier(0);
                                  quantityController.text =
                                      product.quantity!.value.toString();

                                  return ListTile(
                                    // trailing: GestureDetector(
                                    //   onTap: isSelected
                                    //       ? () {
                                    //           setState(() {
                                    //             _selectedSubProductIds.remove(
                                    //                 productList[index]
                                    //                     .id); // Deselecciona el
                                    //             setState(() {});
                                    //           });
                                    //         }
                                    //       : () {
                                    //           setState(() {
                                    //             _selectedSubProductIds.add(
                                    //                 productList[index]
                                    //                     .id!); // Selecciona el producto
                                    //           });
                                    //         },
                                    //   child: isSelected
                                    //       ? const Icon(Icons.remove)
                                    //       : const Icon(Icons.add),
                                    // ), // Icono de verificación si está seleccionado

                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(products[index].name),
                                        Text(products[index].unit),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  if (product.quantity!.value ==
                                                      0) {
                                                    return;
                                                  }
                                                  if (product.quantity!.value ==
                                                      1) {
                                                    dabataseProvider
                                                        .selectedCommodities
                                                        .value
                                                        .remove(product);
                                                  }
                                                  product.quantity!.value--;
                                                  hasPurchases = products.any(
                                                      (product) =>
                                                          product
                                                              .quantity!.value >
                                                          0);
                                                  // int currentValue = int.tryParse(
                                                  //         quantityController.text) ??
                                                  //     0;
                                                  // if (currentValue == 0) {
                                                  //   return;
                                                  // }
                                                  // int newValue = currentValue - 1;
                                                  // quantityController.text =
                                                  //     newValue.toString();
                                                });
                                              },
                                              icon: SvgPicture.asset(
                                                'assets/icons/minus.svg',
                                                width: 18,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                ValueListenableBuilder(
                                                  valueListenable: quantity,
                                                  builder:
                                                      (context, value, child) {
                                                    // quantityCTRController.text =
                                                    //     value.toString();
                                                    return Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      235,
                                                                      235,
                                                                      235)),
                                                      height: 30,
                                                      width:
                                                          30, // Define un ancho específico para el Container
                                                      child: TextFormField(
                                                        onChanged:
                                                            (String value) {
                                                          if (value != "") {}
                                                        },
                                                        maxLines: 1,
                                                        textAlign:
                                                            TextAlign.left,
                                                        inputFormatters: <TextInputFormatter>[
                                                          FilteringTextInputFormatter
                                                              .digitsOnly, // Acepta solo dígitos
                                                        ],
                                                        // onChanged: ,
                                                        // onChanged: (String value) {
                                                        //   setState(() {
                                                        //     // Intenta convertir el valor del texto a un número. Si falla, usa 0.
                                                        //     int newValue = int.tryParse(value) ?? 0;
                                                        //     quantity =
                                                        //         newValue; // Actualiza la cantidad con el nuevo valor.
                                                        //     // No es necesario actualizar _amountController.text aquí ya que
                                                        //     // el cambio del valor del campo ya está siendo reflejado en el TextField.
                                                        //   });
                                                        // },
                                                        style: const TextStyle(
                                                            overflow:
                                                                TextOverflow
                                                                    .visible,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16),
                                                        controller:
                                                            quantityController,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration:
                                                            const InputDecoration(
                                                                isDense: true,
                                                                contentPadding:
                                                                    EdgeInsets
                                                                        .fromLTRB(
                                                                            2.0,
                                                                            2.0,
                                                                            2.0,
                                                                            2.0),
                                                                border:
                                                                    InputBorder
                                                                        .none),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: Color.fromARGB(
                                                              255,
                                                              235,
                                                              235,
                                                              235)),
                                                  height: 30,
                                                  width: 30,
                                                  child: Center(
                                                    child: Text(
                                                      products[index]
                                                          .unit
                                                          .substring(0, 3),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    if (product
                                                            .quantity!.value ==
                                                        0) {
                                                      dabataseProvider
                                                          .selectedCommodities
                                                          .value
                                                          .add(product);
                                                      product.quantity!.value++;
                                                      hasPurchases = products
                                                          .any((product) =>
                                                              product.quantity!
                                                                  .value >
                                                              0);
                                                      return;
                                                    }

                                                    if (dabataseProvider
                                                        .selectedCommodities
                                                        .value
                                                        .isNotEmpty) {
                                                      dabataseProvider
                                                          .selectedCommodities
                                                          .value[index]
                                                          .quantity!
                                                          .value++;
                                                      hasPurchases = products
                                                          .any((product) =>
                                                              product.quantity!
                                                                  .value >
                                                              0);

                                                      return;
                                                    }

                                                    product.quantity!.value++;
                                                    hasPurchases = products.any(
                                                        (product) =>
                                                            product.quantity!
                                                                .value >
                                                            0);
                                                    setState(() {});
                                                    // int currentValue = int.tryParse(
                                                    //         quantityController.text) ??
                                                    //     0;
                                                    // int newValue = currentValue + 1;
                                                    // quantityController.text =
                                                    //     newValue.toString();
                                                  });
                                                },
                                                icon: const Icon(Icons.add)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    tileColor: product.quantity!.value == 0
                                        ? null
                                        : Colors
                                            .grey, // Cambia el color si está seleccionado
                                  );
                                },
                              );
                            } else {
                              return const CircularProgressIndicator();
                            }
                          });
                    },
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 108, 40, 123),
                    textStyle: const TextStyle(fontSize: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: hasPurchases
                      ? () {
                          dabataseProvider.selectedCommodities.value =
                              componetsProducts;
                          print(dabataseProvider.selectedCommodities);
                          Navigator.pop(context);
                          // Map<int, double> idCostMap = {};
                          // selectedProducts.forEach((product, quantity) {
                          //   idCostMap[product.id!] = product.cost;
                          // });

                          // dataBaseProvider.updateMultipleProductCosts(idCostMap);
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (_) =>
                          //         ReceiptPage(selectedProducts: selectedProducts),
                          //   ),
                          // );
                        }
                      : null,
                  child: const Text(
                    "Finalizar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
