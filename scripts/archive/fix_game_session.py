import os

def fix_game_session():
    path = 'lib/features/games/domain/models/game_models.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add fields
    old_fields = """  final double? ordersTotal;
  final double? grandTotal;
  final String? employeeId;"""
    
    new_fields = """  final double? ordersTotal;
  final double? grandTotal;
  final double? roundedAmount;
  final double? finalAmount;
  final String? employeeId;"""
    
    content = content.replace(old_fields, new_fields)

    # Add to constructor
    old_ctor = """      this.ordersTotal,
      this.grandTotal,
      this.employeeId,"""
    
    new_ctor = """      this.ordersTotal,
      this.grandTotal,
      this.roundedAmount,
      this.finalAmount,
      this.employeeId,"""
    
    content = content.replace(old_ctor, new_ctor)

    # Add to copyWith params
    old_copy_params = """      double? ordersTotal,
      double? grandTotal,
      String? employeeId,"""
      
    new_copy_params = """      double? ordersTotal,
      double? grandTotal,
      double? roundedAmount,
      double? finalAmount,
      String? employeeId,"""
      
    content = content.replace(old_copy_params, new_copy_params)

    # Add to copyWith assignments
    old_copy_assign = """        ordersTotal: ordersTotal ?? this.ordersTotal,
        grandTotal: grandTotal ?? this.grandTotal,
        employeeId: employeeId ?? this.employeeId,"""
        
    new_copy_assign = """        ordersTotal: ordersTotal ?? this.ordersTotal,
        grandTotal: grandTotal ?? this.grandTotal,
        roundedAmount: roundedAmount ?? this.roundedAmount,
        finalAmount: finalAmount ?? this.finalAmount,
        employeeId: employeeId ?? this.employeeId,"""
        
    content = content.replace(old_copy_assign, new_copy_assign)

    # Add to toMap
    old_tomap = """        'ordersTotal': ordersTotal,
        'grandTotal': grandTotal,
        'employeeId': employeeId,"""
        
    new_tomap = """        'ordersTotal': ordersTotal,
        'grandTotal': grandTotal,
        'roundedAmount': roundedAmount,
        'finalAmount': finalAmount,
        'employeeId': employeeId,"""
        
    content = content.replace(old_tomap, new_tomap)

    # Add to fromMap
    old_frommap = """        ordersTotal: (map['ordersTotal'] as num?)?.toDouble(),
        grandTotal: (map['grandTotal'] as num?)?.toDouble(),
        employeeId: map['employeeId'] as String?,"""
        
    new_frommap = """        ordersTotal: (map['ordersTotal'] as num?)?.toDouble(),
        grandTotal: (map['grandTotal'] as num?)?.toDouble(),
        roundedAmount: (map['roundedAmount'] as num?)?.toDouble(),
        finalAmount: (map['finalAmount'] as num?)?.toDouble(),
        employeeId: map['employeeId'] as String?,"""
        
    content = content.replace(old_frommap, new_frommap)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_game_session()
