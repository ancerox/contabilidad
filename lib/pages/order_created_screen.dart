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
  final String selectedOption;
  final bool isEditPage;
  final String totalOwned;
  final int orderNumber;
  final String orderId;
  final double totalPrice;
  final List<DateRange> markedDays;
  final OrderModel orderModel;
  final List<ProductModel> productModelList;

  const OrderCreatedScreen({
    super.key,
    required this.selectedOption,
    required this.totalOwned,
    required this.isEditPage,
    required this.totalPrice,
    required this.orderNumber,
    required this.orderModel,
    required this.productModelList,
    required this.markedDays,
    required this.orderId,
  });

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
                          widget.orderModel.orderId ?? "No disponible",
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
              const SizedBox(height: 20),
              // Lista de pagos
              if (widget.orderModel.pagos.isNotEmpty)
                Text('Pagos:', style: theme.textTheme.titleLarge),
              if (widget.orderModel.pagos.isNotEmpty)
                ...widget.orderModel.pagos.map((pago) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.payment, color: theme.primaryColor),
                        title: Text(
                            "Pago de \$${pago.amount.toStringAsFixed(2)} el ${pago.date}"),
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
                    if (widget.orderModel.pagos.isNotEmpty) {
                      if (!widget.isEditPage) {
                        for (var pago in widget.orderModel.pagos) {
                          // Only create the pago if it doesn't exist in the current order's pagos
                          await dataBaseProvider.createOrderWithProducts(
                            OrderModel(
                              orderId:
                                  "Pago ${widget.orderModel.pagos.length} ${widget.orderModel.orderId}",
                              pagos: [], // Initialize as needed or append appropriate values
                              totalOwned: "",
                              margen: "test",
                              status: "Pago",
                              clientName: widget.orderModel.clientName,
                              celNumber: "",
                              direccion: "",
                              date: pago.date,
                              comment: "",
                              totalCost: pago.amount,
                            ),
                            widget.orderModel.productList!,
                          );
                        }
                      } else if (widget.isEditPage) {
                        final existingOrders =
                            await dataBaseProvider.getAllOrdersWithProducts();

                        final OrderModel matchingOrder =
                            existingOrders.firstWhere(
                                (order) => order.id == widget.orderModel.id);

                        // Get the order with the same id as current orderModel from the database

                        // If the order does not exist or pagos list is empty, proceed to add pagos

                        for (var pago in widget.orderModel.pagos) {
                          if (!matchingOrder.pagos.any(
                              (existingPago) => existingPago.id == pago.id)) {
                            // Only create the pago if it doesn't exist in the current order's pagos
                            await dataBaseProvider.createOrderWithProducts(
                              OrderModel(
                                orderId:
                                    "Pago ${widget.orderModel.pagos.length} ${widget.orderModel.orderId}",
                                pagos: [], // Initialize as needed or append appropriate values
                                totalOwned: "",
                                margen: "test",
                                status: "Pago",
                                clientName: widget.orderModel.clientName,
                                celNumber: "",
                                direccion: "",
                                date: pago.date,
                                comment: "",
                                totalCost: pago.amount,
                              ),
                              widget.orderModel.productList!,
                            );
                          }
                        }
                      }

                      {
                        print(
                            'Order with ID ${widget.orderModel.orderId} already exists with the same pagos.');
                      }
                    }

                    /// EDIT ORDERS AND STOCK
                    if (widget.isEditPage) {
                      List<OrderModel> existingOrders =
                          await dataBaseProvider.getAllOrdersWithProducts();
                      List<ProductModel> existingProducts =
                          await dataBaseProvider.obtenerProductos();

                      // Restore Stock
                      for (var element in widget.orderModel.productList!) {
                        if (element.datesUsed == null ||
                            element.datesUsed!.isEmpty) {
                          final ordercostOfOrder = existingProducts.firstWhere(
                              (eleProduct) => eleProduct.id == element.id!);
                          double diference = 0.0;
                          if (element.initialQuantity != null) {
                            diference = element.initialQuantity! -
                                element.quantity!.value;
                          }

                          print("${element.initialQuantity} teasdasd233");
                          print("${element.quantity!.value} teasdasd233");
                          dataBaseProvider.updateProductAmount(element.id!,
                              ordercostOfOrder.amount + (diference));
                          element.initialQuantity =
                              element.quantity!.value.toInt();
                          print("${ordercostOfOrder.amount} teasdasd233");
                          print("$diference teasdasd233");
                          // if (element.quantity!.value >
                          //     element.initialQuantity!) {

                          // }
                          // if (element.quantity!.value <
                          //     element.initialQuantity!) {
                          //   dataBaseProvider.updateProductAmount(
                          //       element.id!,
                          //       element.amount -
                          //           (element.quantity!.value) -
                          //           (element.initialQuantity!));
                          // }
                        }
                      }

                      final ordercostOfOrder = existingOrders.firstWhere(
                          (element) =>
                              element.status == "Costo de orden" &&
                              element.orderId == widget.orderModel.orderId);

                      // final orderPagoAmount = existingOrders
                      //     .firstWhere((element) => element.status == "Pago");

                      ordercostOfOrder.totalCost =
                          widget.orderModel.totalCostSpent!.toDouble();
                      await dataBaseProvider.updateOrderWithProducts(
                          ordercostOfOrder.id.toString(),
                          ordercostOfOrder,
                          ordercostOfOrder.productList!);

//                       orderPagoAmount.pagos = widget.orderModel.pagos;
//                       await dataBaseProvider.updateOrderWithProducts(
//                           orderPagoAmount.id.toString(),
//                           orderPagoAmount,
//                           orderPagoAmount.productList!);
// // element.status == "Pago" ||

                      //  final existingOrders =
                      //       await dataBaseProvider.getAllOrdersWithProducts();

                      //    OrderModel matchingOrder =
                      //       existingOrders.firstWhere(
                      //           (order) => order.orderId == widget.orderModel.orderId);

                      //           matchingOrder.totalCost = widget.orderModel.totalCost;

                      await dataBaseProvider.updateOrderWithProducts(
                          widget.orderModel.id.toString(),
                          widget.orderModel,
                          widget.productModelList);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Orden actualizada con éxito')),
                      );
                      dataBaseProvider.selectedProductsNotifier.value = [];
                      dataBaseProvider.dateRangeMap.clear();
                      dataBaseProvider.selectedCommodities.value.clear();
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HomePage()));
                      return;
                    }
                    final cobroOrder = OrderModel(
                      totalCostSpent: widget.orderModel.totalCostSpent,
                      orderId: widget.orderModel.orderId,
                      pagos: [],
                      totalOwned: "",
                      margen: "",
                      status: "Costo de orden",
                      clientName: widget.orderModel.clientName,
                      celNumber: "",
                      direccion: "",
                      date: DateFormat('MM/dd/yyyy')
                          .format(DateTime.now())
                          .toString(),
                      comment: "",
                      totalCost: widget.orderModel.totalCostSpent!.toDouble(),
                    );
                    await dataBaseProvider.createOrderWithProducts(
                        widget.orderModel, widget.productModelList);
                    await dataBaseProvider.createOrderWithProducts(
                        cobroOrder, widget.productModelList);

                    if (widget.selectedOption == "Venta") {
                      await dataBaseProvider
                          .reduceProductStock(widget.productModelList);
                    }

                    dataBaseProvider.selectedProductsNotifier.value = [];
                    dataBaseProvider.dateRangeMap.clear();
                    dataBaseProvider.selectedCommodities.value.clear();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HomePage()));

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Orden creada con éxito')),
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
    DateRange lastDateRange = product.datesUsed!.last;
    int totalDays =
        lastDateRange.end!.difference(lastDateRange.start!).inDays + 1;
    return 'Días: $totalDays x \$${product.unitPrice.toStringAsFixed(2)} (por día)';
  }

  double _calculateTotalRentalPrice(ProductModel product) {
    DateRange lastDateRange = product.datesUsed!.last;
    int totalDays =
        lastDateRange.end!.difference(lastDateRange.start!).inDays + 1;
    return totalDays * product.unitPrice * product.quantity!.value;
  }

  String _formatDatesUsed() {
    final datesUsed = widget.productModelList
        .expand((product) => product.datesUsed ?? [])
        .toList();

    if (datesUsed.isEmpty) {
      return widget.orderModel.date;
    }

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

    products =
        products.where((element) => element.quantity!.value > 0).toList();
    List<ProductModel> productsCommodities = dataBaseProvider
        .selectedCommodities.value
        .where((element) => element.quantity!.value > 0)
        .toList();

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
              pw.Text('.'),
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
                      pw.Text(
                          "\$${product.unitPrice * product.quantity!.value}"),
                    ],
                  );
                },
              ),

              if (dataBaseProvider.selectedCommodities.value.isNotEmpty)
                pw.Text('Costos adicionales:',

                    // pw.Divider(),
                    style: const pw.TextStyle(fontSize: 18)),
              pw.ListView.builder(
                itemCount: productsCommodities.length,
                itemBuilder: (context, index) {
                  final product =
                      dataBaseProvider.selectedCommodities.value[index];
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          '${product.quantity!.value} ${product.unit} x ${product.name}'),
                      pw.Text(
                          "\$${product.unitPrice * product.quantity!.value}"),
                    ],
                  );
                },
              ),

              pw.Divider(),

              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Precio total'),
                  pw.Text('\$${widget.totalPrice} DOP'),
                ],
              ),
              pw.Divider(),

              // Payment List
              if (order.pagos.isNotEmpty)
                pw.Text('Pagos:', style: const pw.TextStyle(fontSize: 18)),
              if (order.pagos.isNotEmpty)
                pw.ListView.builder(
                  itemCount: order.pagos.length,
                  itemBuilder: (context, index) {
                    final pago = order.pagos[index];
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Pago de \$${pago.amount.toStringAsFixed(2)}'),
                        pw.Text('Fecha: ${pago.date}'),
                      ],
                    );
                  },
                ),
              pw.Divider(),

              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total adeudado'),
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

              pw.SizedBox(height: 8),
              pw.Row(
                // mainAxisAlignment: pw
                //     .MainAxisAlignment.spaceBetween, // Distribute space evenly
                crossAxisAlignment:
                    pw.CrossAxisAlignment.center, // Align the items at the top
                children: [
                  pw.Text('Comentario: ',
                      maxLines: 1), // The label stays fixed in its space
                  pw.SizedBox(
                      width: 10), // Optional space between label and text
                  pw.Expanded(
                    child: pw.Text(
                      order.comment,
                      textAlign: pw.TextAlign.left, // Ensure text is justified
                      overflow: pw.TextOverflow.clip, // Clip the overflow
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
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
