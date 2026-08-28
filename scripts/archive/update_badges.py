path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\settings\presentation\screens\settings_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTableCountBadge('Snooker', tables.where((t) => t.type == TableType.snooker).length, Colors.red, context),
                    _buildTableCountBadge('Indian Pool', tables.where((t) => t.type == TableType.indianPool).length, Colors.amber, context),
                    _buildTableCountBadge('American Pool', tables.where((t) => t.type == TableType.americanPool).length, Colors.blue, context),
                  ],
                ),''', '''                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTableCountBadge('Snooker', tables.where((t) => t.type == TableType.snooker).length, Colors.red, context),
                    _buildTableCountBadge('Indian Pool', tables.where((t) => t.type == TableType.indianPool).length, Colors.amber, context),
                    _buildTableCountBadge('American Pool', tables.where((t) => t.type == TableType.americanPool).length, Colors.blue, context),
                    _buildTableCountBadge('PS5', tables.where((t) => t.type == TableType.ps5).length, Colors.deepPurple, context),
                    _buildTableCountBadge('PC', tables.where((t) => t.type == TableType.pc).length, Colors.cyan, context),
                    _buildTableCountBadge('Carrom', tables.where((t) => t.type == TableType.carrom).length, Colors.brown, context),
                    _buildTableCountBadge('Foosball', tables.where((t) => t.type == TableType.foosball).length, Colors.green, context),
                    _buildTableCountBadge('Chess', tables.where((t) => t.type == TableType.chess).length, Colors.grey, context),
                  ],
                ),''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
