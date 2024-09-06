import 'dart:convert';

import 'package:contabilidad/models/date_range.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class ProductModel extends Equatable {
  final int? id;
  final String name;
  final String? file;
  int amount;
  double unitPrice;
  final String productCategory;
  int cost;
  final String unit;
  final String productType;
  ValueNotifier<int>? quantity;
  List<ProductModel>? subProduct;
  List<DateRange>? datesNotAvailable;
  List<DateRange>? datesUsed;
  bool
      costModified; // Nueva propiedad para rastrear si el costo fue modificado manualmente

  ProductModel({
    this.id,
    required this.name,
    this.file,
    required this.amount,
    required this.unitPrice,
    required this.productCategory,
    required this.cost,
    required this.unit,
    required this.productType,
    this.quantity,
    this.subProduct,
    this.datesNotAvailable,
    this.datesUsed,
    this.costModified = false, // Valor predeterminado a `false`
  });

  ProductModel copyWith({
    int? id,
    String? name,
    String? file,
    int? amount,
    double? unitPrice,
    String? productCategory,
    int? cost,
    String? unit,
    String? productType,
    ValueNotifier<int>? quantity,
    List<ProductModel>? subProduct,
    List<DateRange>? datesNotAvailable,
    List<DateRange>? datesUsed,
    bool? costModified, // Añadir al copyWith
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      file: file ?? this.file,
      amount: amount ?? this.amount,
      unitPrice: unitPrice ?? this.unitPrice,
      productCategory: productCategory ?? this.productCategory,
      cost: cost ?? this.cost,
      unit: unit ?? this.unit,
      productType: productType ?? this.productType,
      quantity: quantity ?? this.quantity,
      subProduct: subProduct ?? this.subProduct,
      datesNotAvailable: datesNotAvailable ?? this.datesNotAvailable,
      datesUsed: datesUsed ?? this.datesUsed,
      costModified: costModified ?? this.costModified, // Aplicar el cambio aquí
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        file,
        amount,
        unitPrice,
        productCategory,
        cost,
        unit,
        productType,
        quantity?.value,
        subProduct,
        datesNotAvailable,
        datesUsed,
        costModified, // Añadir a la lista de propiedades
      ];

  @override
  bool get stringify => true;

  // Convierte el objeto a un Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'file': file,
      'amount': amount,
      'unitPrice': unitPrice,
      'productCategory': productCategory,
      'cost': cost,
      'unit': unit,
      'productType': productType,
      'quantity': quantity?.value ?? 0,
      'subProduct': subProduct != null
          ? jsonEncode(subProduct!.map((p) => p.toMap()).toList())
          : null,
      'datesNotAvailable': datesNotAvailable != null
          ? jsonEncode(
              datesNotAvailable!.map((range) => range.toMap()).toList())
          : [],
      'datesUsed': datesUsed != null
          ? jsonEncode(datesUsed!.map((range) => range.toMap()).toList())
          : null,
      'costModified': costModified ? 1 : 0, // Convertir a entero para SQLite
    };
  }

  // Crea una instancia de ProductModel desde un Map
  static ProductModel fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      file: map['file'],
      amount: map['amount'],
      unitPrice: map['unitPrice'],
      productCategory: map['productCategory'],
      cost: (map['cost'] is double)
          ? (map['cost'] as double).toInt()
          : map['cost'] as int,
      unit: map['unit'],
      productType: map['productType'],
      quantity: ValueNotifier<int>(map['quantity'] ?? 0),
      subProduct: map['subProduct'] != null && map['subProduct'] is String
          ? (jsonDecode(map['subProduct']) as List<dynamic>?)
              ?.map((p) => ProductModel.fromMap(p as Map<String, dynamic>))
              .toList()
          : [],
      datesNotAvailable:
          map['datesNotAvailable'] != null && map['datesNotAvailable'] is String
              ? List<DateRange>.from(jsonDecode(map['datesNotAvailable'])
                  .map((range) => DateRange.fromMap(range)))
              : [],
      datesUsed: map['datesUsed'] != null && map['datesUsed'] is String
          ? List<DateRange>.from(jsonDecode(map['datesUsed'])
              .map((range) => DateRange.fromMap(range)))
          : null,
      costModified:
          (map['costModified'] == 1) ? true : false, // Convertir de int a bool
    );
  }
}
