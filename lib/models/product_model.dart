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
  double cost;
  final String unit;
  final String productType;
  ValueNotifier<int>? quantity;
  final List<ProductModel>? subProduct;
  List<DateRange>? datesNotAvailable;
  List<DateRange>? datesUsed;

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
  });

  ProductModel copyWith({
    int? id,
    String? name,
    String? file,
    int? amount,
    double? unitPrice,
    String? productCategory,
    double? cost,
    String? unit,
    String? productType,
    ValueNotifier<int>? quantity,
    List<ProductModel>? subProduct,
    List<DateRange>? datesNotAvailable,
    List<DateRange>? datesUsed,
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
      ];

  @override
  bool get stringify => true;

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
          : null,
      'datesUsed': datesUsed != null
          ? jsonEncode(datesUsed!.map((range) => range.toMap()).toList())
          : null,
    };
  }

  static ProductModel fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      file: map['file'],
      amount: map['amount'],
      unitPrice: map['unitPrice'],
      productCategory: map['productCategory'],
      cost: map['cost'],
      unit: map['unit'],
      productType: map['productType'],
      quantity: ValueNotifier<int>(map['quantity'] ?? 0),
      subProduct: map['subProduct'] != null
          ? List<ProductModel>.from(
              jsonDecode(map['subProduct']).map((p) => ProductModel.fromMap(p)))
          : null,
      datesNotAvailable: map['datesNotAvailable'] != null
          ? List<DateRange>.from(jsonDecode(map['datesNotAvailable'])
              .map((range) => DateRange.fromMap(range)))
          : null,
      datesUsed: map['datesUsed'] != null
          ? List<DateRange>.from(jsonDecode(map['datesUsed'])
              .map((range) => DateRange.fromMap(range)))
          : null,
    );
  }
}
