import re
import os

def modify_model(file_path, class_name):
    if not os.path.exists(file_path):
        print(f"Not found: {file_path}")
        return
        
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Skip if already added
    if 'createdByUserId' in content:
        return

    # Add fields to class definition
    class_def_target = f"class {class_name} {{"
    fields = """
  final String? createdByUserId;
  final String? createdByName;
  final String? updatedByUserId;
  final String? updatedByName;"""
    if class_def_target in content:
        content = content.replace(class_def_target, class_def_target + fields)

    # Add to constructor
    constructor_target = f"    required this.id,"
    constructor_fields = """    this.createdByUserId,
    this.createdByName,
    this.updatedByUserId,
    this.updatedByName,"""
    # Find the main constructor
    c_idx = content.find(f"  const {class_name}({{")
    if c_idx == -1: c_idx = content.find(f"  {class_name}({{")
    if c_idx != -1:
        req_id_idx = content.find(constructor_target, c_idx)
        if req_id_idx != -1:
            content = content[:req_id_idx] + constructor_fields + "\n" + content[req_id_idx:]
        else:
            print("Could not find required this.id in constructor")

    # Add to toMap
    tomap_target = f"    return {{"
    tomap_idx = content.find("Map<String, dynamic> toMap() {")
    if tomap_idx != -1:
        rtn_idx = content.find(tomap_target, tomap_idx)
        if rtn_idx != -1:
            tomap_fields = """      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'updatedByUserId': updatedByUserId,
      'updatedByName': updatedByName,"""
            content = content[:rtn_idx+len(tomap_target)] + "\n" + tomap_fields + content[rtn_idx+len(tomap_target):]

    # Add to fromMap
    frommap_target = "id: "
    frommap_idx = content.find(f"factory {class_name}.fromMap(")
    if frommap_idx != -1:
        id_idx = content.find(frommap_target, frommap_idx)
        if id_idx != -1:
            frommap_fields = """      createdByUserId: map['createdByUserId'] as String?,
      createdByName: map['createdByName'] as String?,
      updatedByUserId: map['updatedByUserId'] as String?,
      updatedByName: map['updatedByName'] as String?,"""
            content = content[:id_idx] + frommap_fields + "\n" + "      " + content[id_idx:]

    # Add to copyWith
    copywith_target = "String? id,"
    copywith_idx = content.find("copyWith({")
    if copywith_idx != -1:
        id_idx = content.find(copywith_target, copywith_idx)
        if id_idx != -1:
            copywith_fields = """    String? createdByUserId,
    String? createdByName,
    String? updatedByUserId,
    String? updatedByName,"""
            content = content[:id_idx] + copywith_fields + "\n" + "    " + content[id_idx:]
            
        ret_id_idx = content.find("id: id ?? this.id,", copywith_idx)
        if ret_id_idx != -1:
            ret_fields = """      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      updatedByName: updatedByName ?? this.updatedByName,"""
            content = content[:ret_id_idx] + ret_fields + "\n" + "      " + content[ret_id_idx:]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_model('lib/features/games/domain/models/game_models.dart', 'GameSession')
    modify_model('lib/features/quick_sales/domain/models/quick_sale_models.dart', 'QuickSale')
    print("Done")
