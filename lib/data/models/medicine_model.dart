import '../../core/utils/arabic_date_helper.dart';

class MedicineModel {
  final int? id;
  final String tradeName;
  final String? scientificName;
  final String form;
  final String? concentration;
  final int clinicStock;
  final int warehouseStock;
  final int minStockAlert;
  final double unitCostPrice;
  final double unitSalePrice;
  final String expiryDate;
  final String? batchNumber;
  final String? createdAt;

  MedicineModel({
    this.id,
    required this.tradeName,
    this.scientificName,
    required this.form,
    this.concentration,
    this.clinicStock = 0,
    this.warehouseStock = 0,
    this.minStockAlert = 5,
    this.unitCostPrice = 0.0,
    this.unitSalePrice = 0.0,
    required this.expiryDate,
    this.batchNumber,
    this.createdAt,
  });

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] as int?,
      tradeName: map['trade_name'] as String? ?? '',
      scientificName: map['scientific_name'] as String?,
      form: map['form'] as String? ?? 'أقراص (Tablets)',
      concentration: map['concentration'] as String?,
      clinicStock: map['clinic_stock'] as int? ?? 0,
      warehouseStock: map['warehouse_stock'] as int? ?? 0,
      minStockAlert: map['min_stock_alert'] as int? ?? 5,
      unitCostPrice: (map['unit_cost_price'] as num? ?? 0.0).toDouble(),
      unitSalePrice: (map['unit_sale_price'] as num? ?? 0.0).toDouble(),
      expiryDate: map['expiry_date'] as String? ?? '',
      batchNumber: map['batch_number'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trade_name': tradeName,
      'scientific_name': scientificName,
      'form': form,
      'concentration': concentration,
      'clinic_stock': clinicStock,
      'warehouse_stock': warehouseStock,
      'min_stock_alert': minStockAlert,
      'unit_cost_price': unitCostPrice,
      'unit_sale_price': unitSalePrice,
      'expiry_date': expiryDate,
      'batch_number': batchNumber,
    };
  }

  int get totalStock => clinicStock + warehouseStock;

  bool get isLowStock => clinicStock <= minStockAlert;

  ExpiryStatus get expiryStatus {
    final parsed = ArabicDateHelper.parseDate(expiryDate);
    if (parsed == null) return ExpiryStatus.valid;
    return ArabicDateHelper.checkExpiryStatus(parsed);
  }

  bool get isExpired => expiryStatus == ExpiryStatus.expired;
  bool get isNearExpiry => expiryStatus == ExpiryStatus.nearExpiry;

  MedicineModel copyWith({
    int? id,
    String? tradeName,
    String? scientificName,
    String? form,
    String? concentration,
    int? clinicStock,
    int? warehouseStock,
    int? minStockAlert,
    double? unitCostPrice,
    double? unitSalePrice,
    String? expiryDate,
    String? batchNumber,
    String? createdAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      tradeName: tradeName ?? this.tradeName,
      scientificName: scientificName ?? this.scientificName,
      form: form ?? this.form,
      concentration: concentration ?? this.concentration,
      clinicStock: clinicStock ?? this.clinicStock,
      warehouseStock: warehouseStock ?? this.warehouseStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      unitCostPrice: unitCostPrice ?? this.unitCostPrice,
      unitSalePrice: unitSalePrice ?? this.unitSalePrice,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
