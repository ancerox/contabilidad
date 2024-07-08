import 'package:flutter/material.dart';

class MyPage extends StatefulWidget {
  final Map<dynamic, int> selectedProducts;

  const MyPage({super.key, required this.selectedProducts});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    double totalCost = widget.selectedProducts.entries.fold(
      0.0,
      (previousValue, entry) => previousValue + (entry.key.cost * entry.value),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: Center(
        child: Text('Total Cost: \$${totalCost.toStringAsFixed(2)}'),
      ),
    );
  }
}

class ProducdtModel {
  final int id;
  final String name;
  final double cost;

  ProducdtModel({
    required this.id,
    required this.name,
    required this.cost,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}
