import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  late final DataBase dataBase;
  final TextEditingController controller = TextEditingController();
  late Future<List<OrderModel>> _futureOrders;

  @override
  void initState() {
    super.initState();
    dataBase = Provider.of<DataBase>(context, listen: false);
    _futureOrders = dataBase.getAllOrdersWithProducts();
  }

  void _refreshOrders() {
    setState(() {
      _futureOrders = dataBase.getAllOrdersWithProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes Pendientes'),
        backgroundColor: const Color(0xffA338FF),
      ),
      backgroundColor: const Color(0xffF9F4FF),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Ordenes Pendientes',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: _buildOrderList()),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return FutureBuilder<List<OrderModel>>(
      future: _futureOrders,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final List<OrderModel> orderList = snapshot.data!
                .where((order) => order.status == "pendiente")
                .toList();

            return ListView.builder(
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                OrderModel order = orderList[index];
                final List<ProductModel> products = order.productList ?? [];

                return PendingOrderWidget(
                  order: order,
                  products: products,
                  onRefresh: _refreshOrders,
                );
              },
            );
          } else {
            return const Center(child: Text('No se encontraron órdenes.'));
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class PendingOrderWidget extends StatelessWidget {
  final OrderModel order;
  final List<ProductModel> products;
  final VoidCallback onRefresh;

  const PendingOrderWidget({
    super.key,
    required this.order,
    required this.products,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Add navigation or actions here if needed
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
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
            HeaderSection(order: order),
            ItemListSection(
              products: products,
              order: order,
            ),
            TotalSectionPending(
              order: order,
              products: products,
              onRefresh: onRefresh,
            ),
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
          topRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        ),
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
                Text(
                  '#${order.orderId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Container(
                  height: 25,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.amber,
                  ),
                  child: Center(
                    child: Text(
                      order.status,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 3,
            child: Text(
              order.clientName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
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
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now(); // Fallback to current date if parsing fails
    }
  }
}

class ItemListSection extends StatelessWidget {
  final List<ProductModel> products;
  final OrderModel order;

  const ItemListSection({
    super.key,
    required this.products,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffA338FF), width: 0.4),
      ),
      child: Column(
        children: [
          for (var product in products)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
              child: Row(
                children: [
                  Text('${product.quantity!.value} x '),
                  Text(product.name),
                  const Spacer(),
                  Text('\$${product.unitPrice.toStringAsFixed(2)}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class TotalSectionPending extends StatelessWidget {
  final OrderModel order;
  final List<ProductModel> products;
  final VoidCallback onRefresh;

  const TotalSectionPending({
    super.key,
    required this.order,
    required this.products,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffA338FF), width: 0.4),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Adeudado'),
              Text('\$${order.totalCost.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirmación'),
                    content: const Text(
                        '¿Estás seguro que deseas facturar esta orden?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Facturar'),
                      ),
                    ],
                  );
                },
              );

              if (confirm) {
                final database = Provider.of<DataBase>(context, listen: false);
                await database.updateOrderStatus(order.id!, "cerrado");
                onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Orden facturada con éxito')),
                );
              }
            },
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text(
                  'Facturar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
