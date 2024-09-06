import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/recivo_inventario.dart';
import 'package:contabilidad/widget/item_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  double? _amount;
  late DataBase dataBaseProvider;
  final _searchController = TextEditingController();
  final _controller = TextEditingController();
  final ValueNotifier<String> selectedItemNotifier =
      ValueNotifier<String>(''); // Para el filtro seleccionado

  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _costCTRController = {};
  final Map<String, ValueNotifier<int>> productQuantities = {};
  final Map<String, ValueNotifier<int>> productCosts = {};
  ValueNotifier<bool> isCheckoutButtonEnabled = ValueNotifier(false);
  List<ProductModel> selectedProducts = [];
  List<ProductModel> allProducts = []; // Lista completa de productos
  List<ProductModel> filteredProducts = []; // Lista filtrada de productos
  bool isFilterEmpty = false;

  @override
  void initState() {
    super.initState();
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    getProducts();
    // _searchController.addListener(_filterProducts);
    selectedItemNotifier.addListener(
        _filterProducts); // Escuchar cambios en el filtro seleccionado
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    String selectedFilter = selectedItemNotifier.value;

    setState(() {
      // Cambiar `filteredProducts` a `allProducts`
      filteredProducts = allProducts.where((product) {
        final matchesSearchQuery = product.name.toLowerCase().contains(query);
        final matchesSelectedFilter =
            selectedFilter.isEmpty || product.productType == selectedFilter;
        return matchesSearchQuery && matchesSelectedFilter;
      }).toList();
    });
  }

  void _updateCheckoutButtonState() {
    isCheckoutButtonEnabled.value =
        selectedProducts.any((product) => product.quantity!.value > 0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    _quantityControllers.forEach((_, controller) => controller.dispose());
    productQuantities.forEach((_, notifier) => notifier.dispose());
    productCosts.forEach((_, notifier) => notifier.dispose());
    super.dispose();
  }

  void getProducts() async {
    var products = await dataBaseProvider.obtenerProductos();

    // Ordenar productos alfabéticamente por nombre
    products
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    for (var product in products) {
      print("${product.cost} testtt");
      final productId = product.id.toString();

      productQuantities[productId] = ValueNotifier<int>(0);
      productCosts[productId] = ValueNotifier<int>(product.cost.toInt());
      _quantityControllers[productId] = TextEditingController();
      _costCTRController[productId] = TextEditingController();
    }

    setState(() {
      allProducts = products;
      filteredProducts = products; // Inicialmente mostrar todos los productos
    });
  }

  bool _isCheckoutEnabled() {
    int totalQuantity = productQuantities.values
        .fold(0, (sum, notifier) => sum + notifier.value);
    return totalQuantity > 0;
  }

  void _updateSelectedProductQuantity(
      ProductModel product, int change, bool isOverwrite) {
    final existingProduct = selectedProducts.firstWhere(
        (p) => p.id == product.id,
        orElse: () => ProductModel(
            subProduct: product.subProduct,
            id: product.id,
            name: product.name,
            cost: product.cost,
            unit: product.unit,
            amount: product.amount,
            unitPrice: product.unitPrice,
            file: product.file,
            productCategory: product.productCategory,
            productType: product.productType,
            quantity: ValueNotifier<int>(0)));

    int updatedQuantity = existingProduct.quantity!.value + change;
    if (isOverwrite) {
      updatedQuantity = change;
    }

    if (updatedQuantity <= 0) {
      selectedProducts.removeWhere((p) => p.id == product.id);
    } else {
      existingProduct.quantity!.value = updatedQuantity;
      if (!selectedProducts.contains(existingProduct)) {
        selectedProducts.add(existingProduct);
      }
    }

    _updateCheckoutButtonState();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Escoge un producto"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenHeight * 0.01,
        ),
        child: Column(
          children: [
            // Filtros personalizados
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal, // Habilitar desplazamiento horizontal
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
                          _filterProducts();

                          // _filterProducts(); // /Actualizar la lista filtrada
                        },
                        child: ValueListenableBuilder<String>(
                          valueListenable: selectedItemNotifier,
                          builder: (context, value, child) {
                            return Container(
                              height: screenHeight * 0.05,
                              width: screenWidth * 0.3, // Ancho ajustable
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
                                  textAlign:
                                      TextAlign.center, // Centrar el texto
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                    fontSize: screenHeight * 0.018,
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
            ),

            // Campo de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Buscar producto...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final productId = product.id.toString();

                  if (!productQuantities.containsKey(productId)) {
                    productQuantities[productId] = ValueNotifier<int>(0);
                  }
                  if (!productCosts.containsKey(productId)) {
                    productCosts[productId] =
                        ValueNotifier<int>(product.cost.toInt());
                  }

                  final quantityController = _quantityControllers[productId] ??
                      TextEditingController();
                  final costCTRController =
                      _costCTRController[productId] ?? TextEditingController();

                  costCTRController.text = product.cost.toString();
                  print("${product.cost} test123123");
                  quantityController.text =
                      productQuantities[productId]!.value.toString();

                  return GestureDetector(
                    onTap: () async {
                      // Handle tap
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ValueListenableBuilder<int>(
                        valueListenable: productCosts[productId]!,
                        builder: (context, costValue, child) {
                          return Item(
                            costOnChange: (String value) {
                              if (value.isNotEmpty) {
                                productCosts[productId]!.value =
                                    int.parse(value);

                                //
                                product.cost = productCosts[productId]!.value;
                              }
                            },
                            quantityOnChange: (String value) {
                              if (value == "") {
                                return;
                              }
                              productQuantities[productId]!.value =
                                  int.parse(value);
                              _updateCheckoutButtonState();

                              _updateSelectedProductQuantity(product,
                                  int.parse(quantityController.text), true);
                            },
                            quantityCTRController: quantityController,
                            costCTRController: costCTRController,
                            cost: productCosts[productId]!.value.toInt(),
                            quantity: productQuantities[productId]!,
                            minus: () {
                              if (productQuantities[productId]!.value == 0) {
                                return;
                              }
                              productQuantities[productId]!.value--;
                              _updateCheckoutButtonState();
                              _updateSelectedProductQuantity(
                                  product, -1, false);
                            },
                            plus: () {
                              productQuantities[productId]!.value++;
                              _updateCheckoutButtonState();
                              _updateSelectedProductQuantity(product, 1, false);
                            },
                            hasTrailing: true,
                            magnitud: product.unit,
                            amount: product.amount,
                            name: product.name,
                            precio: product.unitPrice,
                            imagePath: product.file!,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              height: screenHeight * 0.08,
              child: ValueListenableBuilder(
                valueListenable: isCheckoutButtonEnabled,
                builder: (context, value, child) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 108, 40, 123),
                      textStyle: const TextStyle(fontSize: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: value
                        ? () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ReceiptPage(
                                        selectedProducts: selectedProducts)));
                          }
                        : null,
                    child: const Text(
                      "Finalizar Compra",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
