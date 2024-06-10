import 'dart:io';

import 'package:contabilidad/consts.dart';
import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/date_range.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/choose_product_screen.dart';
import 'package:contabilidad/pages/order_created_screen.dart';
import 'package:contabilidad/widget/item_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CreateOrderScreen extends StatefulWidget {
  final OrderModel? order;
  final bool isEditPage;

  const CreateOrderScreen({super.key, required this.isEditPage, this.order});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  ValueNotifier<List<ProductModel>> products = ValueNotifier([]);
  ValueNotifier<double> totalPriceNotifier = ValueNotifier<double>(0.0);

  int? orderId;
  String? _selectedOption;
  double margin = 0;
  int totalOwned = 0;
  int grantTotalCost = 0;
  int grantTotalPrice = 0;
  int grantTotalOwned = 0;
  List<PagoModel> pagos = [];

  late DataBase dataBaseProvider;
  final Map<String, ValueNotifier<int>> _quantityNotifiers = {};
  ValueNotifier<bool> isCheckoutButtonEnabled = ValueNotifier(false);
  Map<ProductModel, int> selectedProducts = {};
  final Map<int, TextEditingController> _unitPriceControllers = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cellController = TextEditingController();
  final TextEditingController _directionController = TextEditingController();
  final TextEditingController _commnetController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();
  final TextEditingController _paymentAmountController =
      TextEditingController();
  Map<ProductModel, List<DateRange>> productDateRanges = {};
  Map<ProductModel, DateTime?> focusedDays = {};
  Map<ProductModel, DateTime?> startDays = {};
  Map<ProductModel, DateTime?> endDays = {};
  Map<ProductModel, RangeSelectionMode> rangeSelectionModes = {};
  int? _orderNumber;

  Map<int, ValueNotifier<int>> productQuantities = {};
  bool isOrdenExpress = false;
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: const Text(
              '¿Estás seguro que deseas cambiar de tipo de orden? vas a perder los datos'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Retorna false
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Retorna true
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _onOptionSelected(String option) async {
    if (dataBaseProvider.selectedProductsNotifier.value.isNotEmpty ||
        productDateRanges.isNotEmpty) {
      final onOptionSelected = await _showConfirmationDialog(context);
      if (onOptionSelected == true) {
        setState(() {
          _selectedOption = option;
          dataBaseProvider.selectedProductsNotifier.value = [];
          productDateRanges.clear();
          startDays.clear();
          endDays.clear();
          rangeSelectionModes.clear();
          focusedDays.clear();
        });
        return;
      } else {
        return;
      }
    }
    setState(() {
      _selectedOption = option;
    });
  }

  @override
  void dispose() {
    dataBaseProvider.selectedProductsNotifier.value.clear();
    _unitPriceControllers.forEach((_, controller) => controller.dispose());
    _dateController.dispose();
    _nameController.dispose();
    _cellController.dispose();
    _directionController.dispose();
    _commnetController.dispose();
    _totalController.dispose();
    _paymentDateController.dispose();
    _paymentAmountController.dispose();
    _quantityControllers.forEach((_, controller) => controller.dispose());
    _quantityNotifiers.forEach((_, notifier) => notifier.dispose());
    products.dispose();
    totalPriceNotifier.dispose();
    isCheckoutButtonEnabled.dispose();
    super.dispose();
  }

  Future<void> _fetchNextOrderNumber() async {
    final nextOrderNumber = await dataBaseProvider.getTotalOrdersCount();
    setState(() {
      _orderNumber = nextOrderNumber;
    });
  }

  void _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        controller.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _updateSelectedProductQuantity(
      ProductModel product, int change, bool isOverwrite) {
    final currentQuantity = selectedProducts[product] ?? 0;
    int updatedQuantity = isOverwrite ? change : currentQuantity + change;

    if (updatedQuantity <= 0) {
      selectedProducts.remove(product);
      _unitPriceControllers.remove(product.id);
    } else {
      selectedProducts[product] = updatedQuantity;
      double unitPrice = double.tryParse(product.unitPrice.toString()) ?? 0.0;
      double totalPrice = updatedQuantity * unitPrice;
      _unitPriceControllers[product.id]?.text = totalPrice.toStringAsFixed(2);
    }

    _calculateTotalPrice();
    _updateCheckoutButtonState();
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (var product in dataBaseProvider.selectedProductsNotifier.value) {
      double unitPrice = double.tryParse(product.unitPrice.toString()) ?? 0.0;
      int quantity = product.quantity?.value ?? 0;

      // Get the corresponding date ranges for the current product
      List<DateRange>? dateRanges = productDateRanges[product];

      // Calculate the cost for the product considering its date ranges
      total += calculateCost(product, dateRanges ?? []);
    }
    totalPriceNotifier.value = total;
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

  _onCreateOrder() async {
    if (_formKey.currentState!.validate()) {
      if (_totalController.text.isEmpty) _totalController.text = "0";

      int newOrderNumber = await dataBaseProvider.getTotalOrdersCount();

      final listProducts = dataBaseProvider.selectedProductsNotifier.value;
      final order = OrderModel(
        datesInUse: productDateRanges.values.expand((e) => e).toList(),
        pagos: pagos,
        productList: listProducts,
        orderNumber: newOrderNumber.toString(),
        totalOwned: productDateRanges.isNotEmpty
            ? "${productDateRanges.values.first[0].end!.difference(productDateRanges.values.first[0].start!).inDays + 1 - grantTotalOwned}"
            : totalOwned.toString(),
        margen: margin.toString(),
        status: "pendiente",
        clientName: _nameController.text,
        celNumber: _cellController.text,
        direccion: _directionController.text,
        date: _dateController.text,
        comment: _commnetController.text,
        totalCost: double.parse(_totalController.text),
      );

      if (widget.isEditPage && widget.order != null) {
        order.id = orderId;
        await dataBaseProvider.updateOrderWithProducts(
            widget.order!.id!, order, listProducts);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden actualizada con éxito')),
        );
        Navigator.pop(context, true);
        return;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderCreatedScreen(
              markedDays: productDateRanges.values.expand((e) => e).toList(),
              orderModel: order,
              productModelList: listProducts,
            ),
          ),
        );
        return;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    for (int i = 0; i < products.value.length; i++) {
      _unitPriceControllers[i] = TextEditingController();
    }
    _dateController.text = DateFormat('MM/dd/yyyy').format(DateTime.now());
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _fetchNextOrderNumber();

    if (widget.isEditPage && widget.order != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeEditOrder();
      });
    }
  }

  void _initializeEditOrder() {
    orderId = widget.order!.id;
    dataBaseProvider.selectedProductsNotifier.value =
        widget.order!.productList!;
    pagos = widget.order!.pagos;
    grantTotalOwned = pagos.fold(0, (sum, pago) => sum + pago.amount.toInt());
    _nameController.text = widget.order!.clientName;
    _cellController.text = widget.order!.celNumber;
    _directionController.text = widget.order!.direccion;
    _dateController.text = widget.order!.date;
    _commnetController.text = widget.order!.comment;
    _totalController.text = widget.order!.totalCost.toString();

    _calculateTotalPrice();
  }

  void _updateCheckoutButtonState() {
    bool hasProductsInCart = _quantityNotifiers.values
        .any((quantityNotifier) => quantityNotifier.value > 0);
    isCheckoutButtonEnabled.value = hasProductsInCart;
  }

  TextEditingController _getOrCreateController(String productId) {
    return _quantityControllers.putIfAbsent(
        productId, () => TextEditingController());
  }

  ValueNotifier<int> _getOrCreateQuantityNotifier(String productId) {
    return _quantityNotifiers.putIfAbsent(
        productId, () => ValueNotifier<int>(0));
  }

  int calculateTotalUnavailableDays(List<DateRange> dateRanges) {
    int totalDays = 0;
    for (var dateRange in dateRanges) {
      if (dateRange.start != null && dateRange.end != null) {
        totalDays += dateRange.end!.difference(dateRange.start!).inDays + 1;
      }
    }
    return totalDays;
  }

  double calculateCost(ProductModel product, List<DateRange> dateRanges) {
    int totalDays = calculateTotalUnavailableDays(dateRanges);
    return totalDays * product.unitPrice;
  }

  double calculateTotalCostRent(List<ProductModel> selectedProducts,
      Map<ProductModel, List<DateRange>> productDateRanges) {
    double totalCost = 0.0;
    for (var product in selectedProducts) {
      totalCost += calculateCost(product, productDateRanges[product] ?? []);
    }
    return totalCost;
  }

  double precioTotalSell(List<ProductModel> products) {
    double totalPrice = 0.0;
    for (ProductModel product in products) {
      totalPrice += product.unitPrice * product.quantity!.value;
    }
    return totalPrice;
  }

  void _addPago() {
    if (_paymentDateController.text.isNotEmpty &&
        _paymentAmountController.text.isNotEmpty) {
      setState(() {
        pagos.add(PagoModel(
          date: _paymentDateController.text,
          amount: double.parse(_paymentAmountController.text),
        ));
        totalOwned -= int.parse(_paymentAmountController.text);
        grantTotalOwned =
            pagos.fold(0, (sum, pago) => sum + pago.amount.toInt());
        _paymentDateController.clear();
        _paymentAmountController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: Row(
          children: [
            const Text('Crear orden'),
            const Spacer(),
            widget.isEditPage
                ? Container()
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        isOrdenExpress = !isOrdenExpress;
                      });
                    },
                    child: Container(
                      height: 40,
                      width: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xffA338FF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade200.withOpacity(0.6),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 20,
                          ),
                          isOrdenExpress
                              ? const Text(
                                  "Full order",
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                )
                              : const Text(
                                  "Orden Express",
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                        ],
                      ),
                    ),
                  )
          ],
        ),
      ),
      body: isOrdenExpress
          ? SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Información de la orden',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text('Por favor, selecione el tipo de producto'),
                    const SizedBox(height: 5),
                    WidgetSelector(
                      onOptionSelected: dataBaseProvider
                              .selectedProductsNotifier.value.isNotEmpty ||
                          productDateRanges.isNotEmpty,
                      onSelected: _onOptionSelected,
                      onSetState: () {
                        setState(() {
                          _calculateTotalPrice();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                        child: ValueListenableBuilder<List<ProductModel>>(
                      valueListenable:
                          dataBaseProvider.selectedProductsNotifier,
                      builder: (context, selectedProducts, child) {
                        int totalquantity = selectedProducts.fold(
                            0,
                            (int sum, ProductModel product) =>
                                sum +
                                product.unitPrice.toInt() *
                                    product.quantity!.value);
                        int totalCost = selectedProducts.fold(
                            0,
                            (int sum, ProductModel product) =>
                                sum +
                                product.cost.toInt() * product.quantity!.value);
                        totalOwned = totalquantity - grantTotalOwned;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedOption == 'Alquiler')
                              AlquilerWidget(
                                dataBaseProvider: dataBaseProvider,
                                showCalendar: showCalendar,
                                productDateRanges: productDateRanges,
                                calculateTotalCost: calculateTotalCostRent,
                              ),
                            _selectedOption == 'Alquiler'
                                ? Container()
                                : Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 225, 225, 225)),
                                    height: MediaQuery.of(context).size.height *
                                        0.3,
                                    child: ListView.builder(
                                      itemCount: selectedProducts.length,
                                      itemBuilder: (context, index) {
                                        final product = selectedProducts[index];
                                        final unitPriceControllers =
                                            _unitPriceControllers[index] ??
                                                TextEditingController();
                                        final controller =
                                            _getOrCreateController(
                                                product.id.toString());
                                        double unitPrice = double.tryParse(
                                                product.unitPrice.toString()) ??
                                            0.0;
                                        int quantity = product.quantity!.value;

                                        double totalPrice =
                                            quantity * unitPrice;
                                        double totalcost =
                                            product.cost * quantity;

                                        unitPriceControllers.text =
                                            totalPrice.toString();

                                        return Item(
                                          subProducts: product.subProduct,
                                          costOnChange: (String value) {
                                            if (value != "") {
                                              product.cost =
                                                  double.parse(value);
                                              _calculateTotalPrice();
                                            }
                                          },
                                          onFieldSubmitted: (String value) {
                                            setState(() {});
                                          },
                                          cost: totalcost,
                                          imagePath: product.file!,
                                          name: product.name,
                                          precio: product.unitPrice,
                                          quantityOnChange: (String value) {
                                            if (value == "") {
                                              return;
                                            }
                                            product.quantity!.value =
                                                int.parse(value);
                                            _updateCheckoutButtonState();
                                            _updateSelectedProductQuantity(
                                                product,
                                                int.parse(controller.text),
                                                true);
                                            totalOwned =
                                                totalquantity - grantTotalOwned;
                                            _calculateTotalPrice();
                                            setState(() {});
                                          },
                                          plus: () {
                                            product.quantity!.value++;
                                            _updateCheckoutButtonState();
                                            _updateSelectedProductQuantity(
                                                product, 1, false);
                                            _calculateTotalPrice();
                                            setState(() {});
                                          },
                                          minus: () {
                                            if (product.quantity!.value == 1) {
                                              setState(() {
                                                selectedProducts
                                                    .remove(product);
                                                _calculateTotalPrice();
                                              });
                                              return;
                                            }

                                            product.quantity!.value--;
                                            _updateCheckoutButtonState();
                                            _updateSelectedProductQuantity(
                                                product, -1, false);
                                            _calculateTotalPrice();
                                            setState(() {});
                                          },
                                          hasTrailing: true,
                                          quantity: product.quantity!,
                                          quantityCTRController: controller,
                                          magnitud: product.unit,
                                          unitPriceCTRController:
                                              unitPriceControllers,
                                        );
                                      },
                                    ),
                                  ),
                            _selectedOption == 'Alquiler'
                                ? Container()
                                : ValueListenableBuilder<List<ProductModel>>(
                                    valueListenable: dataBaseProvider
                                        .selectedProductsNotifier,
                                    builder:
                                        (context, olselectedProducts, child) {
                                      return Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20),
                                            height: 40,
                                            decoration: const BoxDecoration(
                                                color: Color.fromARGB(
                                                    255, 226, 213, 78)),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text("Precio Total",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15)),
                                                ValueListenableBuilder<double>(
                                                  valueListenable:
                                                      totalPriceNotifier,
                                                  builder: (context, totalPrice,
                                                      child) {
                                                    return Text(
                                                      "\$ ${olselectedProducts.isNotEmpty ? precioTotalSell(olselectedProducts).toStringAsFixed(2) : totalPrice}",
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                            const SizedBox(height: 20),
                            const Text('Pago',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      const Color.fromARGB(255, 202, 202, 202)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  ...pagos.map((pago) {
                                    return ListTile(
                                      title: Text(
                                          'Pago: ${pago.amount}, Fecha: ${pago.date}'),
                                    );
                                  }),
                                  TextFormField(
                                    controller: _paymentDateController,
                                    onTap: () {
                                      _selectDate(
                                          context, _paymentDateController);
                                    },
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Fecha del pago',
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _paymentAmountController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Monto del pago',
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _addPago,
                                    child: const Text('Agregar Pago'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    )),
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
                            onPressed: () async {
                              _onCreateOrder();
                            },
                            child: const Text(
                              "Continuar",
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Ordern #$_orderNumber',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    const Text('Información contacto',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextFormField(
                      validator: isOrdenExpress
                          ? (String? validator) {
                              return null;
                            }
                          : (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingrese el nombre del cliente';
                              }
                              return null;
                            },
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del cliente',
                      ),
                    ),
                    TextFormField(
                      validator: isOrdenExpress
                          ? (String? validator) {
                              return null;
                            }
                          : (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingrese el número de celular';
                              }
                              return null;
                            },
                      controller: _cellController,
                      decoration: const InputDecoration(
                        labelText: 'Celular',
                      ),
                    ),
                    TextFormField(
                      validator: isOrdenExpress
                          ? (String? validator) {
                              return null;
                            }
                          : (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingrese la dirección';
                              }
                              return null;
                            },
                      controller: _directionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Información de la orden',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text('Por favor, selecione el tipo de producto'),
                    const SizedBox(height: 5),
                    WidgetSelector(
                      onOptionSelected: dataBaseProvider
                              .selectedProductsNotifier.value.isNotEmpty ||
                          productDateRanges.isNotEmpty,
                      onSelected: _onOptionSelected,
                      onSetState: () {
                        setState(() {
                          _calculateTotalPrice();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<List<ProductModel>>(
                      valueListenable:
                          dataBaseProvider.selectedProductsNotifier,
                      builder: (context, selectedProducts, child) {
                        int totalquantity = selectedProducts.fold(
                            0,
                            (int sum, ProductModel product) =>
                                sum +
                                product.unitPrice.toInt() *
                                    product.quantity!.value);
                        int totalCost = selectedProducts.fold(
                            0,
                            (int sum, ProductModel product) =>
                                sum +
                                product.cost.toInt() * product.quantity!.value);
                        totalOwned = totalquantity - grantTotalOwned;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedOption == 'Alquiler')
                              AlquilerWidget(
                                dataBaseProvider: dataBaseProvider,
                                showCalendar: showCalendar,
                                productDateRanges: productDateRanges,
                                calculateTotalCost: calculateTotalCostRent,
                              ),
                            _selectedOption == 'Alquiler'
                                ? Container()
                                : Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 225, 225, 225)),
                                    height: MediaQuery.of(context).size.height *
                                        0.3,
                                    child: ListView.builder(
                                      itemCount: selectedProducts.length,
                                      itemBuilder: (context, index) {
                                        final product = selectedProducts[index];
                                        final unitPriceControllers =
                                            _unitPriceControllers[index] ??
                                                TextEditingController();
                                        final controller =
                                            _getOrCreateController(
                                                product.id.toString());
                                        double unitPrice = double.tryParse(
                                                product.unitPrice.toString()) ??
                                            0.0;
                                        int quantity = product.quantity!.value;

                                        double totalPrice =
                                            quantity * unitPrice;
                                        double totalcost =
                                            product.cost * quantity;

                                        unitPriceControllers.text =
                                            totalPrice.toString();

                                        return Item(
                                          subProducts: product.subProduct,
                                          costOnChange: (String value) {
                                            if (value != "") {
                                              product.cost =
                                                  double.parse(value);
                                              _calculateTotalPrice();
                                            }
                                          },
                                          onFieldSubmitted: (String value) {
                                            setState(() {});
                                          },
                                          cost: totalcost,
                                          imagePath: product.file!,
                                          name: product.name,
                                          precio: product.unitPrice,
                                          quantityOnChange: (String value) {
                                            if (value == "") {
                                              return;
                                            }
                                            product.quantity!.value =
                                                int.parse(value);
                                            _updateCheckoutButtonState();
                                            _updateSelectedProductQuantity(
                                                product,
                                                int.parse(controller.text),
                                                true);
                                            totalOwned =
                                                totalquantity - grantTotalOwned;
                                            _calculateTotalPrice();
                                            setState(() {});
                                          },
                                          plus: () {
                                            product.quantity!.value++;
                                            _updateCheckoutButtonState();
                                            _updateSelectedProductQuantity(
                                                product, 1, false);
                                            _calculateTotalPrice();
                                            setState(() {});
                                          },
                                          minus: () {
                                            if (product.quantity!.value == 1) {
                                              setState(() {
                                                selectedProducts
                                                    .remove(product);
                                                _calculateTotalPrice();
                                              });
                                              return;
                                            }

                                            product.quantity!.value--;
                                            _updateCheckoutButtonState();
                                            _updateSelectedProductQuantity(
                                                product, -1, false);
                                            _calculateTotalPrice();
                                            setState(() {});
                                          },
                                          hasTrailing: true,
                                          quantity: product.quantity!,
                                          quantityCTRController: controller,
                                          magnitud: product.unit,
                                          unitPriceCTRController:
                                              unitPriceControllers,
                                        );
                                      },
                                    ),
                                  ),
                            _selectedOption == 'Alquiler'
                                ? Container()
                                : ValueListenableBuilder<List<ProductModel>>(
                                    valueListenable: dataBaseProvider
                                        .selectedProductsNotifier,
                                    builder:
                                        (context, olselectedProducts, child) {
                                      return Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20),
                                            height: 40,
                                            decoration: const BoxDecoration(
                                                color: Color.fromARGB(
                                                    255, 226, 213, 78)),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text("Precio Total",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15)),
                                                ValueListenableBuilder<double>(
                                                  valueListenable:
                                                      totalPriceNotifier,
                                                  builder: (context, totalPrice,
                                                      child) {
                                                    return Text(
                                                      "\$ ${olselectedProducts.isNotEmpty ? precioTotalSell(olselectedProducts).toStringAsFixed(2) : totalPrice}",
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                            const SizedBox(height: 20),
                            const Text('Comentario',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              height: size(context).height * 0.111,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      const Color.fromARGB(255, 202, 202, 202)),
                              child: TextFormField(
                                controller: _commnetController,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Escribe tu comentario aquí...',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Ganancias',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 202, 202, 202),
                              ),
                              child: selectedProducts.isEmpty &&
                                      productDateRanges.values.isEmpty
                                  ? const Center(
                                      child: Text(
                                        "Por favor, escoga al menos un producto",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      width: double.infinity,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            productDateRanges.isNotEmpty
                                                ? "${productDateRanges.entries.fold(0, (sum, entry) => sum + entry.value.fold(0, (rangeSum, dateRange) => rangeSum + dateRange.end!.difference(dateRange.start!).inDays + 1)) - selectedProducts.fold(0, (costSum, product) => costSum + product.cost)} "
                                                : "${totalquantity - totalCost}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Pago',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      const Color.fromARGB(255, 202, 202, 202)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  ...pagos.map((pago) {
                                    return ListTile(
                                      title: Text(
                                          'Pago: ${pago.amount}, Fecha: ${pago.date}'),
                                    );
                                  }),
                                  TextFormField(
                                    controller: _paymentDateController,
                                    onTap: () {
                                      _selectDate(
                                          context, _paymentDateController);
                                    },
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Fecha del pago',
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _paymentAmountController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Monto del pago',
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _addPago,
                                    child: const Text('Agregar Pago'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Total Adeudado',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 202, 202, 202),
                              ),
                              child: selectedProducts.isEmpty &&
                                      productDateRanges.values.isEmpty
                                  ? const Center(
                                      child: Text(
                                        "Por favor, escoga al menos un producto",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      width: double.infinity,
                                      child: Text(
                                        // Check if there are any entries in productDateRanges
                                        productDateRanges.isNotEmpty
                                            ? productDateRanges.entries
                                                .map((entry) {
                                                // Assuming you want to calculate the difference for the first entry in the map
                                                DateRange firstDateRange =
                                                    entry.value[0];
                                                return "${firstDateRange.end!.difference(firstDateRange.start!).inDays + 1 - grantTotalOwned}";
                                              }).first // Take the first calculated value
                                            : totalOwned.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              margin: const EdgeInsets.all(20),
                              width: double.infinity,
                              height: 70,
                              child: ValueListenableBuilder(
                                valueListenable: isCheckoutButtonEnabled,
                                builder: (context, value, child) {
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 108, 40, 123),
                                      textStyle: const TextStyle(fontSize: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      _onCreateOrder();
                                    },
                                    child: const Text(
                                      "Continuar",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  void showCalendar(int index, ProductModel product) {
    List<DateRange> selectedDateRanges = productDateRanges[product] ?? [];

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext builder) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Select a Date',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TableCalendar(
                      enabledDayPredicate: (day) {
                        for (var range in product.datesNotAvailable ?? []) {
                          if ((range.start != null && range.end != null) &&
                              (day.isAfter(range.start!
                                      .subtract(const Duration(days: 1))) &&
                                  day.isBefore(range.end!
                                      .add(const Duration(days: 1))))) {
                            return false;
                          }
                        }
                        for (var range in product.datesUsed ?? []) {
                          if ((range.start != null && range.end != null) &&
                              (day.isAfter(range.start!
                                      .subtract(const Duration(days: 1))) &&
                                  day.isBefore(range.end!
                                      .add(const Duration(days: 1))))) {
                            return false;
                          }
                        }
                        return true;
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon:
                            Icon(Icons.chevron_left, color: Colors.deepPurple),
                        rightChevronIcon:
                            Icon(Icons.chevron_right, color: Colors.deepPurple),
                        titleTextStyle:
                            TextStyle(fontSize: 18, color: Colors.deepPurple),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          for (var range in selectedDateRanges) {
                            if (day.isAfter(range.start!
                                    .subtract(const Duration(days: 1))) &&
                                day.isBefore(
                                    range.end!.add(const Duration(days: 1)))) {
                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  day.day.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }
                          }
                          return null;
                        },
                      ),
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: focusedDays[product] ?? DateTime.now(),
                      rangeSelectionMode: rangeSelectionModes[product] ??
                          RangeSelectionMode.toggledOff,
                      rangeStartDay: startDays[product],
                      rangeEndDay: endDays[product],
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          startDays[product];
                          if (startDays[product] == null ||
                              endDays[product] != null) {
                            startDays[product] = selectedDay;
                            endDays[product] = null;
                            rangeSelectionModes[product] =
                                RangeSelectionMode.toggledOff;
                          } else if (selectedDay.isAfter(startDays[product]!)) {
                            endDays[product] = selectedDay;
                            selectedDateRanges.add(DateRange(
                                start: startDays[product],
                                end: endDays[product]));
                          }
                          focusedDays[product] = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          focusedDays[product] = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        rangeHighlightColor: Colors.deepPurple.withOpacity(0.6),
                        rangeStartDecoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        outsideDaysVisible: false,
                      ),
                    ),
                    GestureDetector(
                      onTap: selectedDateRanges.isNotEmpty
                          ? () {
                              setState(() {
                                productDateRanges[product] =
                                    List.from(selectedDateRanges);
                                startDays[product] =
                                    selectedDateRanges.first.start;
                                endDays[product] = selectedDateRanges.last.end;
                              });
                              Navigator.pop(context);
                            }
                          : null,
                      child: Container(
                        height: 50,
                        width: 200,
                        decoration: BoxDecoration(
                          color: selectedDateRanges.isNotEmpty
                              ? Colors.deepPurple.withOpacity(0.6)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            "Continue",
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }).then((value) => setState(() {
          _calculateTotalPrice();
        }));
  }
}

class WidgetSelector extends StatelessWidget {
  final bool onOptionSelected;
  final Function(String) onSelected;
  final Function onSetState;

  const WidgetSelector({
    super.key,
    required this.onOptionSelected,
    required this.onSelected,
    required this.onSetState,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton(
          onPressed: () {
            onSelected('Venta');
            !onOptionSelected
                ? Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChoseProductOrdenScreen()))
                    .then((value) {
                    onSetState();
                  })
                : null;
          },
          child: const Text('Venta'),
        ),
        ElevatedButton(
          onPressed: () => onSelected('Alquiler'),
          child: const Text('Alquiler'),
        ),
      ],
    );
  }
}

class VentaWidget extends StatefulWidget {
  final DataBase dataBaseProvider;

  const VentaWidget({super.key, required this.dataBaseProvider});

  @override
  State<VentaWidget> createState() => _VentaWidgetState();
}

class _VentaWidgetState extends State<VentaWidget> {
  late TextEditingController _searchController;
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTextNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: widget.dataBaseProvider.obtenerProductos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          var products = snapshot.data ?? [];

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
                        },
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: _searchTextNotifier,
                  builder: (context, value, _) {
                    final filteredProducts = products.where((product) {
                      return product.name
                          .toLowerCase()
                          .contains(value.toLowerCase());
                    }).toList();

                    return SizedBox(
                      height: 400,
                      child: ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];

                          return ListTile(
                            leading: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                    fit: BoxFit.contain,
                                    image: FileImage(File(product.file!)),
                                  ),
                                  color: const Color(0xffD8DFFF),
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            title: Text(product.name),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class AlquilerWidget extends StatefulWidget {
  final DataBase dataBaseProvider;
  final void Function(int, ProductModel) showCalendar;
  final Map<ProductModel, List<DateRange>> productDateRanges;
  final double Function(List<ProductModel>, Map<ProductModel, List<DateRange>>)
      calculateTotalCost;

  const AlquilerWidget({
    super.key,
    required this.dataBaseProvider,
    required this.showCalendar,
    required this.productDateRanges,
    required this.calculateTotalCost,
  });

  @override
  State<AlquilerWidget> createState() => _AlquilerWidgetState();
}

class _AlquilerWidgetState extends State<AlquilerWidget> {
  late TextEditingController _searchController;
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');
  int newIndex = -1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTextNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: widget.dataBaseProvider.obtenerProductos(),
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
                                product.productCategory == "En alquiler")
                            .toList();

                        // Filter only products with selected date ranges
                        List<ProductModel> productsWithDateRanges =
                            filteredProducts.where((product) {
                          return widget.productDateRanges[product] != null &&
                              widget.productDateRanges[product]!.isNotEmpty;
                        }).toList();

                        return Column(
                          children: [
                            SizedBox(
                              height: 150,
                              child: ListView.builder(
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  ProductModel product =
                                      filteredProducts[index];

                                  return GestureDetector(
                                    onTap: () {
                                      widget.showCalendar(index, product);
                                    },
                                    child: ListTile(
                                      leading: Container(
                                        height: 30,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            fit: BoxFit.contain,
                                            image:
                                                FileImage(File(product.file!)),
                                          ),
                                          color: const Color(0xffD8DFFF),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      title: Text(product.name),
                                      trailing: index == newIndex
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            )
                                          : const SizedBox(
                                              height: 10,
                                              width: 10,
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 226, 213, 78)),
                                  child: productsWithDateRanges.isEmpty
                                      ? const Center(
                                          child: Text(
                                            "Ningun dia seleccionado",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: productsWithDateRanges
                                              .map((product) {
                                            final dateRanges = widget
                                                .productDateRanges[product];
                                            final totalDays =
                                                dateRanges != null &&
                                                        dateRanges.isNotEmpty
                                                    ? dateRanges.fold(
                                                        0,
                                                        (sum, dateRange) =>
                                                            sum +
                                                            dateRange.end!
                                                                .difference(
                                                                    dateRange
                                                                        .start!)
                                                                .inDays +
                                                            1)
                                                    : 0;
                                            return Text(
                                              "${product.name} precio por día | $totalDays días x ${product.unitPrice}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                ),
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
}
