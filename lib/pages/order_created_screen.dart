import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/date_range.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class OrderCreatedScreen extends StatefulWidget {
  final List<DateRange> markedDays;
  final OrderModel orderModel;
  final List<ProductModel> productModelList;

  const OrderCreatedScreen(
      {super.key,
      required this.orderModel,
      required this.productModelList,
      required this.markedDays});

  @override
  State<OrderCreatedScreen> createState() => _OrderCreatedScreenState();
}

class _OrderCreatedScreenState extends State<OrderCreatedScreen> {
  late DataBase dataBaseProvider;

  @override
  void initState() {
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int totalquantity = widget.productModelList.fold(
      0,
      (int sum, ProductModel product) {
        if (product.datesUsed != null && product.datesUsed!.isNotEmpty) {
          int totalDays =
              widget.markedDays.fold(0, (int total, DateRange range) {
            return total + (range.end!.difference(range.start!).inDays + 1);
          });
          return sum + (totalDays * product.unitPrice.toInt());
        } else {
          return sum + (product.unitPrice.toInt() * product.quantity!.value);
        }
      },
    );

    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Recibo de Pedido'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Order Header
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildHeaderDetail(
                          'ID del Pedido:',
                          widget.orderModel.id?.toString() ?? "No disponible",
                          Icons.confirmation_num),
                      _buildHeaderDetail('Cliente:',
                          widget.orderModel.clientName, Icons.person),
                      _buildHeaderDetail('Contacto:',
                          widget.orderModel.celNumber, Icons.phone),
                      _buildHeaderDetail('Dirección:',
                          widget.orderModel.direccion, Icons.location_on),
                      _buildHeaderDetail(
                          'Fecha:', _formatDatesUsed(), Icons.date_range),
                      _buildHeaderDetail(
                          'Total Adeudado:',
                          widget.orderModel.totalOwned.toString(),
                          Icons.date_range),
                      _buildHeaderDetail(
                          'Precio Total:',
                          '\$${totalquantity.toStringAsFixed(2)}',
                          Icons.attach_money,
                          isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Productos:', style: theme.textTheme.titleLarge),
              ...widget.productModelList.map((product) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading:
                          Icon(Icons.shopping_cart, color: theme.primaryColor),
                      title: Text(product.name),
                      subtitle: Text(
                          'Cantidad: ${product.quantity!.value} x \$${product.unitPrice.toStringAsFixed(2)} (cada uno)'),
                      trailing: Text(
                        '\$${(product.quantity!.value * product.unitPrice).toStringAsFixed(2)}',
                      ),
                    ),
                  )),
              if (widget.orderModel.comment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _buildDetail(
                      'Comentarios:', widget.orderModel.comment, Icons.comment),
                ),
              ElevatedButton.icon(
                onPressed: () => generateAndSavePdf(
                    widget.orderModel, widget.productModelList),
                icon: const Icon(Icons.save_alt),
                label: const Text('Exportar a PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 108, 40, 123),
                    textStyle: const TextStyle(fontSize: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await dataBaseProvider.createOrderWithProducts(
                        widget.orderModel, widget.productModelList);

                    await dataBaseProvider
                        .reduceProductStock(widget.productModelList);

                    dataBaseProvider.selectedProductsNotifier.value = [];
                    Navigator.push(
                        context, MaterialPageRoute(builder: (_) => HomePage()));

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Orden creada con exito')),
                    );
                  },
                  child: const Text(
                    "Confirmar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatDatesUsed() {
    final datesUsed = widget.productModelList
        .expand((product) => product.datesUsed ?? [])
        .toList();

    if (datesUsed.isEmpty) {
      return widget.orderModel.date;
    }

    final formattedDates = datesUsed.map((dateRange) {
      final start = dateRange.start != null
          ? DateFormat('MM/dd/yyyy').format(dateRange.start!)
          : 'N/A';
      final end = dateRange.end != null
          ? DateFormat('MM/dd/yyyy').format(dateRange.end!)
          : 'N/A';
      return '$start - $end';
    }).join(', ');

    return formattedDates;
  }

  Future<void> generateAndSavePdf(
      OrderModel order, List<ProductModel> products) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Column(
        children: [
          pw.Text('Recibo de Pedido', style: const pw.TextStyle(fontSize: 24)),
          pw.Divider(),
          pw.Text('Cliente: ${order.clientName}'),
          pw.Text('Contacto: ${order.celNumber}'),
          pw.Text('Dirección: ${order.direccion}'),
          pw.Text('Fecha: ${_formatDatesUsed()}'),
          pw.Text('Costo Total: \$${order.totalCost.toStringAsFixed(2)}'),
          pw.Divider(),
          pw.ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(product.name),
                  pw.Text(
                      '${product.amount} x \$${product.unitPrice.toStringAsFixed(2)}'),
                  pw.Text(
                      '\$${(product.amount * product.unitPrice).toStringAsFixed(2)}'),
                ],
              );
            },
          ),
          if (order.comment.isNotEmpty)
            pw.Text('Comentarios: ${order.comment}'),
        ],
      );
    }));

    // Save the document
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'recibo_pedido_${order.id}.pdf');
  }

  Widget _buildHeaderDetail(String label, String value, IconData icon,
      {bool isTotal = false}) {
    return ListTile(
      leading: Icon(icon, size: 30),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
    );
  }

  Widget _buildDetail(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
