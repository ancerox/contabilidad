import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/date_range.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/choose_component_screen.dart';
import 'package:contabilidad/widget/alquiler_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AlquilerWidget extends StatefulWidget {
  final Map<int, DateTime?> startDays;
  final Map<int, DateTime?> endDays;
  final bool isEditPage;
  final DateTime selectedDay;
  final void Function(int, ProductModel, Function) showCalendar;
  final Map<int, List<DateRange>> productDateRanges;
  final double Function(List<ProductModel>, Map<int, List<DateRange>>)
      calculateTotalCost;

  const AlquilerWidget({
    required this.isEditPage,
    required this.selectedDay,
    super.key,
    required this.showCalendar,
    required this.productDateRanges,
    required this.calculateTotalCost,
    required this.endDays,
    required this.startDays,
  });

  @override
  State<AlquilerWidget> createState() => _AlquilerWidgetState();
}

class _AlquilerWidgetState extends State<AlquilerWidget> {
  late TextEditingController _searchController;
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');
  final Map<String, ValueNotifier<double>> productQuantities = {};
  final Map<String, ValueNotifier<double>> productTotalPrices = {};
  final ValueNotifier<double> _totalPriceNotifier = ValueNotifier<double>(0);
  late DataBase dataBaseProvider;

  @override
  void initState() {
    super.initState();
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);

    _searchController = TextEditingController();
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });

    if (widget.isEditPage) {
      print("testoy");
      _updateTotalPrice();
      for (var element in dataBaseProvider.selectedProductsNotifier.value) {
        _handleQuantityChanged(element.name, element.quantity!.value);
      }
      dataBaseProvider.totalPrice = _totalPriceNotifier.value;
    }
    // dataBaseProvider.totalPriceNotifier = _totalPriceNotifier;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    dataBaseProvider.totalPrice =
        _totalPriceNotifier.value; // Assign the notifier here
  }

  @override
  void dispose() {
    widget.productDateRanges.clear();
    dataBaseProvider.dateRangeMap.clear();
    dataBaseProvider.dateRange = ValueNotifier(DateRange());
    dataBaseProvider.selectedProductsNotifier.value.clear();
    dataBaseProvider.selectedCommodities.value.clear();
    _searchController.dispose();
    _searchTextNotifier.dispose();
    productQuantities.forEach((key, value) => value.dispose());
    productTotalPrices.forEach((key, value) => value.dispose());
    dataBaseProvider.selectedProductsNotifier.value.clear();
    super.dispose();
  }

  void _handleQuantityChanged(String productName, double quantity) {
    if (productQuantities[productName] == null) {
      productQuantities[productName] = ValueNotifier<double>(quantity);
    } else {
      productQuantities[productName]!.value = quantity;
    }
    _updateProductTotalPrice(productName);
    _updateTotalPrice();
  }

  double _calculateProductTotalPrice(ProductModel product) {
    final quantity = productQuantities[product.name]?.value ?? 0;
    final startDay = widget.startDays[product.id];
    final endDay = widget.endDays[product.id];

    if (startDay != null && endDay != null) {
      final totalDays = endDay.difference(startDay).inDays + 1;
      return totalDays * product.unitPrice * quantity;
    }
    return 0.0;
  }

  void _updateProductTotalPrice(String productName) {
    final product = dataBaseProvider.selectedProductsNotifier.value
        .firstWhere((p) => p.name == productName);
    final totalPrice = _calculateProductTotalPrice(product);
    if (productTotalPrices[productName] == null) {
      productTotalPrices[productName] = ValueNotifier<double>(totalPrice);
    } else {
      productTotalPrices[productName]!.value = totalPrice;
    }
    final quantity = productQuantities[product.name]!;

    product.quantity = quantity;
  }

  void _updateTotalPrice() {
    double totalPrice = dataBaseProvider.selectedProductsNotifier.value
        .where((product) =>
            widget.productDateRanges[product.id] != null &&
            widget.productDateRanges[product.id]!.isNotEmpty)
        .fold<double>(
            0, (sum, product) => sum + _calculateProductTotalPrice(product));

    _totalPriceNotifier.value = totalPrice;
    dataBaseProvider.totalPrice = _totalPriceNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    dataBaseProvider = Provider.of<DataBase>(context, listen: true);
    return FutureBuilder<List<ProductModel>>(
      future: dataBaseProvider.obtenerProductos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          var products = snapshot.data ?? [];

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
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
                              setState(() {});
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
                        List<ProductModel> listOfProductsSave =
                            products.where((product) {
                          return product.name
                              .toLowerCase()
                              .contains(value.toLowerCase());
                        }).toList();
                        filteredProducts = filteredProducts
                            .where((product) =>
                                product.productCategory == "En alquiler")
                            .toList();
                        listOfProductsSave = listOfProductsSave
                            .where((product) =>
                                product.productCategory == "En alquiler")
                            .toList();

                        listOfProductsSave.removeWhere((productoAFiltrar) {
                          return dataBaseProvider.selectedProductsNotifier.value
                              .any((productoConCantidad) {
                            return productoConCantidad.id ==
                                    productoAFiltrar.id &&
                                productoConCantidad.quantity!.value > 0;
                          });
                        });
                        listOfProductsSave.removeWhere((element) {
                          return dataBaseProvider.selectedProductsNotifier.value
                              .any((productoConCantidad) {
                            return productoConCantidad.id == element.id;
                          });
                        });

                        return Column(
                          children: [
                            widget.isEditPage
                                ? const Text("Productos agregados")
                                : Container(),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                itemCount: widget.isEditPage
                                    ? dataBaseProvider
                                        .selectedProductsNotifier.value.length
                                    : filteredProducts.length,
                                itemBuilder: (context, index) {
                                  const uuid = Uuid();
                                  ProductModel product =
                                      filteredProducts[index];

                                  if (widget.isEditPage == true) {
                                    product = dataBaseProvider
                                        .selectedProductsNotifier.value[index];
                                  }

                                  bool isSelected = dataBaseProvider
                                      .selectedProductsNotifier.value
                                      .any((p) => p.id == product.id);

                                  if (productQuantities[product.name] == null) {
                                    productQuantities[product.name] =
                                        ValueNotifier<double>(0);
                                  }

                                  if (productTotalPrices[product.name] ==
                                      null) {
                                    productTotalPrices[product.name] =
                                        ValueNotifier<double>(0);
                                  }

                                  return ValueListenableBuilder<double>(
                                    valueListenable:
                                        productQuantities[product.name]!,
                                    builder: (context, quantity, child) {
                                      return ProductTile(
                                        title: GestureDetector(
                                          onTap: () {
                                            widget.showCalendar(index, product,
                                                () {
                                              _handleQuantityChanged(
                                                  product.name, 0);
                                            });
                                          },
                                          child: Text(product.name),
                                        ),
                                        endDay: widget.endDays[product.id] ??
                                            DateTime.now(),
                                        startDay:
                                            widget.startDays[product.id] ??
                                                DateTime.now(),
                                        isEditPage: widget.isEditPage,
                                        dateSelected: widget.selectedDay,
                                        productModel: product,
                                        imagePath: product.file!,
                                        productName: product.name,
                                        initialQuantity: quantity,
                                        productDateRanges:
                                            widget.productDateRanges,
                                        onQuantityChanged: (quantity) {
                                          print("GEGEGEEG");
                                          // Get the current list of selected products
                                          List<ProductModel> currentList =
                                              dataBaseProvider
                                                  .selectedProductsNotifier
                                                  .value;

                                          // Check if the product exists in the current list
                                          bool productExists = currentList
                                              .any((p) => p.id == product.id);

                                          // If quantity is 0, remove the product from the list if it exists
                                          if (quantity == 0) {
                                            for (var productLooped
                                                in currentList) {
                                              if (productLooped.id ==
                                                  product.id) {
                                                bool dateRangeUpdated = false;

                                                // Update borrowQuantity for the specific date range if it exists
                                                if (productLooped.datesUsed !=
                                                        null &&
                                                    product.id! ==
                                                        productLooped.id) {
                                                  for (var elementDateRange
                                                      in productLooped
                                                          .datesUsed!) {
                                                    print("TEASDASDASDS");

                                                    if (elementDateRange.id !=
                                                            null &&
                                                        dataBaseProvider
                                                            .dateRangeMap
                                                            .containsKey(
                                                                elementDateRange
                                                                    .id)) {
                                                      elementDateRange
                                                          .borrowQuantity = 0;
                                                      print("TEASDASDASDS");
// // After updating borrowQuantity to 0
// dataBaseProvider.selectedProductsNotifier.value = List<ProductModel>.from(currentList);

                                                      break;
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                            if (productExists) {
                                              _handleQuantityChanged(
                                                  product.name, quantity);
                                              List<ProductModel> updatedList =
                                                  List<ProductModel>.from(
                                                      currentList);
                                              // updatedList.removeWhere(
                                              //     (p) => p.id == product.id);
                                              dataBaseProvider
                                                  .selectedProductsNotifier
                                                  .value = updatedList;
                                            }
                                            // Remove the product from selectedProductsNotifier

                                            return;
                                          } else {
                                            // Quantity is not 0
                                            if (productExists) {
                                              // Update the existing product's borrowQuantity in datesUsed
                                              for (var productLooped
                                                  in currentList) {
                                                if (productLooped.id ==
                                                    product.id) {
                                                  bool dateRangeUpdated = false;

                                                  // Update borrowQuantity for the specific date range if it exists
                                                  if (productLooped.datesUsed !=
                                                          null &&
                                                      product.id! ==
                                                          productLooped.id) {
                                                    for (var elementDateRange
                                                        in productLooped
                                                            .datesUsed!) {
                                                      if (elementDateRange.id !=
                                                              null &&
                                                          dataBaseProvider
                                                              .dateRangeMap
                                                              .containsKey(
                                                                  elementDateRange
                                                                      .id)) {
                                                        elementDateRange
                                                                .borrowQuantity =
                                                            quantity;
                                                        dateRangeUpdated = true;
                                                        break;
                                                      }
                                                    }
                                                  }

                                                  // If no dateRange was updated, add a new DateRange
                                                  if (!dateRangeUpdated) {
                                                    DateRange newDateRange =
                                                        DateRange(
                                                      id: uuid.v4(),
                                                      start: dataBaseProvider
                                                          .dateRange
                                                          .value
                                                          .start,
                                                      end: dataBaseProvider
                                                          .dateRange.value.end,
                                                      borrowQuantity: quantity,
                                                    );
                                                    productLooped.datesUsed ??=
                                                        [];
                                                    productLooped.datesUsed!
                                                        .add(newDateRange);
                                                    dataBaseProvider
                                                                .dateRangeMap[
                                                            newDateRange.id!] =
                                                        newDateRange;
                                                  }

                                                  print("$productLooped TESTO");
                                                  print(
                                                      "TESTO ---------------------");
                                                  print("$currentList TESTO");
                                                  _handleQuantityChanged(
                                                      productLooped.name,
                                                      quantity);
                                                  break;
                                                }
                                              }
                                            } else {
                                              // Add the product to the list if it doesn't exist
                                              DateRange newDateRange =
                                                  DateRange(
                                                id: uuid.v4(),
                                                start: dataBaseProvider
                                                    .dateRange.value.start,
                                                end: dataBaseProvider
                                                    .dateRange.value.end,
                                                borrowQuantity: quantity,
                                              );
                                              product.datesUsed = [
                                                newDateRange
                                              ];
                                              currentList.add(product);
                                              dataBaseProvider
                                                  .selectedProductsNotifier
                                                  .value = currentList;

                                              // Add to dateRangeMap
                                              dataBaseProvider.dateRangeMap[
                                                      newDateRange.id!] =
                                                  newDateRange;

                                              _handleQuantityChanged(
                                                  product.name, quantity);
                                            }
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            widget.isEditPage
                                ? const Divider(
                                    thickness: 4,
                                  )
                                : Container(),
                            widget.isEditPage
                                ? SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      itemCount: listOfProductsSave.length,
                                      itemBuilder: (context, index) {
                                        const uuid = Uuid();

                                        ProductModel product =
                                            listOfProductsSave[index];

                                        bool isSelected = dataBaseProvider
                                            .selectedProductsNotifier.value
                                            .any((p) => p.id == product.id);

                                        if (productQuantities[product.name] ==
                                            null) {
                                          productQuantities[product.name] =
                                              ValueNotifier<double>(0);
                                        }

                                        if (productTotalPrices[product.name] ==
                                            null) {
                                          productTotalPrices[product.name] =
                                              ValueNotifier<double>(0);
                                        }

                                        return ValueListenableBuilder<double>(
                                          valueListenable:
                                              productQuantities[product.name]!,
                                          builder: (context, quantity, child) {
                                            return ProductTile(
                                              title: GestureDetector(
                                                onTap: () {
                                                  widget.showCalendar(
                                                      index, product, () {
                                                    _handleQuantityChanged(
                                                        product.name, 0);
                                                  });
                                                },
                                                child: Text(product.name),
                                              ),
                                              endDay:
                                                  widget.endDays[product.id] ??
                                                      DateTime.now(),
                                              startDay: widget
                                                      .startDays[product.id] ??
                                                  DateTime.now(),
                                              isEditPage: widget.isEditPage,
                                              dateSelected: widget.selectedDay,
                                              productModel: product,
                                              imagePath: product.file!,
                                              productName: product.name,
                                              initialQuantity: quantity,
                                              productDateRanges:
                                                  widget.productDateRanges,
                                              onQuantityChanged: (quantity) {
                                                print("TEST43434");
                                                // Get the current list of selected products
                                                List<ProductModel> currentList =
                                                    dataBaseProvider
                                                        .selectedProductsNotifier
                                                        .value;

                                                // Check if the product exists in the current list
                                                bool productExists =
                                                    currentList.any((p) =>
                                                        p.id == product.id);

                                                // If quantity is 0, remove the product from the list if it exists
                                                if (quantity == 0 &&
                                                    !widget.isEditPage) {
                                                  if (productExists) {
                                                    _handleQuantityChanged(
                                                        product.name, quantity);
                                                    List<ProductModel>
                                                        updatedList =
                                                        List<ProductModel>.from(
                                                            currentList);
                                                    updatedList.removeWhere(
                                                        (p) =>
                                                            p.id == product.id);
                                                    dataBaseProvider
                                                        .selectedProductsNotifier
                                                        .value = updatedList;
                                                  }
                                                } else {
                                                  // Quantity is not 0
                                                  if (productExists) {
                                                    // Update the existing product's borrowQuantity in datesUsed
                                                    for (var productLooped
                                                        in currentList) {
                                                      if (productLooped.id ==
                                                          product.id) {
                                                        bool dateRangeUpdated =
                                                            false;

                                                        // Update borrowQuantity for the specific date range if it exists
                                                        if (productLooped
                                                                    .datesUsed !=
                                                                null &&
                                                            product.id! ==
                                                                productLooped
                                                                    .id) {
                                                          for (var elementDateRange
                                                              in productLooped
                                                                  .datesUsed!) {
                                                            if (elementDateRange
                                                                        .id !=
                                                                    null &&
                                                                dataBaseProvider
                                                                    .dateRangeMap
                                                                    .containsKey(
                                                                        elementDateRange
                                                                            .id)) {
                                                              elementDateRange
                                                                      .borrowQuantity =
                                                                  quantity;
                                                              dateRangeUpdated =
                                                                  true;
                                                              break;
                                                            }
                                                          }
                                                        }

                                                        // If no dateRange was updated, add a new DateRange
                                                        if (!dateRangeUpdated) {
                                                          DateRange
                                                              newDateRange =
                                                              DateRange(
                                                            id: uuid.v4(),
                                                            start:
                                                                dataBaseProvider
                                                                    .dateRange
                                                                    .value
                                                                    .start,
                                                            end:
                                                                dataBaseProvider
                                                                    .dateRange
                                                                    .value
                                                                    .end,
                                                            borrowQuantity:
                                                                quantity,
                                                          );
                                                          productLooped
                                                              .datesUsed ??= [];
                                                          productLooped
                                                              .datesUsed!
                                                              .add(
                                                                  newDateRange);
                                                          dataBaseProvider
                                                                      .dateRangeMap[
                                                                  newDateRange
                                                                      .id!] =
                                                              newDateRange;
                                                        }

                                                        print(
                                                            "$productLooped TESTO");
                                                        print(
                                                            "TESTO ---------------------");
                                                        print(
                                                            "$currentList TESTO");
                                                        _handleQuantityChanged(
                                                            productLooped.name,
                                                            quantity);
                                                        break;
                                                      }
                                                    }
                                                  } else {
                                                    // Add the product to the list if it doesn't exist
                                                    DateRange newDateRange =
                                                        DateRange(
                                                      id: uuid.v4(),
                                                      start: dataBaseProvider
                                                          .dateRange
                                                          .value
                                                          .start,
                                                      end: dataBaseProvider
                                                          .dateRange.value.end,
                                                      borrowQuantity: quantity,
                                                    );
                                                    product.datesUsed = [
                                                      newDateRange
                                                    ];
                                                    currentList.add(product);
                                                    dataBaseProvider
                                                        .selectedProductsNotifier
                                                        .value = currentList;

                                                    // Add to dateRangeMap
                                                    dataBaseProvider
                                                                .dateRangeMap[
                                                            newDateRange.id!] =
                                                        newDateRange;

                                                    _handleQuantityChanged(
                                                        product.name, quantity);
                                                  }
                                                }
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  )
                                : Container(),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ChooseComponentScreen()),
                                ).then((value) {
                                  dataBaseProvider.selectedCommodities
                                      .notifyListeners();
                                });
                              },
                              child: const Text('Costos adicionales'),
                            ),
                            Column(
                              children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    decoration: const BoxDecoration(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ValueListenableBuilder(
                                            valueListenable: dataBaseProvider
                                                .selectedProductsNotifier,
                                            builder:
                                                (context, productList, child) {
                                              return Column(
                                                children: [
                                                  SizedBox(
                                                    child: ListView.builder(
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      shrinkWrap: true,
                                                      itemCount:
                                                          productList.length,
                                                      itemBuilder:
                                                          (conxtext, i) {
                                                        final product =
                                                            productList[i];
                                                        final productTotalPriceNotifier =
                                                            productTotalPrices[
                                                                product.name]!;
                                                        return ValueListenableBuilder(
                                                          valueListenable:
                                                              productTotalPriceNotifier,
                                                          builder: (context,
                                                              totalPrice,
                                                              child) {
                                                            final startDay =
                                                                widget.startDays[
                                                                    product.id];
                                                            final endDay =
                                                                widget.endDays[
                                                                    product.id];
                                                            if (product
                                                                    .quantity!
                                                                    .value >=
                                                                1) {
                                                              return Container(
                                                                margin: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        8.0),
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        16.0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              16),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.2),
                                                                      spreadRadius:
                                                                          2,
                                                                      blurRadius:
                                                                          8,
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              3),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      product
                                                                          .name,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            20,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            8),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            const Text(
                                                                              "Precio por día:",
                                                                              style: TextStyle(
                                                                                fontSize: 14,
                                                                                color: Colors.black54,
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              "\$${product.unitPrice.toStringAsFixed(2)}",
                                                                              style: const TextStyle(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.black87,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 16), // Space between rows
                                                                            const Text(
                                                                              "Cantidad:",
                                                                              style: TextStyle(
                                                                                fontSize: 14,
                                                                                color: Colors.black54,
                                                                              ),
                                                                            ),
                                                                            ValueListenableBuilder<double>(
                                                                              valueListenable: productQuantities[product.name]!,
                                                                              builder: (context, quantity, child) {
                                                                                return Text(
                                                                                  quantity.toString(),
                                                                                  style: const TextStyle(
                                                                                    fontSize: 16,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    color: Colors.black87,
                                                                                  ),
                                                                                );
                                                                              },
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            const Text(
                                                                              "Días seleccionados:",
                                                                              style: TextStyle(
                                                                                fontSize: 14,
                                                                                color: Colors.black54,
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              startDay != null && endDay != null ? "${endDay.difference(startDay).inDays + 1} días" : " días",
                                                                              style: const TextStyle(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.black87,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 16), // Space between rows
                                                                            const Text(
                                                                              "Precio total:",
                                                                              style: TextStyle(
                                                                                fontSize: 14,
                                                                                color: Colors.black54,
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              startDay != null && endDay != null ? "\$${(endDay.difference(startDay).inDays + 1) * (product.quantity!.value) * (product.unitPrice)}" : "\$0",
                                                                              style: const TextStyle(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.green,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }
                                                            return Container();
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                        ValueListenableBuilder(
                                            valueListenable: dataBaseProvider
                                                .selectedCommodities,
                                            builder:
                                                (context, productList, child) {
                                              return Column(
                                                children: [
                                                  SizedBox(
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      itemCount:
                                                          productList.length,
                                                      itemBuilder:
                                                          (conxtext, i) {
                                                        final product =
                                                            productList[i];

                                                        if (product.quantity!
                                                                .value !=
                                                            0) {
                                                          return Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        8.0),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .grey
                                                                      .withOpacity(
                                                                          0.2),
                                                                  spreadRadius:
                                                                      2,
                                                                  blurRadius: 8,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 3),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  product.name,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        20,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 8),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          "Precio por ${product.unit.toLowerCase()}",
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                Colors.black54,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          "\$${product.unitPrice.toStringAsFixed(2)}",
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.black87,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                16),
                                                                        const Text(
                                                                          "Cantidad:",
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                Colors.black54,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          product
                                                                              .quantity!
                                                                              .value
                                                                              .toString(),
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.black87,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        const SizedBox(
                                                                            height:
                                                                                16),
                                                                        const Text(
                                                                          "Precio total:",
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                Colors.black54,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          (product.quantity!.value * product.unitPrice)
                                                                              .toStringAsFixed(2),
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.green,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                const Center(
                                                                  child: Text(
                                                                    "Costo adicional",
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: Colors
                                                                          .black54,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                        if (dataBaseProvider
                                            .selectedProductsNotifier.value
                                            .where((product) =>
                                                widget.productDateRanges[
                                                        product.id] !=
                                                    null &&
                                                widget
                                                    .productDateRanges[
                                                        product.id]!
                                                    .isNotEmpty)
                                            .isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 16.0,
                                                horizontal: 10.0),
                                            padding: const EdgeInsets.all(16.0),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.2),
                                                  spreadRadius: 2,
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "Precio Total",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                ValueListenableBuilder<double>(
                                                  valueListenable:
                                                      _totalPriceNotifier,
                                                  builder: (context, totalPrice,
                                                      child) {
                                                    return ValueListenableBuilder(
                                                      valueListenable:
                                                          dataBaseProvider
                                                              .selectedCommodities,
                                                      builder: (context,
                                                          selectedCommodities,
                                                          child) {
                                                        final earningsCommodities =
                                                            selectedCommodities
                                                                .fold(0.0, (sum,
                                                                    product) {
                                                          return sum +
                                                              (product.unitPrice *
                                                                  product
                                                                      .quantity!
                                                                      .value);
                                                        });

                                                        return Text(
                                                          "\$${totalPrice + earningsCommodities} ",
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .green[700],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    )),
                              ],
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  bool isAnyDateRangeIdMatching(
      ProductModel product, List<ProductModel> currentList) {
    // Flatten the list of datesUsed from all products in the current list
    List<String?> currentDateRangeIds = currentList
        .expand((p) => p.datesUsed!)
        .map((dateRange) => dateRange.id)
        .toList();

    // Check if any of the product's datesUsed.id matches any id in the current list's datesUsed
    return product.datesUsed!
        .any((dateRange) => currentDateRangeIds.contains(dateRange.id));
  }

  bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    return widget.selectedDay.isAfter(start) &&
            widget.selectedDay.isBefore(end) ||
        widget.selectedDay.isAtSameMomentAs(start) ||
        widget.selectedDay.isAtSameMomentAs(end);
  }
}
