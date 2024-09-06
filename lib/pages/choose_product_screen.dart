import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/widget/item_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChoseProductOrdenScreen extends StatefulWidget {
  const ChoseProductOrdenScreen({
    super.key,
  });

  @override
  _ChoseProductOrdenScreenState createState() =>
      _ChoseProductOrdenScreenState();
}

class _ChoseProductOrdenScreenState extends State<ChoseProductOrdenScreen> {
  late TextEditingController _searchController;
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');
  final ValueNotifier<String> selectedItemNotifier =
      ValueNotifier<String>('Producto terminado');
  final Map<String, TextEditingController> _quantityControllers = {};
  ValueNotifier<bool> isCheckoutButtonEnabled = ValueNotifier(false);
  final Map<String, ValueNotifier<int>> _quantityNotifiers = {};
  late DataBase dataBaseProvider;

  @override
  void initState() {
    super.initState();
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    _searchController = TextEditingController();
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
    selectedItemNotifier
        .addListener(_filterProducts); // Add the listener for the filter
  }

  void _filterProducts() {
    setState(() {}); // Triggers UI update when filter changes
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTextNotifier.dispose();
    selectedItemNotifier.dispose(); // Dispose the filter notifier
    _quantityControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _updateSelectedProductQuantity(
      ProductModel product, int change, bool isOverwrite) {
    int updatedQuantity =
        isOverwrite ? change : (product.quantity?.value ?? 0) + change;

    if (updatedQuantity <= 0) {
      dataBaseProvider.selectedProductsNotifier.value.remove(product);
      product.quantity?.value = 0;
    } else {
      if (product.quantity == null) {
        product.quantity = ValueNotifier<int>(updatedQuantity);
      } else {
        product.quantity!.value = updatedQuantity;
      }
      if (!dataBaseProvider.selectedProductsNotifier.value.contains(product)) {
        dataBaseProvider.selectedProductsNotifier.value.add(product);
      }
    }

    _updateCheckoutButtonState();
  }

  void _updateCheckoutButtonState() {
    bool hasProductsInCart = dataBaseProvider.selectedProductsNotifier.value
        .any((product) => (product.quantity?.value ?? 0) > 0);
    isCheckoutButtonEnabled.value = hasProductsInCart;
  }

  TextEditingController _getOrCreateController(String productId) {
    return _quantityControllers.putIfAbsent(
        productId, () => TextEditingController());
  }

  ValueNotifier<int> _getOrCreateQuantityNotifier(
      String productId, int initialQuantity) {
    return _quantityNotifiers.putIfAbsent(
        productId, () => ValueNotifier<int>(initialQuantity));
  }

  @override
  Widget build(BuildContext context) {
    final dataBaseProvider = Provider.of<DataBase>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Filter options UI
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (var option in [
                      'Producto terminado',
                      'Materia prima',
                      'Gasto administrativo',
                      'Servicios',
                    ])
                      GestureDetector(
                        onTap: () {
                          selectedItemNotifier.value = option;
                        },
                        child: ValueListenableBuilder<String>(
                          valueListenable: selectedItemNotifier,
                          builder: (context, value, child) {
                            return Container(
                              height: 40,
                              width: 120,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: value == option
                                    ? const Color.fromARGB(255, 165, 75, 175)
                                    : const Color.fromARGB(255, 83, 69, 84),
                              ),
                              child: Center(
                                child: Text(
                                  option,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Search bar
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
              Expanded(
                child: FutureBuilder<List<ProductModel>>(
                  future: dataBaseProvider.obtenerProductos(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      var products = snapshot.data ?? [];

                      // Priorizar productos seleccionados previamente
                      final selectedProductsFromNotifier =
                          dataBaseProvider.selectedProductsNotifier.value;

                      // Combinar y eliminar duplicados basados en el ID del producto
                      products = [
                        ...selectedProductsFromNotifier,
                        ...products.where((product) =>
                            !selectedProductsFromNotifier
                                .map((e) => e.id)
                                .contains(product.id)),
                      ];
                      products.sort((a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                      products = products
                          .where((element) =>
                              element.productCategory != "En alquiler")
                          .toList();

                      // // Apply filter based on product type
                      products = products.where((product) {
                        return selectedItemNotifier.value.isEmpty ||
                            product.productType == selectedItemNotifier.value;
                      }).toList();

                      // Apply search filter
                      products = products.where((product) {
                        return product.name
                            .toLowerCase()
                            .contains(_searchTextNotifier.value.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          product.quantity ??= ValueNotifier(0);
                          final quantityNotifier = _getOrCreateQuantityNotifier(
                            product.id.toString(),
                            product.quantity!.value,
                          );

                          final controller =
                              _getOrCreateController(product.id.toString());

                          return Item(
                            cost: product.cost.toInt(),
                            costOnChange: (String value) {
                              _updateSelectedProductQuantity(
                                products[index],
                                int.parse(value),
                                true,
                              );
                              _updateCheckoutButtonState();
                              setState(() {});
                            },
                            quantityOnChange: (String value) {
                              if (value == "") return;
                              quantityNotifier.value = int.parse(value);
                              _updateCheckoutButtonState();
                              _updateSelectedProductQuantity(
                                products[index],
                                int.parse(controller.text),
                                true,
                              );
                            },
                            minus: () {
                              if (quantityNotifier.value == 0) return;
                              quantityNotifier.value--;
                              _updateCheckoutButtonState();
                              _updateSelectedProductQuantity(
                                products[index],
                                -1,
                                false,
                              );
                            },
                            plus: () {
                              quantityNotifier.value++;
                              _updateCheckoutButtonState();
                              _updateSelectedProductQuantity(
                                products[index],
                                1,
                                false,
                              );
                            },
                            quantityCTRController: controller,
                            magnitud: product.unit,
                            quantity: quantityNotifier,
                            hasTrailing: true,
                            imagePath: product.file!,
                            name: product.name,
                            precio: product.unitPrice,
                          );
                        },
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
              // Confirm button
              Container(
                margin: const EdgeInsets.all(20),
                width: double.infinity,
                height: 70,
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
                              Navigator.pop(context);
                              // No reasignar, simplemente usar .value para actualizar la lista
                              dataBaseProvider.selectedProductsNotifier
                                  .notifyListeners();
                            }
                          : null,
                      child: const Text(
                        "Confirmar",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
