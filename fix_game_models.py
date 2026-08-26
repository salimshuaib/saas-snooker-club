import os

def fix_game_session_missing():
    path = 'lib/features/games/domain/models/game_models.dart'
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # Add to constructor
    c = c.replace(
        "    this.grandTotal,\n    this.employeeId,",
        "    this.grandTotal,\n    this.roundedAmount,\n    this.finalAmount,\n    this.employeeId,"
    )
    
    # Add to copyWith
    c = c.replace(
        "    double? grandTotal,\n    String? employeeId,",
        "    double? grandTotal,\n    double? roundedAmount,\n    double? finalAmount,\n    String? employeeId,"
    )
    
    c = c.replace(
        "      grandTotal: grandTotal ?? this.grandTotal,\n      employeeId: employeeId ?? this.employeeId,",
        "      grandTotal: grandTotal ?? this.grandTotal,\n      roundedAmount: roundedAmount ?? this.roundedAmount,\n      finalAmount: finalAmount ?? this.finalAmount,\n      employeeId: employeeId ?? this.employeeId,"
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

fix_game_session_missing()
