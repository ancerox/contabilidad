class DateRange {
  DateTime? start;
  DateTime? end;
  int? orderId; // Add orderId to DateRange

  DateRange({this.start, this.end, this.orderId});

  Map<String, dynamic> toMap() {
    return {
      'start': start?.toIso8601String(),
      'end': end?.toIso8601String(),
      'orderId': orderId, // Include orderId in toMap
    };
  }

  static DateRange fromMap(Map<String, dynamic> map) {
    return DateRange(
      start: map['start'] != null ? DateTime.parse(map['start']) : null,
      end: map['end'] != null ? DateTime.parse(map['end']) : null,
      orderId: map['orderId'], // Include orderId in fromMap
    );
  }

  @override
  String toString() {
    return 'DateRange(start: ${start?.toIso8601String()}, end: ${end?.toIso8601String()})';
  }
}
