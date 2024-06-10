import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReceiptPage extends StatefulWidget {
  final Map<ProductModel, int> selectedProducts;

  const ReceiptPage({super.key, required this.selectedProducts});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final TextEditingController conceptoController = TextEditingController();
  late DataBase dataBaseProvider;
  @override
  void initState() {
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double totalCost = widget.selectedProducts.entries.fold(
        0,
        (previousValue, entry) =>
            previousValue + (entry.key.cost * entry.value));

    // Group products by ID to sum quantities of duplicates
    final Map<int, ProductModel> productsById = {};
    final Map<int, int> quantitiesById = {};

    for (var entry in widget.selectedProducts.entries) {
      final product = entry.key;
      final quantity = entry.value;

      if (productsById.containsKey(product.id)) {
        quantitiesById[product.id!] =
            (quantitiesById[product.id] ?? 0) + quantity;
      } else {
        productsById[product.id!] = product;
        quantitiesById[product.id!] = quantity;
      }
    }

    List<MapEntry<ProductModel, int>> consolidatedProductEntries = productsById
        .entries
        .map((entry) => MapEntry(entry.value, quantitiesById[entry.key]!))
        .toList();

    List<ProductModel> consolidatedProducts =
        consolidatedProductEntries.map((entry) {
      return entry.key..quantity!.value = entry.value;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recibo de Compra',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple, // Adds a custom color to the AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                leading: Icon(Icons.receipt_long,
                    size: 50,
                    color: Colors.deepPurple), // Custom color for the icon
                title: Text('Productos Comprados',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: consolidatedProductEntries.length,
                  itemBuilder: (BuildContext context, int index) {
                    final productEntry = consolidatedProductEntries[index];
                    final product = productEntry.key;
                    final quantity = productEntry.value;
                    return ListTile(
                      title: Text(product.name,
                          style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold)), // Bold for product names
                      subtitle: Text(
                          'Cantidad: $quantity\nPrecio por unidad: \$${product.cost.toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: conceptoController,
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Costo Total:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors
                                .deepPurple)), // Custom style for total cost
                    Text('\$${totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await updateMultipleProducts(
                        context, conceptoController.text, consolidatedProducts);

                    final snackBar = SnackBar(
                      content: const Text(
                        'Has agregado productos correctamente',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor:
                          Colors.deepPurple, // Un color de fondo llamativo
                      duration: const Duration(
                          seconds: 3), // Duración que el SnackBar será mostrado
                      action: SnackBarAction(
                        label: 'Deshacer',
                        textColor:
                            Colors.amber, // Color llamativo para la acción
                        onPressed: () {
                          // Código para deshacer la acción aquí
                        },
                      ),
                      behavior: SnackBarBehavior
                          .floating, // Hace que el SnackBar "flote" sobre la UI
                      shape: RoundedRectangleBorder(
                        // Forma personalizada
                        borderRadius:
                            BorderRadius.circular(20.0), // Bordes redondeados
                      ),
                      margin: const EdgeInsets.all(
                          10), // Margen alrededor del SnackBar
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0), // Ajusta el padding interno
                    );

                    // Muestra el SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.deepPurple), // Custom button color
                  child: const Text('Aceptar',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateMultipleProducts(BuildContext context, String concepto,
      List<ProductModel> consolidatedProducts) async {
    final dataBase = Provider.of<DataBase>(context, listen: false);

    // Filtra los productos que tienen subproductos
    List<ProductModel> productsWithSubproducts = consolidatedProducts
        .where((product) =>
            product.subProduct != null && product.subProduct!.isNotEmpty)
        .toList();

    if (productsWithSubproducts.isNotEmpty) {
      // Reduce la cantidad de los productos en la base de datos
      await dataBase.reduceProductStock(productsWithSubproducts);
    }

    // Crea una orden con el concepto y los productos consolidados
    OrderModel order = OrderModel(
      pagos: [],
      orderNumber: "",
      clientName: concepto, // Llena con los datos apropiados
      celNumber: '', // Llena con los datos apropiados
      direccion: '', // Llena con los datos apropiados
      date: DateTime.now().toString(),
      comment: "",
      totalCost: consolidatedProducts.fold(
          0, (sum, item) => sum + (item.cost * item.quantity!.value)),
      status: 'Compra',
      margen: '', // Llena con los datos apropiados
      totalOwned: '', // Llena con los datos apropiados
    );

    await dataBase.createOrderWithProducts(order, consolidatedProducts);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomePage()),
      (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
    );
  }
}
