import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/create_order.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final DataBase dataBase;
  final TextEditingController controller = TextEditingController();
  String selectedStatus = 'historial';

  @override
  void initState() {
    super.initState();
    dataBase = Provider.of<DataBase>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Órdenes'),
        backgroundColor: const Color(0xffA338FF),
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: const Color(0xffEAD2FF),
              ),
              child: TextFormField(
                onChanged: (String value) {
                  setState(() {});
                },
                controller: controller,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.settings),
                  icon: Icon(Icons.person),
                  border: InputBorder.none,
                  hintText: 'Nombre',
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilterBar(
              selectedStatus: selectedStatus,
              onStatusSelected: (status) {
                setState(() {
                  selectedStatus = status;
                });
              },
            ),
            Expanded(
              child: FutureBuilder<List<OrderModel>>(
                future: dataBase.getAllOrdersWithProducts(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.done) {
                    if (snap.hasData && snap.data != null) {
                      List<OrderModel> orders = snap.data!;
                      List<OrderModel> filteredOrderList =
                          orders.where((OrderModel order) {
                        return order.status == selectedStatus;
                      }).toList();

                      if (selectedStatus == "historial") {
                        filteredOrderList = orders;
                      }

                      if (controller.text.isNotEmpty) {
                        filteredOrderList = orders.where((OrderModel order) {
                          return order.clientName
                              .toLowerCase()
                              .contains(controller.text.toLowerCase());
                        }).toList();
                      }

                      return ListView.builder(
                        itemCount: filteredOrderList.length,
                        itemBuilder: (context, index) {
                          OrderModel order = filteredOrderList[index];
                          final List<ProductModel> products =
                              order.productList ?? [];
                          return InvoiceWidget(
                              order: order,
                              products: products,
                              onOrderUpdated: _refreshOrders);
                        },
                      );
                    } else {
                      return const Center(child: Text('No data available'));
                    }
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshOrders() {
    setState(() {});
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
            text: 'Pago',
            isSelected: selectedStatus == 'Pago',
            onPressed: () => onStatusSelected('Pago'),
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
            text: 'Compra',
            isSelected: selectedStatus == 'Compra',
            onPressed: () => onStatusSelected('Compra'),
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
  final OrderModel order;
  final List<ProductModel> products;
  final VoidCallback onOrderUpdated;

  const InvoiceWidget(
      {super.key,
      required this.order,
      required this.products,
      required this.onOrderUpdated});

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
                  )).then((value) {
                if (value != null && value) {
                  widget.onOrderUpdated();
                }
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
            ItemListSection(products: widget.products),
            TotalSection(order: widget.order, products: widget.products),
            if (widget.order.pagos.isNotEmpty)
              PaymentSection(pagos: widget.order.pagos),
          ],
        ),
      ),
    );
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
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('#A83940',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                Container(
                  height: 25,
                  width: 80,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.amber),
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
              order.status == "Compra" || order.status == "Pago"
                  ? DateFormat('dd MMMM yyyy')
                      .format(DateTime.parse(order.date))
                  : order.date,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemListSection extends StatelessWidget {
  final List<ProductModel> products;

  const ItemListSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffA338FF), width: 0.4),
      ),
      child: Column(
        children: [
          for (var product in products)
            ItemRow(
              title: product.name,
              quantity: product.quantity!.value,
              cost: product.cost,
              unit: product.unit,
            ),
        ],
      ),
    );
  }
}

class ItemRow extends StatelessWidget {
  final String title;
  final int quantity;
  final double cost;
  final String unit;

  const ItemRow({
    super.key,
    required this.title,
    required this.quantity,
    required this.cost,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: Row(
        children: [
          const SizedBox(width: 8.0),
          Text('$quantity  '),
          Flexible(child: Text("$title $unit")),
        ],
      ),
    );
  }
}

class TotalSection extends StatelessWidget {
  final List<ProductModel> products;
  final OrderModel order;

  const TotalSection({super.key, required this.order, required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffA338FF), width: 0.4),
      ),
      child: Column(
        children: [
          TotalRow(label: 'Costo total', amount: '\$${order.totalCost}'),
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
      return DateFormat('dd MMMM yyyy').format(DateTime.parse(date));
    } catch (e) {
      // Handle the error by returning a default or error message
      return 'Invalid date';
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
