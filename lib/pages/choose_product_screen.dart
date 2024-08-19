import 'package:contabilidad/consts.dart';
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
  final Map<String, TextEditingController> _quantityControllers = {};
  ValueNotifier<bool> isCheckoutButtonEnabled = ValueNotifier(false);
  List<ProductModel> selectedProducts = [];
  // A map to keep track of ValueNotifier<int> for each product's quantity, identified by product ID.
  final Map<String, ValueNotifier<int>> _quantityNotifiers = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
  }

  // @override
  // void dispose() {
  //   _searchController.dispose();
  //   _searchTextNotifier.dispose();
  //   _quantityControllers.forEach((key, controller) {
  //     controller.dispose();
  //   });
  //   super.dispose();
  // }

  void _updateSelectedProductQuantity(
      ProductModel product, int change, bool isOverwrite) {
    int updatedQuantity =
        isOverwrite ? change : (product.quantity?.value ?? 0) + change;

    if (updatedQuantity <= 0) {
      selectedProducts.remove(product);
      product.quantity?.value =
          0; // Optionally reset to 0 or some default value
    } else {
      if (product.quantity == null) {
        product.quantity = ValueNotifier<int>(updatedQuantity);
      } else {
        product.quantity!.value = updatedQuantity;
      }

      // selectedProducts[product] =
      //     updatedQuantity; // This assumes you're still tracking quantity separately
    }

    _updateCheckoutButtonState();
  }

  void _updateCheckoutButtonState() {
    // Update the checkout button's enabled state based on the quantities of all products
    bool hasProductsInCart = _quantityNotifiers.values
        .any((quantityNotifier) => quantityNotifier.value > 0);
    isCheckoutButtonEnabled.value = hasProductsInCart;
  }

  TextEditingController _getOrCreateController(String productId) {
    // Check if a controller already exists for the given product ID, otherwise create it.
    return _quantityControllers.putIfAbsent(
        productId, () => TextEditingController());
  }

  ValueNotifier<int> _getOrCreateQuantityNotifier(
      String productId, int initialQuantity) {
    // Check if a notifier already exists for the given product ID, otherwise create it with the initial quantity.
    return _quantityNotifiers.putIfAbsent(
        productId, () => ValueNotifier<int>(initialQuantity));
  }

  List<ProductModel> convertMapToList(Map<ProductModel, int> productMap) {
    List<ProductModel> productList = [];
    productMap.forEach((product, quantity) {
      for (int i = 0; i < quantity; i++) {
        productList.add(product);
      }
    });
    return productList;
  }

  @override
  Widget build(BuildContext context) {
    final dataBaseProvider = Provider.of<DataBase>(context, listen: false);

    return Scaffold(
      // appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<ProductModel>>(
          future: dataBaseProvider.obtenerProductos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final dataBase = Provider.of<DataBase>(context, listen: false);

              var products = snapshot.data ?? [];

              final listProducts = dataBase.selectedProductsNotifier.value;
              if (dataBase.selectedProductsNotifier.value.isNotEmpty) {
                // Set<ProductModel> resultSet =
                //     Set<ProductModel>.from(listProducts);

                // // Add all elements from list2. The set will automatically avoid duplicates.
                // resultSet.addAll(products);
                Map<ProductModel, ProductModel> map = {
                  for (var item in products) item: item
                };

                for (var item in listProducts) {
                  map[item] =
                      item; // This replaces if the item already exists, adds if it doesn't
                }

                // Step 3: Convert the map back to a list
                List<ProductModel> mixedList = map.values.toList();
                print(mixedList);
                products = mixedList;
                selectedProducts = listProducts;
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
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
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: _searchTextNotifier,
                      builder: (context, value, _) {
                        List<ProductModel> filteredProducts =
                            products.where((product) {
                          return product.name
                              .toLowerCase()
                              .contains(value.toLowerCase());
                        }).toList();

                        filteredProducts = filteredProducts
                            .where((product) =>
                                product.productCategory == "En venta")
                            .toList();

                        return SizedBox(
                          height: size(context).height * 0.75,
                          child: ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              product.quantity ??= ValueNotifier(0);
                              final quantityNotifier =
                                  _getOrCreateQuantityNotifier(
                                      product.id.toString(),
                                      product.quantity!.value);

                              // if (listProducts.isNotEmpty) {
                              //   Map<ProductModel, int> productMap = {
                              //     for (int i = 0; i < products.length; i++)
                              //       products[i]: dataBase
                              //           .selectedProductsNotifier
                              //           .value[product]!
                              //   };
                              //   dataBase.selectedProductsNotifier =
                              //       ValueNotifier<Map<ProductModel, int>>(
                              //           productMap);
                              // }

                              final controller =
                                  _getOrCreateController(product.id.toString());
                              // Pass the quantityNotifier to your Item widget or wherever it's needed
                              print(products);
                              return Item(
                                cost: product.cost.toInt(),
                                costOnChange: (String value) {
                                  _updateSelectedProductQuantity(
                                      products[index], int.parse(value), true);
                                  _updateCheckoutButtonState();

                                  setState(() {});
                                },
                                quantityOnChange: (String value) {
                                  if (value == "") {
                                    return;
                                  }
                                  quantityNotifier.value = int.parse(value);
                                  _updateCheckoutButtonState();
                                  _updateSelectedProductQuantity(
                                      products[index],
                                      int.parse(controller.text),
                                      true);
                                },
                                minus: () {
                                  if (quantityNotifier.value == 0) return;
                                  quantityNotifier.value--;
                                  _updateCheckoutButtonState();
                                  _updateSelectedProductQuantity(
                                      products[index], -1, false);
                                },
                                plus: () {
                                  quantityNotifier.value++;
                                  _updateCheckoutButtonState();
                                  if (product.quantity!.value == 0) {
                                    selectedProducts.add(product);

                                    product.quantity!.value++;
                                    return;
                                  }
                                  if (listProducts.isNotEmpty) {
                                    listProducts[index].quantity!.value++;
                                    return;
                                  }
                                  product.quantity!.value++;
                                  // _updateSelectedProductQuantity(
                                  //     products[index], 1, false);
                                },
                                quantityCTRController: controller,
                                magnitud: product.unit,
                                quantity:
                                    quantityNotifier, // Assuming your Item widget is adjusted to use ValueNotifier<int> for quantity
                                hasTrailing: true,
                                imagePath: product.file!,
                                name: product.name,
                                precio: product.unitPrice,

                                // You might want to adjust this part based on how you use `amount`
                              );
                            },
                          ),
                        );
                      },
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
                                    Navigator.pop(context);
                                    final dataBase = Provider.of<DataBase>(
                                        context,
                                        listen: false);
                                    dataBase.selectedProductsNotifier.value =
                                        selectedProducts;
                                  }
                                : null,
                            child: const Text(
                              "Confirmar",
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
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
