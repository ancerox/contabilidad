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
  final String totalOwned;
  final int orderNumber;
  final double totalPrice;
  final List<DateRange> markedDays;
  final OrderModel orderModel;
  final List<ProductModel> productModelList;

  const OrderCreatedScreen(
      {super.key,
      required this.totalOwned,
      required this.totalPrice,
      required this.orderNumber,
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
    // double totalPrice = 0.0;

    // for (var product in widget.productModelList) {
    //   if (widget.markedDays.isNotEmpty) {
    //     int totalDays = widget.markedDays.fold(0, (int sum, DateRange range) {
    //       return sum + (range.end!.difference(range.start!).inDays + 1);
    //     });
    //     totalPrice += totalDays * product.unitPrice;
    //   } else {
    //     totalPrice += product.unitPrice * product.quantity!.value;
    //   }
    // }

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
                          widget.orderNumber.toString() ?? "No disponible",
                          Icons.confirmation_num),
                      _buildHeaderDetail('Cliente:',
                          widget.orderModel.clientName, Icons.person),
                      _buildHeaderDetail('Contacto:',
                          widget.orderModel.celNumber, Icons.phone),
                      _buildHeaderDetail('Dirección:',
                          widget.orderModel.direccion, Icons.location_on),
                      _buildHeaderDetail(
                          'Fecha:', _formatDatesUsed(), Icons.date_range),
                      _buildHeaderDetail('Total Adeudado:', widget.totalOwned,
                          Icons.date_range),
                      _buildHeaderDetail(
                          'Precio Total:',
                          '\$${widget.totalPrice.toStringAsFixed(2)}',
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
                      title: Text(
                          "${product.quantity!.value} ${product.unit.toLowerCase()} x ${product.name}"),
                      subtitle: product.datesUsed != null &&
                              product.datesUsed!.isNotEmpty
                          ? Text(_buildRentalProductSubtitle(product))
                          : Text(
                              'Cantidad: ${product.quantity!.value} x \$${product.unitPrice.toStringAsFixed(2)} (cada uno)'),
                      trailing: Text(
                        product.datesUsed != null &&
                                product.datesUsed!.isNotEmpty
                            ? '\$${_calculateTotalRentalPrice(product).toStringAsFixed(2)}'
                            : '\$${(product.quantity!.value * product.unitPrice).toStringAsFixed(2)}',
                      ),
                    ),
                  )),
              const SizedBox(
                height: 10,
              ),
              if (dataBaseProvider.selectedCommodities.value.isNotEmpty)
                Text('Costos adicionales:', style: theme.textTheme.titleLarge),
              if (dataBaseProvider.selectedCommodities.value.isNotEmpty)
                ...dataBaseProvider.selectedCommodities.value
                    .map((product) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.shopping_cart,
                                color: theme.primaryColor),
                            title: Text(
                                "${product.quantity!.value} ${product.unit.toLowerCase()} x ${product.name}"),
                            subtitle: product.datesUsed != null &&
                                    product.datesUsed!.isNotEmpty
                                ? Text(_buildRentalProductSubtitle(product))
                                : Text(
                                    'Cantidad: ${product.quantity!.value} x \$${product.unitPrice.toStringAsFixed(2)} (cada uno)'),
                            trailing: Text(
                              product.datesUsed != null &&
                                      product.datesUsed!.isNotEmpty
                                  ? '\$${_calculateTotalRentalPrice(product).toStringAsFixed(2)}'
                                  : '\$${(product.quantity!.value * product.unitPrice).toStringAsFixed(2)}',
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
                    if (widget.orderModel.productList!
                        .any((element) => element.datesUsed != null)) {
                      await dataBaseProvider.createOrderWithProducts(
                          widget.orderModel, widget.productModelList);
                      dataBaseProvider.selectedProductsNotifier.value = [];
                      dataBaseProvider.dateRangeMap.clear();
                      dataBaseProvider.selectedCommodities.value.clear();
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => HomePage()));
                      return;
                    }

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
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildRentalProductSubtitle(ProductModel product) {
    // Retrieve the last DateRange from product.datesUsed
    DateRange lastDateRange = product.datesUsed!.last;

    // Calculate total days in the last DateRange
    int totalDays =
        lastDateRange.end!.difference(lastDateRange.start!).inDays + 1;

    // Calculate the total rental cost based on total days and unit price

    // Build the subtitle string
    return 'Días: $totalDays x \$${product.unitPrice.toStringAsFixed(2)} (por día)';
  }

  double _calculateTotalRentalPrice(ProductModel product) {
    // Retrieve the last DateRange from product.datesUsed
    DateRange lastDateRange = product.datesUsed!.last;

    // Calculate total days in the last DateRange
    int totalDays =
        lastDateRange.end!.difference(lastDateRange.start!).inDays + 1;

    // Calculate the total rental price based on total days and unit price
    return totalDays * product.unitPrice * product.quantity!.value;
  }

  String _formatDatesUsed() {
    final datesUsed = widget.productModelList
        .expand((product) => product.datesUsed ?? [])
        .toList();

    if (datesUsed.isEmpty) {
      return widget.orderModel.date;
    }

    // Ensure only the last two DateRanges are considered
    final lastTwoDates = datesUsed.length >= 2
        ? datesUsed.sublist(datesUsed.length - 2)
        : datesUsed;

    final formattedDates = lastTwoDates.map((dateRange) {
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

  Future<void> generateAndSavePdf(
      OrderModel order, List<ProductModel> products) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Receipt Header
              pw.Text('Recibo de Pedido',
                  style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 8),
              pw.Text('Gracias por tu pedido, ${order.clientName}'),
              pw.SizedBox(height: 8),
              pw.Text('Este es el recibo de tu pedido.'),
              pw.Divider(),

              // Order Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Número de Pedido'),
                  pw.Text('${order.orderNumber}'),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Fecha'),
                  pw.Text(order.date),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cliente'),
                  pw.Text(order.clientName),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Teléfono'),
                  pw.Text(order.celNumber),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Dirección'),
                  pw.Text(order.direccion),
                ],
              ),
              pw.Divider(),

              // Product List
              pw.ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          '${product.quantity!.value} ${product.unit} x ${product.name}'),
                      pw.Text("\$${product.unitPrice.toStringAsFixed(2)}"),
                    ],
                  );
                },
              ),
              pw.Divider(),

              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total a Pagar'),
                  pw.Text('\$${order.totalOwned} DOP'),
                ],
              ),

              pw.Divider(),

              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Estado'),
                  pw.Text(order.status),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Comentario'),
                  pw.Text(order.comment),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save and share the document
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'recibo_pedido_${order.id}.pdf');
  }
}
