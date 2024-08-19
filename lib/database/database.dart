import 'dart:convert';
import 'dart:io';

import 'package:contabilidad/models/date_range.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

class DataBase extends ChangeNotifier {
  final ValueNotifier<double> _totalPriceNotifier = ValueNotifier<double>(0.0);

  ValueNotifier<double> get totalPriceNotifier => _totalPriceNotifier;

  double get totalPrice => _totalPriceNotifier.value;

  set totalPrice(double value) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _totalPriceNotifier.value = value;
    });
  }

  ValueNotifier<int> quantityNotifier = ValueNotifier(0);
  ValueNotifier<DateRange> dateRange = ValueNotifier(DateRange());

  Map<String, DateRange> dateRangeMap = {};

  ValueNotifier<List<ProductModel>> selectedProductsNotifier =
      ValueNotifier<List<ProductModel>>([]);
  ValueNotifier<List<ProductModel>> selectedProductsProvider =
      ValueNotifier<List<ProductModel>>([]);

  ValueNotifier<List<ProductModel>> selectedCommodities =
      ValueNotifier<List<ProductModel>>([]);

  int zeroquantityCount = 0; // Parameter to keep track of zero quantity

  Future<Database> getDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'mi_base_de_datos.db');
    return openDatabase(
      path,
      onCreate: (db, version) {
        db.execute(
          "CREATE TABLE IF NOT EXISTS products(id INTEGER PRIMARY KEY, name TEXT, file TEXT, amount INTEGER, unitPrice REAL, productCategory TEXT, cost REAL, unit TEXT, productType TEXT, subProduct TEXT, quantity INTEGER, datesNotAvailable TEXT, datesUsed TEXT)",
        );
        db.execute(
          "CREATE TABLE IF NOT EXISTS orders(id INTEGER PRIMARY KEY AUTOINCREMENT, clientName TEXT, celNumber TEXT, direccion TEXT, date TEXT, comment TEXT, totalCost REAL, status TEXT, margen TEXT, totalOwned TEXT, orderNumber TEXT, productList TEXT, pagos TEXT, datesInUse TEXT, adminExpenses TEXT)",
        );
        db.execute(
          "CREATE TABLE IF NOT EXISTS order_products(orderId INTEGER, productId INTEGER, quantity INTEGER, PRIMARY KEY (orderId, productId), FOREIGN KEY (orderId) REFERENCES orders(id), FOREIGN KEY (productId) REFERENCES products(id))",
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE products ADD COLUMN file TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE products ADD COLUMN subProduct TEXT');
        }
        if (oldVersion < 4) {
          await db.execute(
              'ALTER TABLE products ADD COLUMN datesNotAvailable TEXT, datesUsed TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE orders ADD COLUMN orderNumber TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE orders ADD COLUMN pagos TEXT');
        }
      },
      version: 6, // Increment the version of the database
    );
  }

  List<OrderModel> _orders = [];
  String _selectedStatus = 'historial';
  String _filterText = '';
  String _filterBy = 'Nombre'; // Aquí definimos el campo _filterBy

  // Getters para acceder a las variables privadas
  List<OrderModel> get orders => _orders;
  String get selectedStatus => _selectedStatus;
  String get filterText => _filterText;
  String get filterBy => _filterBy; // Este es el getter que falta

  // Setters para actualizar las variables y notificar cambios
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

  void setFilterBy(String filter) {
    // Este setter actualiza _filterBy
    _filterBy = filter;
    notifyListeners();
  }

  // Filtrar órdenes según el texto y el tipo de filtro seleccionados
  List<OrderModel> get filteredOrders {
    List<OrderModel> filteredOrderList = _orders.where((OrderModel order) {
      return order.status == _selectedStatus || _selectedStatus == "historial";
    }).toList();

    if (_filterText.isNotEmpty) {
      filteredOrderList = _orders.where((OrderModel order) {
        switch (_filterBy) {
          case 'Fecha':
            return order.date.toLowerCase().contains(_filterText.toLowerCase());
          case 'Número de orden':
            return order.id.toString().contains(_filterText);
          case 'Producto':
            return order.productList?.any((product) => product.name
                    .toLowerCase()
                    .contains(_filterText.toLowerCase())) ??
                false;
          case 'Estatus':
            return order.status
                .toLowerCase()
                .contains(_filterText.toLowerCase());
          case 'Nombre':
          default:
            return order.clientName
                .toLowerCase()
                .contains(_filterText.toLowerCase());
        }
      }).toList();
    }

    return filteredOrderList;
  }

  Future<void> exportToCsv(
      BuildContext context, List<OrderModel> orders) async {
    try {
      // Prompt the user to select a directory
      String? directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath == null) {
        // User canceled the picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export canceled')),
        );
        return;
      }

      List<List<String>> csvData = [
        // Header row
        <String>['Order ID', 'Client Name', 'Status', 'Date', 'Total Cost'],
        // Data rows
        ...orders.map((order) => [
              order.id.toString(),
              order.clientName,
              order.status,
              order.date,
              order.totalCost.toString(),
            ])
      ];

      String csv = const ListToCsvConverter().convert(csvData);

      // Save file to the selected directory
      final String path = '$directoryPath/orders.csv';

      final File file = File(path);
      await file.writeAsString(csv);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV file saved to $path')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  Future<void> exportToExcel(
      BuildContext context, List<OrderModel> orders) async {
    try {
      // Prompt the user to select a directory
      String? directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath == null) {
        // User canceled the picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export canceled')),
        );
        return;
      }

      var excel = Excel.createExcel();

      // Create a sheet
      Sheet sheetObject = excel['Orders'];

      // Header row
      sheetObject.appendRow([
        'Order ID',
        'Client Name',
        'Status',
        'Date',
        'Total Cost',
      ]);

      // Data rows
      for (var order in orders) {
        sheetObject.appendRow([
          order.id.toString(),
          order.clientName,
          order.status,
          order.date,
          order.totalCost.toString(),
        ]);
      }

      // Save the file to the selected directory
      final String path = '$directoryPath/orders.xlsx';

      excel.save(fileName: path);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel file saved to $path')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export Excel: $e')),
      );
    }
  }

  Future<bool> handleStoragePermission() async {
    // Check the current permission status
    var status = await Permission.storage.status;

    // If the permission is granted, return true
    if (status.isGranted) {
      return true;
    }

    // If permission is denied permanently (user selected "Don't ask again"), show a dialog to open app settings
    else if (status.isPermanentlyDenied) {
      bool isOpened = await openAppSettings();
      return isOpened; // Return the result of opening app settings
    }

    // If permission is denied or restricted, request permission
    else {
      status = await Permission.storage.request();

      if (status.isGranted) {
        return true;
      } else {
        // Permission is denied, handle accordingly (maybe show a message to the user)
        return false;
      }
    }
  }

  Future<ProductModel?> getProductById(int id) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ProductModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> insertProduct(ProductModel productModel) async {
    final db = await getDatabase();
    await db.insert(
      'products',
      productModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<void> removeSubproduct(int subproductId) async {
    final db = await getDatabase();
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [subproductId],
    );
    notifyListeners();
  }

  Future<List<ProductModel>> obtenerProductos() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return ProductModel.fromMap(maps[i]);
    });
  }

  Future<void> deleteProduct(int id) async {
    final db = await getDatabase();

    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> updateProductAmount(int id, int newAmount) async {
    final db = await getDatabase();

    try {
      // Realizar una operación de actualización en la tabla 'products'
      int result = await db.update(
        'products',
        {'amount': newAmount},
        where: 'id = ?',
        whereArgs: [id],
      );

      // Verificar si la actualización fue exitosa
      if (result > 0) {
        print('Cantidad actualizada correctamente para el producto con ID $id');
      } else {
        print('No se encontró el producto con ID $id para actualizar');
      }

      notifyListeners();
    } catch (e) {
      print('Error actualizando la cantidad del producto: $e');
    }
  }

  Future<void> updateProductCost(int id, double newCost) async {
    final db = await getDatabase();

    await db.update(
      'products',
      {'cost': newCost},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> updateMultipleProductCosts(Map<int, double> idCostMap) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      for (var entry in idCostMap.entries) {
        await txn.update(
          'products',
          {'cost': entry.value},
          where: 'id = ?',
          whereArgs: [entry.key],
        );
      }
    });
    notifyListeners();
  }

  Future<void> insertOrder(OrderModel order) async {
    final db = await getDatabase();
    try {
      Map<String, dynamic> orderMap = order.toMap();
      print('Attempting to insert order with data: $orderMap');
      await db.insert(
        'orders',
        orderMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Order inserted successfully');
    } catch (e) {
      print('Error inserting order: $e');
    }
    notifyListeners();
  }

  Future<List<OrderModel>> getOrders() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('orders');

    return List.generate(maps.length, (i) {
      return OrderModel.fromMap(maps[i]);
    });
  }

  Future<List<OrderModel>> getAllOrdersWithProducts() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> orderMaps = await db.query('orders');
    List<OrderModel> orders = [];

    try {
      for (var orderMap in orderMaps) {
        List<ProductModel> products = [];

        // Get product entries linked to the order
        final List<Map<String, dynamic>> orderProductMaps = await db.query(
          'order_products',
          where: 'orderId = ?',
          whereArgs: [orderMap['id']],
        );

        print(
            'Order ID ${orderMap['id']} has ${orderProductMaps.length} products linked.');

        for (var orderProductMap in orderProductMaps) {
          final List<Map<String, dynamic>> productMaps = await db.query(
            'products',
            where: 'id = ?',
            whereArgs: [orderProductMap['productId']],
          );

          if (productMaps.isNotEmpty) {
            var product = ProductModel.fromMap(productMaps.first);
            product = product.copyWith(
                quantity: ValueNotifier<int>(orderProductMap['quantity']));
            products.add(product);
          }
        }

        if (products.isNotEmpty) {
          print(
              'Products added for order ID ${orderMap['id']}: ${products.map((p) => p.name).join(', ')}');
        } else {
          print('No products found for order ID ${orderMap['id']}.');
        }

        OrderModel order = OrderModel.fromMap(orderMap);
        order = order.copyWith(productList: products);
        orders.add(order);
      }
    } catch (e) {
      print('Error fetching orders with products: $e');
    }

    return orders;
  }

  Future<void> updateProduct(ProductModel product) async {
    final db = await getDatabase();

    // Retrieve the existing product from the database to get the current subProducts
    final existingProductMap = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [product.id],
    );

    if (existingProductMap.isNotEmpty) {
      final existingProduct = ProductModel.fromMap(existingProductMap.first);

      // Preserve the existing subProducts if the new product has them empty or null
      final updatedSubProducts =
          product.subProduct ?? existingProduct.subProduct;

      // Convert the list of subproducts to a list of maps for JSON encoding
      final encodedSubProducts =
          updatedSubProducts?.map((subProduct) => subProduct.toMap()).toList();

      // Convert the product to a map and update it
      final updatedProductMap = product.toMap();
      updatedProductMap['subProduct'] = jsonEncode(encodedSubProducts);

      await db.update(
        'products',
        updatedProductMap,
        where: 'id = ?',
        whereArgs: [product.id],
      );
    }

    notifyListeners();
  }

  Future<void> reduceProductStock(List<ProductModel> productsToReduce) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      for (var product in productsToReduce) {
        // Obtén la cantidad actual del producto desde la base de datos
        List<Map<String, dynamic>> productData = await txn.query(
          'products',
          columns: ['amount'],
          where: 'id = ?',
          whereArgs: [product.id],
        );

        if (productData.isNotEmpty) {
          var currentAmount = productData.first['amount'] as int;
          var newAmount = currentAmount - product.quantity!.value;

          // Actualiza la cantidad del producto en la base de datos
          await txn.update(
            'products',
            {'amount': newAmount},
            where: 'id = ?',
            whereArgs: [product.id],
          );
        }
      }
    });
    notifyListeners();
  }

  // Method to get the count of products with quantity equal to zero
  int getZeroquantityCount() {
    return zeroquantityCount;
  }

  // Function to update an existing order in the database
  // Updates specific fields of an existing order in the database
  Future<void> updateOrderFieldss(int orderId, OrderModel order) async {
    final db = await getDatabase();

    try {
      // Prepare fields for update
      Map<String, dynamic> updatedFields = {
        'status': order.status,
        'totalCost': order.totalCost,
        'pagos': json.encode(order.pagos.map((e) => e.toMap()).toList()),
        'productList':
            json.encode(order.productList?.map((e) => e.toMap()).toList()),
        'orderNumber': order.orderNumber,
        'totalOwned': order.totalOwned,
        'margen': order.margen,
        'clientName': order.clientName,
        'celNumber': order.celNumber,
        'direccion': order.direccion,
        'date': order.date,
        'comment': order.comment,
      };

      int count = await db.update(
        'orders',
        updatedFields,
        where: 'id = ?',
        whereArgs: [orderId],
      );

      print(
          'Updating productList with: ${json.encode(order.productList?.map((e) => e.toMap()).toList())}');

      if (count == 0) {
        print('No rows updated, check your orderId!');
      } else {
        print('$count rows updated successfully');
      }

      notifyListeners(); // Notify listeners in case they need to update their views
    } catch (e) {
      print('Error updating order: $e');
    }
  }

  Future<int> getTotalOrdersCount() async {
    final db = await getDatabase();

    // Get the total count of orders from the database
    final result =
        await db.rawQuery('SELECT COUNT(*) as totalOrders FROM orders');

    int totalOrders;
    if (result.isNotEmpty && result.first['totalOrders'] != null) {
      totalOrders = result.first['totalOrders'] as int;
    } else {
      totalOrders = 0; // Default to 0 if no orders are found
    }

    return totalOrders;
  }

  Future<void> createOrderWithProducts(
      OrderModel order, List<ProductModel> products) async {
    final db = await getDatabase();

    try {
      // Debugging: Check the order map before insertion
      Map<String, dynamic> orderMap = order.toMap();
      print('Order Map: $orderMap');

      await db.transaction((txn) async {
        try {
          // Insert the order and get the generated id
          int orderId = await txn.insert(
            'orders',
            orderMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Log the order ID to verify it was created
          print('Inserted order with ID: $orderId');

          // Insert the products linked to the order without altering their quantity
          for (var product in products) {
            try {
              // Log the product details to verify they are correct
              int quantity = product.quantity?.value ?? 0;
              print(
                  'Linking product with ID: ${product.id} and quantity: $quantity');

              // Insert the product linkage in the order_products table
              await txn.insert(
                'order_products',
                {
                  'orderId': orderId,
                  'productId': product.id,
                  'quantity': quantity,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              // Update datesUsed field for the product
              if (product.datesUsed != null) {
                await txn.update(
                  'products',
                  {
                    'datesUsed': jsonEncode(product.datesUsed!
                        .map((range) => range.toMap())
                        .toList()),
                  },
                  where: 'id = ?',
                  whereArgs: [product.id],
                );
              }
            } catch (e) {
              print('Error linking product with ID ${product.id}: $e');
            }
          }

          // Verify inserted data
          final List<Map<String, dynamic>> result = await txn.query(
            'order_products',
            where: 'orderId = ?',
            whereArgs: [orderId],
          );
          for (var row in result) {
            print('Inserted order_product: $row');
          }
        } catch (e) {
          print('Error during transaction: $e');
          rethrow; // To ensure the transaction is rolled back
        }
      });

      notifyListeners();
    } catch (e) {
      print('Error creating order with products: $e');
    }
  }

  Future<void> updateOrderWithProducts(int orderId, OrderModel updatedOrder,
      List<ProductModel> updatedProducts) async {
    final db = await getDatabase();

    await db.transaction((txn) async {
      try {
        // Update the order details
        await txn.update(
          'orders',
          updatedOrder.toMap(),
          where: 'id = ?',
          whereArgs: [orderId],
        );

        // Delete existing product links for this order
        await txn.delete(
          'order_products',
          where: 'orderId = ?',
          whereArgs: [orderId],
        );

        // Insert updated products
        for (var product in updatedProducts) {
          var productId = product.id; // Ensure productId is unique id
          var productQuantity =
              product.quantity?.value ?? 0; // Default quantity to 0 if null

          if (productQuantity > 0) {
            await txn.insert(
              'order_products',
              {
                'orderId': orderId,
                'productId': productId,
                'quantity': productQuantity,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // Ensure datesUsed is correctly updated (overwritten, not appended)
          if (product.datesUsed != null && product.datesUsed!.isNotEmpty) {
            // Overwrite the datesUsed field directly, not just updating or appending
            await txn.update(
              'products',
              {
                'datesUsed': jsonEncode(
                    product.datesUsed!.map((range) => range.toMap()).toList()),
              },
              where: 'id = ?',
              whereArgs: [product.id],
            );
          }
        }

        print('Order and products updated successfully.');
      } catch (e, stackTrace) {
        print('Error updating order with products: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    notifyListeners(); // Notify listeners to update the UI if needed
  }

  // Method to export database data as JSON
  Future<String> exportDatabaseToJson() async {
    final db = await getDatabase();

    // Retrieve data from the tables
    final List<Map<String, dynamic>> products = await db.query('products');
    final List<Map<String, dynamic>> orders = await db.query('orders');
    final List<Map<String, dynamic>> orderProducts =
        await db.query('order_products');

    // Create a map with the data
    final Map<String, dynamic> data = {
      'products': products,
      'orders': orders,
      'order_products': orderProducts,
    };

    // Convert the map to a JSON string
    return jsonEncode(data);
  }

  // Method to save JSON data to a user-selected directory
  Future<void> saveJsonToFile(String jsonString) async {
    // Open the directory picker
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      const String fileName = 'database_backup.json';
      final File file = File(path.join(selectedDirectory, fileName));

      // Write the JSON string to the file
      await file.writeAsString(jsonString);
    }
  }

  // Method to back up the database
  Future<void> backupDatabase() async {
    String jsonString = await exportDatabaseToJson();
    await saveJsonToFile(jsonString);
  }

  // Method to load data from a JSON file
  Future<void> loadDataFromJson() async {
    // Open the file picker in read mode
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.isNotEmpty) {
      final File file = File(result.files.single.path!);
      final String jsonString = await file.readAsString();

      // Parse the JSON data
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Clear the existing data
      await clearExistingData();

      // Insert the new data
      await insertProductsFromJson(data['products']);
      await insertOrdersFromJson(data['orders'], data['order_products']);

      notifyListeners();
    }
  }

  // Helper method to clear existing data
  Future<void> clearExistingData() async {
    final db = await getDatabase();
    await db.delete('products');
    await db.delete('orders');
    await db.delete('order_products');
  }

  // Helper methods to insert data from JSON
  Future<void> insertProductsFromJson(List<dynamic> productData) async {
    final db = await getDatabase();
    for (var product in productData) {
      await db.insert(
        'products',
        ProductModel.fromMap(product).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> insertOrdersFromJson(
    List<dynamic> orderData,
    List<dynamic> orderProductData,
  ) async {
    final db = await getDatabase();
    for (var order in orderData) {
      await db.insert(
        'orders',
        OrderModel.fromMap(order).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (var orderProduct in orderProductData) {
      await db.insert(
        'order_products',
        orderProduct,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
