import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/history.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  late final DataBase dataBase;
  final TextEditingController controller = TextEditingController();
  String selectedStatus = 'historial'; // Default selected status
  late Future<List<OrderModel>> _futureOrders;

  @override
  void initState() {
    dataBase = Provider.of<DataBase>(context, listen: false);
    _futureOrders = dataBase.getAllOrdersWithProducts();
    super.initState();
  }

  void _refreshOrders() {
    setState(() {
      _futureOrders = dataBase.getAllOrdersWithProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(),
      backgroundColor: const Color(0xffF9F4FF),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ordenes Pendientes',
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(child: _buildOrderList()),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return FutureBuilder(
      future: _futureOrders,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasData && snap.data != null) {
            final List<OrderModel> orderList = snap.data as List<OrderModel>;

            // Filter products based on selectedStatus
            List<OrderModel> filteredOrderList = orderList.where((order) {
              OrderModel currentOrder = order;
              return currentOrder.status == selectedStatus;
            }).toList();
            if (selectedStatus == "historial") {
              filteredOrderList = snap.data as List<OrderModel>;
            }

            if (controller.text.isNotEmpty) {
              filteredOrderList = orderList.where((order) {
                OrderModel currentOrder = order;
                return currentOrder.clientName
                    .toLowerCase()
                    .contains(controller.text.toLowerCase());
              }).toList();
            }

            filteredOrderList = orderList
                .where((order) => order.status == "pendiente")
                .toList();

            return ListView.builder(
              itemCount: filteredOrderList.length,
              itemBuilder: (context, index) {
                OrderModel order = filteredOrderList[index];
                final List<ProductModel> products =
                    filteredOrderList[index].productList!;

                return InvoiceWidgetInvoice(
                    order: order,
                    products: products,
                    onRefresh: _refreshOrders);
              },
            );
          } else {
            return const Text('No data available');
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class InvoiceWidgetInvoice extends StatelessWidget {
  final OrderModel order;
  final List<ProductModel> products;
  final VoidCallback onRefresh;

  const InvoiceWidgetInvoice(
      {super.key,
      required this.order,
      required this.products,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(30),
      // height: MediaQuery.of(context).size.height * 0.413,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          HeaderSection(order: order),
          ItemListSection(products: products),
          TotalSectionPendding(
              order: order, products: products, onRefresh: onRefresh),
          // const PaymentSection(),
        ],
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
      // height: 50,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(10), topLeft: Radius.circular(10)),
        color: Color(0xffA338FF),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderNumber!,
                  style: const TextStyle(
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
              )
            ],
          ),
          Text(order.clientName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          Text(
            order.date,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class TotalSectionPendding extends StatefulWidget {
  final List<ProductModel> products;
  final OrderModel order;
  final VoidCallback onRefresh;

  const TotalSectionPendding(
      {super.key,
      required this.order,
      required this.products,
      required this.onRefresh});

  @override
  State<TotalSectionPendding> createState() => _TotalSectionPenddingState();
}

class _TotalSectionPenddingState extends State<TotalSectionPendding> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffA338FF), width: 0.4),
      ),
      child: Column(
        children: [
          TotalRow(
              label: 'Total Adeudado', amount: '\$${widget.order.totalCost}'),
          Center(
            child: GestureDetector(
              onTap: () async {
                final database = Provider.of<DataBase>(context, listen: false);
                await database.updateOrderWithProducts(
                    widget.order.id!, widget.order, widget.products);
                widget.onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Orden facturada con exito')),
                );
              },
              child: Container(
                height: 30,
                width: 100,
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15)),
                child: const Center(
                    child: Text(
                  "Facturar",
                  style: TextStyle(color: Colors.white),
                )),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          )
          // const TotalRow(label: 'Margen', amount: '\$200'),
          // const TotalRow(label: 'Costos administrativos', amount: '\$200'),
        ],
      ),
    );
  }
}
