import 'dart:io';

import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/create_order.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  String _selectedStatus = 'historial';
  String _filterText = '';
  String _filterBy = 'Nombre';
  DateTime? _selectedDate;

  List<OrderModel> get orders => _orders;
  String get selectedStatus => _selectedStatus;
  String get filterText => _filterText;
  String get filterBy => _filterBy;
  DateTime? get selectedDate => _selectedDate;

  void clearSelectedDate() {
    _selectedDate = null;
    notifyListeners();
  }

  void setOrders(List<OrderModel> orders) {
    _orders = orders;
    notifyListeners();
  }

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setFilterText(String text) {
    _filterText = text;
    notifyListeners();
  }

  void setFilterBy(String filterBy) {
    _filterBy = filterBy;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  List<OrderModel> get filteredOrders {
    List<OrderModel> filteredOrderList = _orders.where((OrderModel order) {
      print(
          "Order ID: ${order.id}, Status: ${order.status}, Product List: ${order.productList?.length ?? 0}");

      // Ensure orders with status 'Pago' are only shown in 'Transacciones'
      if (order.status == 'Pago' ||
          order.status == "Costo de orden" ||
          order.status == "Produccion" ||
          order.status == "Gasto") {
        if (_selectedStatus == 'Transacciones') {
          print("Showing 'Pago' order in Transacciones.");
          return true;
        } else {
          // Explicitly exclude 'Pago' orders from 'Historial' or other sections
          return false;
        }
      }

      // Handle 'Compra' status
      if (order.status == 'Compra') {
        if (order.productList?.isNotEmpty == true) {
          if (_selectedStatus == 'historial') {
            print(
                "Showing 'Compra' order in Historial because it has products.");
            return true;
          }
        } else if (_selectedStatus == 'Transacciones') {
          print(
              "Showing 'Compra' order in Transacciones because it has no products.");
          return true;
        }
      }

      // Handle other statuses normally
      if (_selectedStatus == 'Transacciones') {
        return order.status == _selectedStatus &&
            order.productList?.isEmpty == true;
      } else if (_selectedStatus == 'historial') {
        return order.status != 'Pago' &&
            (order.status != 'Compra' || order.productList?.isNotEmpty == true);
      }

      // Default behavior
      return order.status == _selectedStatus || _selectedStatus == 'historial';
    }).toList();

    // Additional filtering by date, status, name, etc.
    if (_filterBy == 'Fecha' && _selectedDate != null) {
      filteredOrderList = filteredOrderList.where((OrderModel order) {
        try {
          DateTime parsedDate = _parseDate(order.date);
          return DateFormat('MM/dd/yyyy').format(parsedDate) ==
              DateFormat('MM/dd/yyyy').format(_selectedDate!);
        } catch (e) {
          print('Error parsing date: $e');
          return false;
        }
      }).toList();
    } else if (_filterBy == 'Estatus') {
      filteredOrderList = filteredOrderList.where((OrderModel order) {
        return order.status.toLowerCase() == _filterText.toLowerCase();
      }).toList();
    } else if (_filterText.isNotEmpty) {
      filteredOrderList = filteredOrderList.where((OrderModel order) {
        switch (_filterBy) {
          case 'Nombre':
            return order.clientName
                .toLowerCase()
                .contains(_filterText.toLowerCase());
          case 'Número de orden':
            return order.orderId
                .toLowerCase()
                .contains(_filterText.toLowerCase());
          case 'Producto':
            return order.productList?.any((product) => product.name
                    .toLowerCase()
                    .contains(_filterText.toLowerCase())) ??
                false;
          default:
            return false;
        }
      }).toList();
    }

    print("Filtered orders count: ${filteredOrderList.length}");
    return filteredOrderList;
  }

  DateTime _parseDate(String date) {
    try {
      // Intentar con el formato "yyyy-MM-dd HH:mm:ss.SSSSSS"
      return DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS").parse(date);
    } catch (e) {
      try {
        // Intentar con el formato "MM/dd/yyyy"
        return DateFormat("MM/dd/yyyy").parse(date);
      } catch (e) {
        print('Error al analizar la fecha: $e');
        return DateTime
            .now(); // Devolver la fecha actual si ambas conversiones fallan
      }
    }
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OrderProvider(),
      child: const HistoryScreenContent(),
    );
  }
}

class HistoryScreenContent extends StatefulWidget {
  const HistoryScreenContent({super.key});

  @override
  State<HistoryScreenContent> createState() => _HistoryScreenContentState();
}

class _HistoryScreenContentState extends State<HistoryScreenContent> {
  late final DataBase dataBase;
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    dataBase = Provider.of<DataBase>(context, listen: false);
    loadOrders();
  }

  Future<void> loadOrders() async {
    List<OrderModel> orders = await dataBase.getAllOrdersWithProducts();
    Provider.of<OrderProvider>(context, listen: false).setOrders(orders);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null &&
        picked !=
            Provider.of<OrderProvider>(context, listen: false).selectedDate) {
      Provider.of<OrderProvider>(context, listen: false)
          .setSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Órdenes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xffA338FF),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.table_chart,
              color: Colors.white,
            ),
            onPressed: () async {
              List<OrderModel> orders = context.read<OrderProvider>().orders;
              await dataBase.exportToExcel(context, orders);
            },
            tooltip: 'Exportar como Excel',
          ),
        ],
      ),
      backgroundColor: const Color(0xffF9F4FF),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 10),
              child: Text(
                'Historial',
                style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: Provider.of<OrderProvider>(context).filterBy,
                    icon: const Icon(Icons.arrow_downward),
                    onChanged: (String? newValue) {
                      Provider.of<OrderProvider>(context, listen: false)
                          .setFilterBy(newValue!);
                    },
                    items: <String>[
                      'Nombre',
                      'Fecha',
                      'Número de orden',
                      'Producto',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                if (Provider.of<OrderProvider>(context).filterBy == 'Fecha')
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        Provider.of<OrderProvider>(context).selectedDate == null
                            ? 'Seleccionar fecha'
                            : DateFormat('MM/dd/yyyy').format(
                                Provider.of<OrderProvider>(context)
                                    .selectedDate!),
                      ),
                    ),
                  )
                else if (Provider.of<OrderProvider>(context).filterBy ==
                    'Estatus')
                  Expanded(
                    child: DropdownButton<String>(
                      value: Provider.of<OrderProvider>(context)
                              .filterText
                              .isEmpty
                          ? 'pendiente'
                          : Provider.of<OrderProvider>(context)
                              .filterText, // Valor por defecto si está vacío
                      icon: const Icon(Icons.arrow_downward),
                      onChanged: (String? newValue) {
                        Provider.of<OrderProvider>(context, listen: false)
                            .setSelectedStatus(newValue!);
                      },
                      items: <String>[
                        'pendiente',
                        'pago',
                        'cerrado',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  )
                else
                  Expanded(
                    child: TextFormField(
                      onChanged: (String value) {
                        Provider.of<OrderProvider>(context, listen: false)
                            .setFilterText(value);
                      },
                      controller: controller,
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.search),
                        icon: Icon(Icons.filter_list),
                        border: InputBorder.none,
                        hintText: 'Buscar...',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return FilterBar(
                  selectedStatus: orderProvider.selectedStatus,
                  onStatusSelected: (status) {
                    orderProvider.setSelectedStatus(status);
                  },
                );
              },
            ),
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (context, orderProvider, child) {
                  if (orderProvider.orders.isNotEmpty) {
                    List<OrderModel> filteredOrderList =
                        orderProvider.filteredOrders;

                    return ListView.builder(
                      itemCount: filteredOrderList.length,
                      itemBuilder: (context, index) {
                        OrderModel order = filteredOrderList[index];
                        final List<ProductModel> products =
                            order.productList ?? [];
                        return InvoiceWidget(
                          dataBase: dataBase,
                          order: order,
                          products: products,
                        );
                      },
                    );
                  } else if (orderProvider.orders.isEmpty) {
                    return const Center(
                        child: Text('No se encontraron órdenes.'));
                  }

                  return const CircularProgressIndicator();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onStatusSelected;

  const FilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FilterButton(
            text: 'Historial',
            isSelected: selectedStatus == 'historial',
            onPressed: () => onStatusSelected('historial'),
          ),
          _FilterButton(
            text: 'Pendiente',
            isSelected: selectedStatus == 'pendiente',
            onPressed: () => onStatusSelected('pendiente'),
          ),
          _FilterButton(
            text: 'Cerrado',
            isSelected: selectedStatus == 'cerrado',
            onPressed: () => onStatusSelected('cerrado'),
          ),
          _FilterButton(
            text: 'Transacciones',
            isSelected: selectedStatus == 'Transacciones',
            onPressed: () => onStatusSelected('Transacciones'),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;

  const _FilterButton({
    required this.text,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class InvoiceWidget extends StatefulWidget {
  final DataBase dataBase;
  final OrderModel order;
  final List<ProductModel> products;

  const InvoiceWidget({
    super.key,
    required this.order,
    required this.products,
    required this.dataBase,
  });

  @override
  State<InvoiceWidget> createState() => _InvoiceWidgetState();
}

class _InvoiceWidgetState extends State<InvoiceWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.order.status == "pendiente"
          ? () {
              Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateOrderScreen(
                    order: widget.order,
                    isEditPage: true,
                  ),
                ),
              ).then((value) async {
                // Reload orders when returning from edit page
                List<OrderModel> updatedOrders =
                    await widget.dataBase.getAllOrdersWithProducts();
                context.read<OrderProvider>().setOrders(updatedOrders);
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            HeaderSection(order: widget.order),
            widget.order.status == "Compra" &&
                    widget.order.productList?.isEmpty == true
                ? Container()
                : widget.order.status == "Pago" ||
                        widget.order.status == "Costo de orden" ||
                        widget.order.status == "Produccion" ||
                        widget.order.status == "Gasto"
                    ? Container()
                    : ItemListSection(
                        products: widget.products,
                        order: widget.order,
                      ),
            TotalSection(
              order: widget.order,
              products: widget.products,
              dataBase: widget.dataBase,
            ),
            if (widget.order.pagos.isNotEmpty)
              PaymentSection(pagos: widget.order.pagos),
            if (widget.order.status == "pendiente")
              TextButton(
                onPressed: () async {
                  await _showCloseOrderConfirmation();
                },
                child: const Text(
                  'Cerrar orden',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCloseOrderConfirmation() async {
    // Show a confirmation dialog before closing the order
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: const Text('¿Estás seguro que deseas cerrar esta orden?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels the action
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms the action
              },
              child: const Text('Cerrar Orden'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _closeOrder(); // Close the order if confirmed
    }
  }

  Future<void> _closeOrder() async {
    // Update the order status to "cerrado"
    OrderModel updatedOrder = widget.order.copyWith(status: 'cerrado');

    // Update the order in the database
    await widget.dataBase.updateOrderFieldss(widget.order.id!, updatedOrder);

    // Reload the orders after updating
    List<OrderModel> updatedOrders =
        await widget.dataBase.getAllOrdersWithProducts();
    context.read<OrderProvider>().setOrders(updatedOrders);
  }
}

class HeaderSection extends StatelessWidget {
  final OrderModel order;

  const HeaderSection({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    if (order.status == "Pago bigticket") {
      order.status = "Pago";
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(10), topLeft: Radius.circular(10)),
        color: Color(0xffA338FF),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderId.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                Container(
                  height: 25,
                  width: 200,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: order.status == "Pago" ||
                              order.status == "Pago bigticket"
                          ? Colors.green[400]
                          : order.status == 'Compra' ||
                                  order.status == "Costo de orden"
                              ? Colors.red[400]
                              : Colors.amber),
                  child: Center(
                    child: Text(order.status,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 3,
            child: Text(order.clientName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Flexible(
            flex: 2,
            child: Text(
              DateFormat('dd MMMM yyyy').format(_parseDate(order.date)),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseDate(String date) {
    try {
      // Intentar con el formato "yyyy-MM-dd HH:mm:ss.SSSSSS"
      return DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS").parse(date);
    } catch (e) {
      try {
        // Intentar con el formato "MM/dd/yyyy"
        return DateFormat("MM/dd/yyyy").parse(date);
      } catch (e) {
        print('Error al analizar la fecha: $e');
        return DateTime
            .now(); // Devolver una fecha por defecto si ambas conversiones fallan
      }
    }
  }
}

class ItemListSection extends StatelessWidget {
  final List<ProductModel> products;
  final OrderModel order;
  const ItemListSection(
      {super.key, required this.products, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffA338FF), width: 0.4),
      ),
      child: Column(
        children: [
          TotalRow(label: 'Total Adeudado', amount: order.totalOwned),
          for (var product in products)
            if (product.quantity!.value > 0)
              ItemRow(
                product: product,
                image: product.file!,
                title: product.name,
                quantity: product.quantity!.value.toInt(),
                cost: product.cost.toInt(),
                unit: product.unit,
              ),
          if (order.adminExpenses != null && order.adminExpenses!.isNotEmpty)
            const Text(
              "Costos adicionales",
              style: TextStyle(color: Color.fromARGB(255, 111, 111, 111)),
            ),
          if (order.adminExpenses != null && order.adminExpenses!.isNotEmpty)
            for (var product in order.adminExpenses!)
              ItemRow(
                product: product,
                image: product.file!,
                title: product.name,
                quantity: product.quantity!.value.toInt(),
                cost: product.cost.toInt(),
                unit: product.unit,
              ),
        ],
      ),
    );
  }
}

class ItemRow extends StatefulWidget {
  final ProductModel product;
  final String image;
  final String title;
  final int quantity;
  final int cost;
  final String unit;

  const ItemRow({
    super.key,
    required this.product,
    required this.title,
    required this.image,
    required this.quantity,
    required this.cost,
    required this.unit,
  });
  @override
  State<ItemRow> createState() => _ItemRowState();
}

var isSubProduct = false;

class _ItemRowState extends State<ItemRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8.0),
              Text('${widget.quantity}  '),
              const Text('x '),
              CircleAvatar(
                radius:
                    12, // Ajusta el radio para que el círculo sea más grande
                backgroundColor: Colors.orangeAccent[300],
                child: Container(
                  width: 9, // Ajusta el ancho del contenedor
                  height: 9, // Ajusta la altura del contenedor
                  decoration: BoxDecoration(
                    shape: BoxShape
                        .circle, // Asegúrate de que el contenedor tenga forma circular
                    image: DecorationImage(
                      fit: BoxFit
                          .cover, // Asegúrate de que la imagen cubra todo el contenedor
                      image: FileImage(File(widget.image)),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                  onTap: () {
                    isSubProduct = !isSubProduct;
                    setState(() {});
                  },
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width *
                        0.65, // constraints the width to the maximum available
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${widget.unit} ${widget.title}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.product.subProduct!.isNotEmpty)
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                      ],
                    ),
                  )),
            ],
          ),
          if (isSubProduct == true)
            if (widget.product.subProduct != null &&
                widget.product.subProduct!.isNotEmpty)
              ...widget.product.subProduct!.map((subproduct) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 70),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${subproduct.quantity!.value} x ${subproduct.name}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      Text(
                        '  \$${subproduct.cost}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );
  }
}

class TotalSection extends StatelessWidget {
  final DataBase dataBase;
  final List<ProductModel> products;
  final OrderModel order;

  const TotalSection(
      {super.key,
      required this.order,
      required this.products,
      required this.dataBase});

  @override
  Widget build(BuildContext context) {
    // If the status is "cobro" or "venta," skip the margin and admin cost calculations
    if (order.status == "Pago" ||
        order.status == "Compra" ||
        order.status == "Pago bigticket" ||
        order.status == "Costo de orden" ||
        order.status == "Produccion" ||
        order.status == "Gasto") {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffA338FF), width: 0.4),
        ),
        child: Column(
          children: [
            TotalRow(
              label: 'Monto de transaccion',
              amount: '\$${order.totalCost}',
            ),
          ],
        ),
      );
    }

    // Regular calculation for other statuses
    double adminCost = order.adminExpenses!.fold(
        0,
        (double sum, ProductModel product) =>
            sum + product.cost.toInt() * product.quantity!.value);
    double adminPrice = order.adminExpenses!.fold(
        0,
        (double sum, ProductModel product) =>
            sum + product.unitPrice.toInt() * product.quantity!.value);

    double newMargen = double.parse(order.margen) + adminCost;
    if (order.margen == "0.0") {
      newMargen = order.productList!.fold(
          0,
          (previousValue, element) =>
              previousValue + (element.unitPrice - element.cost) + adminCost);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffA338FF), width: 0.4),
      ),
      child: Column(
        children: [
          TotalRow(label: 'Costo total', amount: '\$${(order.totalCostSpent)}'),
          TotalRow(
              label: 'Precio total',
              amount: '\$${order.totalCost + adminPrice}'),
          TotalRow(label: 'Margen', amount: '\$$newMargen'),
          TotalRow(label: 'Costos administrativos', amount: '\$$adminCost'),
        ],
      ),
    );
  }
}

class TotalRow extends StatelessWidget {
  final String label;
  final String amount;

  const TotalRow({
    super.key,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(amount),
        ],
      ),
    );
  }
}

class PaymentSection extends StatelessWidget {
  final List<PagoModel> pagos;

  const PaymentSection({super.key, required this.pagos});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < pagos.length; i++)
          PaymentRow(
            label: 'Pago ${i + 1}',
            date: _formatDate(pagos[i].date),
            amount: '\$${pagos[i].amount.toStringAsFixed(2)}',
          ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      // Establecer la localización a español
      Intl.defaultLocale = 'es_ES';
      // Analizar la fecha con el formato especificado
      DateTime parsedDate = _parseDate(date);
      // Formatear la fecha como "dd MMMM yyyy" en español
      return DateFormat('dd MMMM yyyy', 'es_ES').format(parsedDate);
    } catch (e) {
      // Manejar el error devolviendo un mensaje por defecto o de error
      return 'Fecha inválida';
    }
  }

  DateTime _parseDate(String date) {
    try {
      // Intentar con el formato "yyyy-MM-dd HH:mm:ss.SSSSSS"
      return DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS").parse(date);
    } catch (e) {
      try {
        // Intentar con el formato "MM/dd/yyyy"
        return DateFormat("MM/dd/yyyy").parse(date);
      } catch (e) {
        print('Error al analizar la fecha: $e');
        return DateTime
            .now(); // Devolver una fecha por defecto si ambas conversiones fallan
      }
    }
  }
}

class PaymentRow extends StatelessWidget {
  final String label;
  final String date;
  final String amount;

  const PaymentRow({
    super.key,
    required this.label,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffA338FF), width: 0.4),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date),
              Text(amount),
            ],
          ),
        ],
      ),
    );
  }
}
