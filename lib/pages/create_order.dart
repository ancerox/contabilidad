import 'dart:io';

import 'package:contabilidad/consts.dart';
import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/date_range.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/choose_component_screen.dart';
import 'package:contabilidad/pages/choose_product_screen.dart';
import 'package:contabilidad/pages/order_created_screen.dart';
import 'package:contabilidad/widget/alquiler_tile.dart';
import 'package:contabilidad/widget/item_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

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
  String totalOwnedGlobal = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cellController = TextEditingController();
  final TextEditingController _directionController = TextEditingController();
  final TextEditingController _commnetController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();
  final TextEditingController _paymentAmountController =
      TextEditingController();
  Map<int, List<DateRange>> productDateRanges = {};
  Map<int, DateTime?> focusedDays = {};
  Map<int, DateTime?> startDays = {};
  Map<int, DateTime?> endDays = {};
  Map<int, RangeSelectionMode> rangeSelectionModes = {};
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
    dataBaseProvider.dateRangeMap.clear();
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
    // _quantityNotifiers.forEach((_, notifier) => notifier.dispose());
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
      List<DateRange>? dateRanges = productDateRanges[product.id];

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
        totalOwned: totalOwnedGlobal,
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
              orderNumber: _orderNumber!,
              totalPrice: dataBaseProvider.totalPriceNotifier.value,
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

    bool hasDatesUsed = widget.order!.productList!.any((product) =>
        product.datesUsed != null && product.datesUsed!.isNotEmpty);

    if (hasDatesUsed) {
      setState(() {
        _selectedOption = 'Alquiler';
      });

      for (var product in widget.order!.productList!) {
        if (product.datesUsed != null && product.datesUsed!.isNotEmpty) {
          productDateRanges[product.id!] = product.datesUsed!;
          focusedDays[product.id!] = product.datesUsed![0].start;
          startDays[product.id!] = product.datesUsed![0].start;
          endDays[product.id!] = product.datesUsed![0].end;
        }
      }
    }

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
      Map<int, List<DateRange>> productDateRanges) {
    double totalCost = 0.0;
    for (var product in selectedProducts) {
      totalCost += calculateCost(product, productDateRanges[product.id] ?? []);
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

  Future<double> calculateTotalRentalPrice(DataBase dataBaseProvider,
      Map<int, List<DateRange>> productDateRanges) async {
    double totalRentalPrice = 0.0;

    for (var entry in productDateRanges.entries) {
      final dateRanges = entry.value;
      final totalDays = dateRanges.fold<int>(
        0,
        (rangeSum, dateRange) =>
            rangeSum + dateRange.end!.difference(dateRange.start!).inDays + 1,
      );

      final product = await dataBaseProvider.getProductById(entry.key);
      if (product != null) {
        totalRentalPrice += totalDays * product.unitPrice;
      }
    }

    return totalRentalPrice;
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
                                isEditPage: widget.isEditPage,
                                selectedDay: _focusedDay,
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
                                            _unitPriceControllers[product.id] ??
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
                                isEditPage: widget.isEditPage,
                                selectedDay: _focusedDay,
                                showCalendar: showCalendar,
                                productDateRanges: productDateRanges,
                                calculateTotalCost: calculateTotalCostRent,
                              ),
                            _selectedOption == 'Alquiler'
                                ? Container()
                                : Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 225, 225, 225)),
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.3,
                                        child: ListView.builder(
                                          itemCount: selectedProducts.length,
                                          itemBuilder: (context, index) {
                                            final product =
                                                selectedProducts[index];
                                            final unitPriceControllers =
                                                _unitPriceControllers[
                                                        product.id] ??
                                                    TextEditingController();
                                            final controller =
                                                _getOrCreateController(
                                                    product.id.toString());
                                            double unitPrice = double.tryParse(
                                                    product.unitPrice
                                                        .toString()) ??
                                                0.0;
                                            int quantity =
                                                product.quantity!.value;

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
                                                totalOwned = totalquantity -
                                                    grantTotalOwned;
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
                                                if (product.quantity!.value ==
                                                    1) {
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
                                    ],
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
                                          Column(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                    ValueListenableBuilder<
                                                        double>(
                                                      valueListenable:
                                                          totalPriceNotifier,
                                                      builder: (context,
                                                          totalPrice, child) {
                                                        return Text(
                                                          "\$ ${olselectedProducts.isNotEmpty ? precioTotalSell(olselectedProducts).toStringAsFixed(2) : totalPrice}",
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 15),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const ChooseComponentScreen()),
                                                  ).then((value) =>
                                                      print("$value TESTO"));
                                                },
                                                child: const Text(
                                                    'Costos adicionales'),
                                              ),
                                            ],
                                          )
                                        ],
                                      );
                                    },
                                  ),
                            const SizedBox(height: 20),
                            const Text(
                              'Ganancias',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: productDateRanges.values.isEmpty
                                  ? const Center(
                                      child: Text(
                                        "Por favor, escoga una fecha",
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
                                          ValueListenableBuilder<double>(
                                            valueListenable: dataBaseProvider
                                                .totalPriceNotifier,
                                            builder:
                                                (context, totalOwned, child) {
                                              return ValueListenableBuilder(
                                                valueListenable: dataBaseProvider
                                                    .selectedProductsNotifier,
                                                builder: (context,
                                                    selectedProducts, child) {
                                                  return ValueListenableBuilder(
                                                    valueListenable:
                                                        dataBaseProvider
                                                            .selectedCommodities,
                                                    builder: (context,
                                                        selectedCommodities,
                                                        child) {
                                                      final alquilerTotal =
                                                          totalOwned -
                                                              selectedProducts
                                                                  .fold(0, (summ,
                                                                      product) {
                                                                final dateRanges =
                                                                    product.datesUsed ??
                                                                        [];
                                                                // final totalDays =
                                                                //    data dateRanges.fold(
                                                                //         0,
                                                                //         (rangeSum,
                                                                //             dateRange) {
                                                                //   return rangeSum +
                                                                //       dateRange
                                                                //           .end!
                                                                //           .difference(
                                                                //               dateRange.start!)
                                                                //           .inDays +
                                                                //       1;
                                                                // });
                                                                int totalDays =
                                                                    0;
                                                                if (endDays[product
                                                                            .id] !=
                                                                        null &&
                                                                    startDays[product
                                                                            .id] !=
                                                                        null) {
                                                                  totalDays = endDays[product
                                                                              .id]!
                                                                          .difference(
                                                                              startDays[product.id]!)
                                                                          .inDays +
                                                                      1;
                                                                }

                                                                final quantity =
                                                                    product.quantity
                                                                            ?.value ??
                                                                        0;
                                                                var totalCost =
                                                                    product.cost *
                                                                        quantity *
                                                                        totalDays;
                                                                if (quantity ==
                                                                    0) {
                                                                  return summ;
                                                                }

                                                                return summ +
                                                                    totalCost
                                                                        .toInt();
                                                              }) +
                                                              dataBaseProvider
                                                                  .selectedCommodities
                                                                  .value
                                                                  .fold(0.0, (sum,
                                                                      product) {
                                                                return sum +
                                                                    (product.unitPrice -
                                                                        product
                                                                            .cost);
                                                              });

                                                      final otherTotal =
                                                          selectedProducts.fold(
                                                              0,
                                                              (sum, product) {
                                                        final unitPrice =
                                                            product.unitPrice;
                                                        final quantity = product
                                                                .quantity
                                                                ?.value ??
                                                            0;
                                                        final productCost =
                                                            product.cost;
                                                        return sum +
                                                            ((unitPrice *
                                                                        quantity) -
                                                                    productCost)
                                                                .toInt();
                                                      });

                                                      return Text(
                                                        _selectedOption ==
                                                                'Alquiler'
                                                            ? "$alquilerTotal"
                                                            : "$otherTotal",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                            ),
                            const Text('Comentario',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              height: size(context).height * 0.111,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
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
                            const Text('Pago',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
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
                            const SizedBox(height: 20),
                            const Text('Total Adeudado',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
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
                                      child: FutureBuilder<double>(
                                        future: calculateTotalRentalPrice(
                                            dataBaseProvider,
                                            productDateRanges),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<double> snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator(); // Show a loading indicator while waiting
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                'Error: ${snapshot.error}');
                                          } else {
                                            final totalRentalPrice =
                                                snapshot.data ?? 0.0;
                                            return ValueListenableBuilder<
                                                double>(
                                              valueListenable: dataBaseProvider
                                                  .totalPriceNotifier,
                                              builder:
                                                  (context, quantity, child) {
                                                return ValueListenableBuilder(
                                                  valueListenable:
                                                      dataBaseProvider
                                                          .selectedCommodities,
                                                  builder: (context,
                                                      selectedCommodities,
                                                      child) {
                                                    final earningsCommodities =
                                                        selectedCommodities
                                                            .fold(0.0,
                                                                (sum, product) {
                                                      return sum +
                                                          (product.unitPrice);
                                                    });
                                                    final totalOwnedOrder =
                                                        productDateRanges
                                                                .isNotEmpty
                                                            ? (quantity -
                                                                    grantTotalOwned +
                                                                    earningsCommodities)
                                                                .toStringAsFixed(
                                                                    2)
                                                            : totalOwned
                                                                .toString();

                                                    totalOwnedGlobal =
                                                        totalOwnedOrder;
                                                    return Text(
                                                      totalOwnedOrder,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          }
                                        },
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

  void showCalendar(
      int index, ProductModel product, Function updateTotalPrice) {
    List<DateRange> selectedDateRanges = productDateRanges[product.id] ?? [];

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
                        // if (!widget.isEditPage) {
                        //   for (var range in product.datesUsed ?? []) {
                        //     if ((range.start != null && range.end != null) &&
                        //         (day.isAfter(range.start!
                        //                 .subtract(const Duration(days: 1))) &&
                        //             day.isBefore(range.end!
                        //                 .add(const Duration(days: 1))))) {
                        //       return false;
                        //     }
                        //   }
                        // }
                        return true;
                      },
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (product.datesUsed != null &&
                              product.datesUsed!.any((element) =>
                                  (day.isAfter(element.start!) &&
                                      day.isBefore(element.end!)) ||
                                  day == element.start ||
                                  day == element.end)) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color:
                                    Colors.grey, // Background color for the day
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
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
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: focusedDays[product.id] ?? DateTime.now(),
                      rangeSelectionMode: rangeSelectionModes[product.id] ??
                          RangeSelectionMode.toggledOff,
                      rangeStartDay: startDays[product.id],
                      rangeEndDay: endDays[product.id],
                      onDaySelected: (selectedDay, focusedDay) {
                        _focusedDay = focusedDay;
                        setState(() {
                          if (startDays[product.id] == null ||
                              endDays[product.id] != null) {
                            // Start a new range selection
                            startDays[product.id!] = selectedDay;
                            endDays[product.id!] = null;
                            rangeSelectionModes[product.id!] =
                                RangeSelectionMode.toggledOff;

                            // Single day selection
                            if (selectedDay == startDays[product.id]) {
                              // Clear end day for single day selection

                              // Handle single day selection logic if any specific logic is required
                              selectedDateRanges = [
                                DateRange(
                                  start: startDays[product.id],
                                  end: startDays[product.id],
                                )
                              ];
                              return;
                            }
                          } else if (selectedDay
                              .isAfter(startDays[product.id]!)) {
                            // Complete the range selection
                            endDays[product.id!] = selectedDay;
                            selectedDateRanges = [
                              DateRange(
                                start: startDays[product.id],
                                end: endDays[product.id],
                              )
                            ];
                          } else if (selectedDay == startDays[product.id]) {
                            // Deselect the start day
                            startDays[product.id!] = null;
                            selectedDateRanges.removeWhere((range) =>
                                range.start == selectedDay &&
                                range.end == selectedDay);
                          } else {
                            // Handle deselection of a previously selected date within a range
                            selectedDateRanges.removeWhere((range) =>
                                selectedDay.isAfter(range.start!
                                    .subtract(const Duration(days: 1))) &&
                                selectedDay.isBefore(
                                    range.end!.add(const Duration(days: 1))));
                            startDays[product.id!] = null;
                            endDays[product.id!] = null;
                            rangeSelectionModes[product.id!] =
                                RangeSelectionMode.toggledOff;
                          }

                          if (startDays[product.id] != null &&
                              endDays[product.id] == null) {
                            selectedDateRanges.clear();
                            productDateRanges.remove(product.id);
                            dataBaseProvider.selectedProductsNotifier.value
                                .removeWhere((p) => p.id == product.id);
                            dataBaseProvider.selectedProductsNotifier
                                .notifyListeners();
                          }
                          focusedDays[product.id!] = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          focusedDays[product.id!] = focusedDay;
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
                                const uuid = Uuid();
                                // Clear all existing date ranges for this product
                                selectedDateRanges.clear();

                                // Create a new DateRange
                                DateRange newRange = DateRange(
                                    start: startDays[product.id],
                                    end: endDays[product.id],
                                    id: uuid.v4());

                                if (endDays[product.id] == null) {
                                  newRange = DateRange(
                                      start: startDays[product.id],
                                      end: startDays[product.id],
                                      id: uuid.v4());
                                }

                                // Add the new date range to the current product only
                                product.datesUsed ??= [];
                                product.datesUsed!.add(newRange);

                                // Add to dateRangeMap
                                dataBaseProvider.dateRangeMap[newRange.id!] =
                                    newRange;

                                selectedDateRanges.add(newRange);
                                dataBaseProvider.dateRange.value = newRange;
                                // dataBaseProvider.dateRangeMap[newRange.id!] =
                                //     newRange;

                                // Update productDateRanges with the current product and its date ranges
                                productDateRanges[product.id!] =
                                    List.from(selectedDateRanges);

                                startDays[product.id!] =
                                    selectedDateRanges.first.start;
                                endDays[product.id!] =
                                    selectedDateRanges.last.end;

                                // Remove the product if it's already in the list
                                dataBaseProvider.selectedProductsNotifier.value
                                    .removeWhere((existingProduct) =>
                                        existingProduct.id == product.id);

                                // Add the product to the selected products list if not already present
                                if (!dataBaseProvider
                                    .selectedProductsNotifier.value
                                    .contains(product)) {
                                  dataBaseProvider
                                      .selectedProductsNotifier.value
                                      .add(product);
                                }
                              });
                              dataBaseProvider.selectedProductsNotifier
                                  .notifyListeners();
                              updateTotalPrice();
                              print("${dataBaseProvider.dateRangeMap} gtg43");
                              Navigator.pop(context);
                            }
                          : () {
                              setState(() {
                                // If start day is selected and end day is null, clear the date ranges for this product
                                selectedDateRanges.clear();
                                print("TEST2");

                                // Remove the product's date ranges from productDateRanges
                                productDateRanges.remove(product.id);

                                // Remove the product from selectedProductsNotifier
                                dataBaseProvider.selectedProductsNotifier.value
                                    .removeWhere((p) => p.id == product.id);
                                dataBaseProvider.selectedProductsNotifier
                                    .notifyListeners();
                              });
                              Navigator.pop(context);
                            },
                      child: Container(
                        height: 50,
                        width: 200,
                        decoration: BoxDecoration(
                          color: selectedDateRanges.isNotEmpty
                              ? Colors.deepPurple.withOpacity(0.6)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            selectedDateRanges.isNotEmpty
                                ? "Continuar"
                                : "Cancelar",
                            style: const TextStyle(
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
  });

  @override
  State<AlquilerWidget> createState() => _AlquilerWidgetState();
}

class _AlquilerWidgetState extends State<AlquilerWidget> {
  late TextEditingController _searchController;
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');
  final Map<String, ValueNotifier<int>> productQuantities = {};
  final Map<String, ValueNotifier<double>> productTotalPrices = {};
  final ValueNotifier<double> _totalPriceNotifier = ValueNotifier<double>(0);
  late DataBase dataBaseProvider;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);

    dataBaseProvider.totalPriceNotifier = _totalPriceNotifier;
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
    // _totalPriceNotifier.dispose();
    super.dispose();
  }

  void _handleQuantityChanged(String productName, int quantity) {
    if (productQuantities[productName] == null) {
      productQuantities[productName] = ValueNotifier<int>(quantity);
    } else {
      productQuantities[productName]!.value = quantity;
    }
    _updateProductTotalPrice(productName);
    _updateTotalPrice();
  }

  double _calculateProductTotalPrice(ProductModel product) {
    final quantity = productQuantities[product.name]?.value ?? 0;
    final dateRanges = widget.productDateRanges[product.id] ?? [];
    final totalDays = dateRanges.fold(
      0,
      (sum, dateRange) =>
          sum + dateRange.end!.difference(dateRange.start!).inDays + 1,
    );
    return totalDays * product.unitPrice * quantity;
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
  }

  @override
  Widget build(BuildContext context) {
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

                        return Column(
                          children: [
                            SizedBox(
                              height: 150,
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
                                        ValueNotifier<int>(0);
                                  }

                                  if (productTotalPrices[product.name] ==
                                      null) {
                                    productTotalPrices[product.name] =
                                        ValueNotifier<double>(0);
                                  }

                                  return ValueListenableBuilder<int>(
                                    valueListenable:
                                        productQuantities[product.name]!,
                                    builder: (context, quantity, child) {
                                      return GestureDetector(
                                          onTap: () {
                                            widget.showCalendar(index, product,
                                                () {
                                              _handleQuantityChanged(
                                                  product.name, quantity);
                                            });
                                          },
                                          child: ProductTile(
                                            dateSelected: widget.selectedDay,
                                            productModel: product,
                                            imagePath: product.file!,
                                            productName: product.name,
                                            initialQuantity: quantity,
                                            productDateRanges:
                                                widget.productDateRanges,
                                            onQuantityChanged: (quantity) {
                                              print(
                                                  " gtg43 ${dataBaseProvider.dateRangeMap}");

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
                                              if (quantity == 0) {
                                                if (productExists) {
                                                  _handleQuantityChanged(
                                                      product.name, quantity);
                                                  List<ProductModel>
                                                      updatedList =
                                                      List<ProductModel>.from(
                                                          currentList);
                                                  updatedList.removeWhere((p) =>
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
                                                        DateRange newDateRange =
                                                            DateRange(
                                                          id: uuid.v4(),
                                                          start:
                                                              dataBaseProvider
                                                                  .dateRange
                                                                  .value
                                                                  .start,
                                                          end: dataBaseProvider
                                                              .dateRange
                                                              .value
                                                              .end,
                                                          borrowQuantity:
                                                              quantity,
                                                        );
                                                        productLooped
                                                            .datesUsed ??= [];
                                                        productLooped.datesUsed!
                                                            .add(newDateRange);
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
                                          ));
                                    },
                                  );
                                },
                              ),
                            ),
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
                                                            return Container(
                                                              margin:
                                                                  const EdgeInsets
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
                                                                          FontWeight
                                                                              .bold,
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
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.black54,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            "\$${product.unitPrice.toStringAsFixed(2)}",
                                                                            style:
                                                                                const TextStyle(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.black87,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 16), // Space between rows
                                                                          const Text(
                                                                            "Cantidad:",
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.black54,
                                                                            ),
                                                                          ),
                                                                          ValueListenableBuilder<
                                                                              int>(
                                                                            valueListenable:
                                                                                productQuantities[product.name]!,
                                                                            builder: (context,
                                                                                quantity,
                                                                                child) {
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
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.black54,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            "${widget.productDateRanges[product.id]?.fold<int>(0, (sum, dateRange) => sum + dateRange.end!.difference(dateRange.start!).inDays + 1) ?? 0} días",
                                                                            style:
                                                                                const TextStyle(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.black87,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 16), // Space between rows
                                                                          const Text(
                                                                            "Precio total:",
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.black54,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            "\$${totalPrice.toStringAsFixed(2)}",
                                                                            style:
                                                                                const TextStyle(
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
                                                            color: Colors.white,
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
                                                                spreadRadius: 2,
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
                                                                  fontSize: 20,
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
                                                                        (product.quantity!.value *
                                                                                product.unitPrice)
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
                                                              (product
                                                                  .unitPrice);
                                                        });
                                                        return Text(
                                                          "\$${totalPrice + earningsCommodities}",
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
