// import 'package:flutter/cupertino.dart';

// class SubProduct {
//   final int? id;
//   final String name;
//   final String? file;
//   int amount;
//   double unitPrice;
//   // Nuevos campos
//   final String productCategory;
//   double cost;
//   final String unit;
//   final String productType;
//   ValueNotifier<int>? quantity;

//   SubProduct({
//     this.quantity,
//     required this.productType,
//     required this.productCategory,
//     this.id,
//     required this.name,
//     this.file,
//     required this.amount,
//     required this.unitPrice,
//     // Inicializar los nuevos campos

//     required this.cost,
//     required this.unit,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'file': file,
//       'amount': amount,
//       'unitPrice': unitPrice,
//       // Mapear los nuevos campos
//       'productCategory': productCategory,
//       'cost': cost,
//       'unit': unit,
//       'productType': productType,
//     };
//   }
// }
