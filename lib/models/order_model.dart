import 'dart:convert';

import 'package:contabilidad/models/date_range.dart';
import 'package:contabilidad/models/product_model.dart';

class PagoModel {
  final String date;
  final double amount;

  PagoModel({required this.date, required this.amount});

  factory PagoModel.fromMap(Map<String, dynamic> map) {
    return PagoModel(
      date: map['date'],
      amount: map['amount'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'amount': amount,
    };
  }
}

class OrderModel {
  final String? orderNumber;
  final String totalOwned;
  final String margen;
  int? id;
  final String clientName;
  final String celNumber;
  final String direccion;
  final List<ProductModel>? productList;
  final List<ProductModel>? adminExpenses;
  final String date;
  final String comment;
  final double totalCost;
  final String status;
  final List<PagoModel> pagos;
  Map<int, List<DateRange>>? datesInUse;

  OrderModel({
    required this.pagos,
    this.id,
    this.orderNumber,
    this.adminExpenses,
    required this.totalOwned,
    required this.margen,
    required this.status,
    required this.clientName,
    required this.celNumber,
    required this.direccion,
    this.productList,
    required this.date,
    required this.comment,
    required this.totalCost,
    this.datesInUse,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    List<ProductModel> productList = [];
    if (map['productList'] != null) {
      try {
        Iterable l = json.decode(map['productList']);
        productList = List<ProductModel>.from(
          l.map((model) => ProductModel.fromMap(model)),
        );
      } catch (e) {
        print('Error decoding productList: $e');
      }
    }

    List<ProductModel> adminExpenses = [];
    if (map['adminExpenses'] != null) {
      try {
        Iterable l = json.decode(map['adminExpenses']);
        adminExpenses = List<ProductModel>.from(
          l.map((model) => ProductModel.fromMap(model)),
        );
      } catch (e) {
        print('Error decoding adminExpenses: $e');
      }
    }

    List<PagoModel> pagosList = [];
    if (map['pagos'] != null) {
      try {
        Iterable l = json.decode(map['pagos']);
        pagosList = List<PagoModel>.from(
          l.map((model) => PagoModel.fromMap(model)),
        );
      } catch (e) {
        print('Error decoding pagos: $e');
      }
    }

    Map<int, List<DateRange>>? datesInUse;
    if (map['datesInUse'] != null) {
      try {
        Map<String, dynamic> datesInUseMap = json.decode(map['datesInUse']);
        datesInUse = datesInUseMap.map((key, value) {
          int intKey = int.parse(key);
          List<DateRange> ranges = List<DateRange>.from(
            value.map((range) => DateRange.fromMap(range)),
          );
          return MapEntry(intKey, ranges);
        });
      } catch (e) {
        print('Error decoding datesInUse: $e');
      }
    }

    return OrderModel(
      pagos: pagosList,
      orderNumber: map['orderNumber'],
      totalOwned: map['totalOwned'],
      margen: map['margen'],
      id: map['id'],
      status: map['status'],
      clientName: map['clientName'],
      celNumber: map['celNumber'],
      direccion: map['direccion'],
      productList: productList,
      adminExpenses: adminExpenses,
      date: map['date'],
      comment: map['comment'],
      totalCost: map['totalCost'].toDouble(),
      datesInUse: datesInUse,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pagos': json.encode(pagos.map((e) => e.toMap()).toList()),
      'orderNumber': orderNumber,
      'totalOwned': totalOwned,
      'margen': margen,
      'id': id,
      'status': status,
      'clientName': clientName,
      'celNumber': celNumber,
      'direccion': direccion,
      'date': date,
      'comment': comment,
      'totalCost': totalCost,
      'productList': productList != null
          ? json.encode(productList!.map((product) => product.toMap()).toList())
          : null,
      'adminExpenses': adminExpenses != null
          ? json
              .encode(adminExpenses!.map((expense) => expense.toMap()).toList())
          : null,
      'datesInUse': datesInUse != null
          ? json.encode(
              datesInUse!.map((key, value) => MapEntry(key.toString(),
                  value.map((range) => range.toMap()).toList())),
            )
          : null,
    };
  }

  OrderModel copyWith({
    String? orderNumber,
    String? totalOwned,
    String? margen,
    int? id,
    String? clientName,
    String? celNumber,
    String? direccion,
    List<ProductModel>? productList,
    List<ProductModel>? adminExpenses,
    String? date,
    String? comment,
    double? totalCost,
    String? status,
    List<PagoModel>? pagos,
    Map<int, List<DateRange>>? datesInUse,
  }) {
    return OrderModel(
      adminExpenses: adminExpenses ?? this.adminExpenses,
      orderNumber: orderNumber ?? this.orderNumber,
      totalOwned: totalOwned ?? this.totalOwned,
      margen: margen ?? this.margen,
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      celNumber: celNumber ?? this.celNumber,
      direccion: direccion ?? this.direccion,
      productList: productList ?? this.productList,
      date: date ?? this.date,
      comment: comment ?? this.comment,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      pagos: pagos ?? this.pagos,
      datesInUse: datesInUse ?? this.datesInUse,
    );
  }
}
