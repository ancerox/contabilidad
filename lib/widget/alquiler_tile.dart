import 'dart:io';

import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/date_range.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductTile extends StatefulWidget {
  final Widget title;
  final DateTime startDay;
  final DateTime endDay;

  final bool isEditPage;
  final Map<int, List<DateRange>> productDateRanges;
  final DateTime dateSelected;
  final ProductModel productModel;
  final String imagePath;
  final String productName;
  final ValueChanged<int> onQuantityChanged;
  final int initialQuantity;

  const ProductTile(
      {required this.title,
      required this.isEditPage,
      required this.productDateRanges,
      required this.dateSelected,
      required this.productModel,
      super.key,
      required this.imagePath,
      required this.productName,
      required this.onQuantityChanged,
      required this.initialQuantity,
      required this.endDay,
      required this.startDay});

  @override
  _ProductTileState createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  late TextEditingController _controller;
  final ValueNotifier<int> _quantityNotifier = ValueNotifier<int>(0);
  bool isConditionMet = false; // This is the condition variable
  late DataBase databaseProvider;

  @override
  void initState() {
    super.initState();
    databaseProvider = Provider.of<DataBase>(context, listen: false);
    _quantityNotifier.value = widget.initialQuantity;
    _controller = TextEditingController(
        text: widget.productModel.quantity!.value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    _quantityNotifier.dispose();

    super.dispose();
  }

  void _incrementQuantity() {
    if (widget.productDateRanges[widget.productModel.id] == null ||
        widget.productDateRanges[widget.productModel.id]!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor eliga primero un fecha')),
      );
      return;
    }

    if (!isStockAvailableForNewOrder(widget.productModel, widget.startDay,
        widget.endDay, _quantityNotifier.value + 1)) {
      // Optional: Provide feedback if the condition is not met
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'No puedes exeder el total de ${widget.productModel.name} disponibles')),
      );
      return;
    } else {
      // Check the condition before incrementing
      _quantityNotifier.value++;
      widget.onQuantityChanged(_quantityNotifier.value);
      _controller.text = _quantityNotifier.value.toString();
    }
  }

  void _decrementQuantity() {
    if (_quantityNotifier.value > 0) {
      _quantityNotifier.value--;
      widget.onQuantityChanged(_quantityNotifier.value);
      _controller.text = _quantityNotifier.value.toString();
    }
  }

  void _onQuantityChanged(String value) {
    print("TEST43434");
    int? newQuantity = int.tryParse(value);
    if (newQuantity != null) {
      if (isStockAvailableForNewOrder(widget.productModel, widget.dateSelected,
          widget.dateSelected, newQuantity)) {
        _quantityNotifier.value = newQuantity;
        widget.onQuantityChanged(_quantityNotifier.value);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'No puedes exeder el total de ${widget.productModel.name} disponibles')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.contain,
            image: FileImage(File(widget.imagePath)),
          ),
          color: const Color(0xffD8DFFF),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      title: widget.title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _decrementQuantity,
          ),
          SizedBox(
            width: 40,
            child: ValueListenableBuilder<int>(
              valueListenable: _quantityNotifier,
              builder: (context, quantity, child) {
                if (_controller.text.isEmpty || _controller.text == "0") {
                  _controller =
                      TextEditingController(text: quantity.toString());
                }
                return TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  onChanged: _onQuantityChanged,
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _incrementQuantity,
          ),
          _quantityNotifier.value > 0
              ? const Icon(
                  Icons.check,
                  color: Colors.green,
                )
              : Container()
        ],
      ),
    );
  }

  int calculateStockInUse(ProductModel productModel) {
    if (productModel.datesUsed != null) {
      final now = widget.dateSelected;

      // Create a set of IDs to exclude based on the dateRangeMap
      final excludedIds = databaseProvider.dateRangeMap.keys.toSet();

      final totalBorrowed = productModel.datesUsed!
          .where((element) =>
              !excludedIds.contains(element.id) &&
              isDateRangeOverlap(now, element.start!, element.end!))
          .fold<int>(0, (sum, element) => sum + (element.borrowQuantity ?? 0));

      final availableStock = productModel.amount - totalBorrowed;

      return availableStock;
    }
    return productModel.amount;
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.day == date2.day &&
        date1.month == date2.month &&
        date1.year == date2.year;
  }

  bool isDateRangeOverlap(DateTime date, DateTime start, DateTime end) {
    DateTime dateOnly = DateTime(date.year, date.month, date.day);
    DateTime startOnly = DateTime(start.year, start.month, start.day);
    DateTime endOnly = DateTime(end.year, end.month, end.day);

    return (dateOnly.isAfter(startOnly) && dateOnly.isBefore(endOnly)) ||
        isSameDay(dateOnly, startOnly) ||
        isSameDay(dateOnly, endOnly);
  }

  bool isDateRangeOverlapWithRange(
      DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return (start1.isBefore(end2) && end1.isAfter(start2)) ||
        isSameDay(start1, start2) ||
        isSameDay(end1, end2);
  }

// Check stock availability for a new order
  bool isStockAvailableForNewOrder(ProductModel productModel,
      DateTime newOrderStart, DateTime newOrderEnd, int newBorrowQuantity) {
    if (productModel.datesUsed != null) {
      final excludedIds = databaseProvider.dateRangeMap.keys.toSet();

      final totalBorrowed = productModel.datesUsed!
          .where((element) =>
              !excludedIds.contains(element.id) &&
              isDateRangeOverlapWithRange(
                  newOrderStart, newOrderEnd, element.start!, element.end!))
          .fold<int>(0, (sum, element) => sum + (element.borrowQuantity ?? 0));

      final availableStock = productModel.amount - totalBorrowed;

      return availableStock >= newBorrowQuantity;
    }
    return productModel.amount >= newBorrowQuantity;
  }
}
