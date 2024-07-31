import 'package:contabilidad/consts.dart';
import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class ChooseComponentScreen extends StatefulWidget {
  const ChooseComponentScreen({super.key});

  @override
  State<ChooseComponentScreen> createState() => _ChooseComponentScreenState();
}

class ProductNotifier extends ChangeNotifier {
  ProductModel product;

  ProductNotifier(this.product);

  void increment() {
    product.quantity!.value++;
    notifyListeners();
  }

  void decrement() {
    if (product.quantity!.value > 0) {
      product.quantity!.value--;
    }
    notifyListeners();
  }

  void setQuantity(int value) {
    product.quantity!.value = value;
    notifyListeners();
  }
}

class _ChooseComponentScreenState extends State<ChooseComponentScreen> {
  ValueNotifier<String> selectedItemNotifier = ValueNotifier('Materia prima');
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');
  late TextEditingController _searchController;
  late DataBase databaseProvider;
  ValueNotifier<List<ProductNotifier>> products =
      ValueNotifier<List<ProductNotifier>>([]);
  ValueNotifier<List<ProductNotifier>> addedProducts =
      ValueNotifier<List<ProductNotifier>>([]);
  bool hasPurchases = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
    Future.microtask(() => loadInitialData());
  }

  Future<void> loadInitialData() async {
    databaseProvider = Provider.of<DataBase>(context, listen: false);
    getProducts();
    loadExistingSelectedCommodities();
  }

  void getProducts() async {
    var productList = await databaseProvider.obtenerProductos();

    products.value = productList
        .where((product) =>
            product.productType.contains(selectedItemNotifier.value))
        .map((product) => ProductNotifier(product))
        .toList();
  }

  void loadExistingSelectedCommodities() {
    addedProducts.value = databaseProvider.selectedCommodities.value
        .map((product) => ProductNotifier(product))
        .toList();
    updateHasPurchases();
  }

  void updateHasPurchases() {
    hasPurchases = addedProducts.value
        .any((productNotifier) => productNotifier.product.quantity!.value > 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<List<ProductNotifier>>(
        valueListenable: products,
        builder: (context, sortedProductsList, child) {
          sortedProductsList = sortedProductsList
              .where((productNotifier) => productNotifier.product.productType
                  .contains(selectedItemNotifier.value))
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
                            selectedItemNotifier.value = option;
                            getProducts();
                          },
                          child: Container(
                            height: 40,
                            width: 110,
                            padding: const EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: selectedItemNotifier.value == option
                                  ? const Color.fromARGB(255, 165, 75, 175)
                                  : const Color.fromARGB(255, 83, 69, 84),
                            ),
                            child: Center(
                              child: Text(
                                option,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ValueListenableBuilder<List<ProductNotifier>>(
                  valueListenable: addedProducts,
                  builder: (context, addedProductsList, child) {
                    return Column(
                      children: [
                        const Text(
                          'Productos Añadidos',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (addedProductsList.isEmpty)
                          const Text('No hay productos añadidos'),
                        if (addedProductsList.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: addedProductsList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(
                                      addedProductsList[index].product.name),
                                  trailing: Text(
                                      'Cantidad: ${addedProductsList[index].product.quantity!.value}'),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(
                  height: size(context).height * 0.3,
                  child: ValueListenableBuilder<String>(
                      valueListenable: _searchTextNotifier,
                      builder: (context, value, child) {
                        var filteredProducts =
                            sortedProductsList.where((productNotifier) {
                          return productNotifier.product.name
                              .toLowerCase()
                              .contains(value.toLowerCase());
                        }).toList();

                        return ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            return ChangeNotifierProvider.value(
                              value: filteredProducts[index],
                              child: Consumer<ProductNotifier>(
                                builder: (context, productNotifier, child) {
                                  var product = productNotifier.product;
                                  var addedProduct = addedProducts.value
                                      .firstWhere(
                                          (p) => p.product.id == product.id,
                                          orElse: () => productNotifier);
                                  var quantityText =
                                      addedProduct.product.quantity!.value > 0
                                          ? addedProduct.product.quantity!.value
                                              .toString()
                                          : '0';
                                  return ListTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(product.name),
                                        Text(product.unit),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                addedProduct.decrement();
                                                if (addedProduct.product
                                                        .quantity!.value ==
                                                    0) {
                                                  addedProducts.value
                                                      .removeWhere((p) =>
                                                          p.product.id ==
                                                          product.id);
                                                }
                                                updateHasPurchases();
                                              },
                                              icon: SvgPicture.asset(
                                                'assets/icons/minus.svg',
                                                width: 18,
                                              ),
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 235, 235, 235)),
                                              height: 30,
                                              width: 30,
                                              child: Center(
                                                child: Text(
                                                  quantityText,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                addedProduct.increment();
                                                if (!addedProducts.value.any(
                                                    (p) =>
                                                        p.product.id ==
                                                        product.id)) {
                                                  addedProducts.value
                                                      .add(productNotifier);
                                                }
                                                updateHasPurchases();
                                              },
                                              icon: const Icon(Icons.add),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    tileColor:
                                        addedProduct.product.quantity!.value ==
                                                0
                                            ? null
                                            : Colors.grey,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      }),
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
                          databaseProvider.selectedCommodities.value =
                              addedProducts.value
                                  .map((pn) => pn.product)
                                  .toList();
                          Navigator.pop(context);
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
