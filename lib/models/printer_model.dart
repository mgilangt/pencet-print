class PrinterModel {
  final String name;
  final String address;
  final bool isConnected;

  const PrinterModel({
    required this.name,
    required this.address,
    this.isConnected = false,
  });

  PrinterModel copyWith({
    String? name,
    String? address,
    bool? isConnected,
  }) {
    return PrinterModel(
      name: name ?? this.name,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  String toString() =>
      'PrinterModel(name: $name, address: $address, connected: $isConnected)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrinterModel && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}
