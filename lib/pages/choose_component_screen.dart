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

  void setQuantity(double value) {
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
    for (var product in productList) {
      print("${product.cost} testtt");
      final productId = product.id.toString();

      _costCTRController[productId] = TextEditingController();
    }
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

  final Map<String, TextEditingController> _costCTRController = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ValueListenableBuilder<List<ProductNotifier>>(
              valueListenable: products,
              builder: (context, sortedProductsList, child) {
                sortedProductsList = sortedProductsList
                    .where((productNotifier) => productNotifier
                        .product.productType
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
                                        ? const Color.fromARGB(
                                            255, 165, 75, 175)
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
                      const Divider(),
                      SingleChildScrollView(
                        child: ValueListenableBuilder<List<ProductNotifier>>(
                          valueListenable: addedProducts,
                          builder: (context, addedProductsList, child) {
                            return Column(
                              children: [
                                const Text(
                                  'Productos Añadidos',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: addedProductsList.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          title: Text(addedProductsList[index]
                                              .product
                                              .name),
                                          trailing: Text(
                                            'Cantidad: ${addedProductsList[index].product.quantity!.value}',
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        // height: size(context).height * 0.4,
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
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  return ChangeNotifierProvider.value(
                                    value: filteredProducts[index],
                                    child: Consumer<ProductNotifier>(
                                      builder:
                                          (context, productNotifier, child) {
                                        var product = productNotifier.product;
                                        var addedProduct = addedProducts.value
                                            .firstWhere(
                                                (p) =>
                                                    p.product.id == product.id,
                                                orElse: () => productNotifier);
                                        addedProduct.product.quantity!.value > 0
                                            ? addedProduct
                                                .product.quantity!.value
                                                .toString()
                                            : '0';
                                        return ListTile(
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(product.unit),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      addedProduct.decrement();
                                                      if (addedProduct
                                                              .product
                                                              .quantity!
                                                              .value <=
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
                                                    decoration:
                                                        const BoxDecoration(
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    235,
                                                                    235,
                                                                    235)),
                                                    height: 50,
                                                    width: 55,
                                                    child: Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Color.fromARGB(
                                                            255, 235, 235, 235),
                                                      ),
                                                      child: Center(
                                                        child: TextField(
                                                          decoration: const InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets.only(
                                                                      left: 8.0,
                                                                      bottom:
                                                                          8.0,
                                                                      top:
                                                                          8.0)),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 20),
                                                          keyboardType:
                                                              const TextInputType
                                                                  .numberWithOptions(
                                                                  decimal:
                                                                      true),
                                                          controller:
                                                              _costCTRController[
                                                                  product.id!
                                                                      .toString()],
                                                          onChanged: (value) {
                                                            // Aquí puedes parsear el valor a double si es necesario
                                                            double?
                                                                parsedValue =
                                                                double.tryParse(
                                                                    value);
                                                            if (parsedValue !=
                                                                null) {
                                                              addedProduct
                                                                  .setQuantity(
                                                                      parsedValue);
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      double? quantity =
                                                          double.tryParse(
                                                              _costCTRController[
                                                                      product.id
                                                                          .toString()]!
                                                                  .text);
                                                      if (quantity != null) {
                                                        addedProduct
                                                            .setQuantity(
                                                                quantity);
                                                      } else {
                                                        addedProduct
                                                            .increment();
                                                      }
                                                      if (!addedProducts.value
                                                          .any((p) =>
                                                              p.product.id ==
                                                              product.id)) {
                                                        addedProducts.value.add(
                                                            productNotifier);
                                                      }
                                                      updateHasPurchases();
                                                    },
                                                    icon: const Icon(Icons.add),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          tileColor: addedProduct.product
                                                      .quantity!.value ==
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
                      // const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 108, 40, 123),
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
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
