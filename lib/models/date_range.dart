class DateRange {
  DateTime? start;
  DateTime? end;
  int? orderId;
  int? borrowQuantity; // Add borrowQuantity to DateRange

  DateRange({this.start, this.end, this.orderId, this.borrowQuantity});

  Map<String, dynamic> toMap() {
    return {
      'start': start?.toIso8601String(),
      'end': end?.toIso8601String(),
      'orderId': orderId,
      'borrowQuantity': borrowQuantity, // Include borrowQuantity in toMap
    };
  }

  static DateRange fromMap(Map<String, dynamic> map) {
    return DateRange(
      start: map['start'] != null ? DateTime.parse(map['start']) : null,
      end: map['end'] != null ? DateTime.parse(map['end']) : null,
      orderId: map['orderId'],
      borrowQuantity:
          map['borrowQuantity'], // Include borrowQuantity in fromMap
    );
  }

  DateRange copyWith({int? borrowQuantity}) {
    return DateRange(
      start: start,
      end: end,
      orderId: orderId,
      borrowQuantity: borrowQuantity ?? this.borrowQuantity,
    );
  }

  @override
  String toString() {
    return 'DateRange(start: ${start?.toIso8601String()}, end: ${end?.toIso8601String()}, orderId: $orderId, borrowQuantity: $borrowQuantity)';
  }
}
