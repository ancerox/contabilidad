class DateRange {
  DateTime? start;
  DateTime? end;
  String? id;
  int? borrowQuantity; // Add borrowQuantity to DateRange

  DateRange({this.start, this.end, this.id, this.borrowQuantity});

  Map<String, dynamic> toMap() {
    return {
      'start': start?.toIso8601String(),
      'end': end?.toIso8601String(),
      'id': id,
      'borrowQuantity': borrowQuantity, // Include borrowQuantity in toMap
    };
  }

  static DateRange fromMap(Map<String, dynamic> map) {
    return DateRange(
      start: map['start'] != null ? DateTime.parse(map['start']) : null,
      end: map['end'] != null ? DateTime.parse(map['end']) : null,
      id: map['id'],
      borrowQuantity:
          map['borrowQuantity'], // Include borrowQuantity in fromMap
    );
  }

  DateRange copyWith(
      {String? id,
      DateTime? start,
      DateTime? end,
      int? orderId,
      int? borrowQuantity}) {
    return DateRange(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      borrowQuantity: borrowQuantity ?? this.borrowQuantity,
    );
  }

  @override
  String toString() {
    return 'DateRange(start: ${start?.toIso8601String()}, end: ${end?.toIso8601String()}, id: $id, borrowQuantity: $borrowQuantity)';
  }
}
