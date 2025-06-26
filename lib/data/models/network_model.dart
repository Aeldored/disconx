enum NetworkStatus { verified, suspicious, unknown }

enum SecurityType { wpa2, wpa3, open }

class NetworkModel {
  final String id;
  final String name;
  final String? description;
  final NetworkStatus status;
  final SecurityType securityType;
  final int signalStrength; // 0-100
  final String macAddress;
  final double? latitude;
  final double? longitude;
  final DateTime lastSeen;
  final bool isConnected;

  NetworkModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.securityType,
    required this.signalStrength,
    required this.macAddress,
    this.latitude,
    this.longitude,
    required this.lastSeen,
    this.isConnected = false,
  });

  String get securityTypeString {
    switch (securityType) {
      case SecurityType.wpa2:
        return 'WPA2';
      case SecurityType.wpa3:
        return 'WPA3';
      case SecurityType.open:
        return 'Open';
    }
  }

  String get signalStrengthString {
    if (signalStrength > 70) return 'Strong';
    if (signalStrength > 40) return 'Medium';
    return 'Weak';
  }

  int get signalBars {
    if (signalStrength > 75) return 4;
    if (signalStrength > 50) return 3;
    if (signalStrength > 25) return 2;
    return 1;
  }

  factory NetworkModel.fromJson(Map<String, dynamic> json) {
    return NetworkModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: NetworkStatus.values.firstWhere(
        (e) => e.toString() == 'NetworkStatus.${json['status']}',
      ),
      securityType: SecurityType.values.firstWhere(
        (e) => e.toString() == 'SecurityType.${json['securityType']}',
      ),
      signalStrength: json['signalStrength'],
      macAddress: json['macAddress'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      lastSeen: DateTime.parse(json['lastSeen']),
      isConnected: json['isConnected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.toString().split('.').last,
      'securityType': securityType.toString().split('.').last,
      'signalStrength': signalStrength,
      'macAddress': macAddress,
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': lastSeen.toIso8601String(),
      'isConnected': isConnected,
    };
  }
}