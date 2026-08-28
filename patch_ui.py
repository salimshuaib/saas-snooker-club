path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\settings\presentation\widgets\pricing_edit_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

new_ui = '''                    const Gap(24),
                    _buildSectionHeader('PS5', Icons.gamepad, Colors.deepPurple),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour (30m)', _ps530mController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('One Hour (1h)', _ps51hController)),
                      ],
                    ),
                    const Gap(24),
                    _buildSectionHeader('PC', Icons.computer, Colors.cyan),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour (30m)', _pc30mController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('One Hour (1h)', _pc1hController)),
                      ],
                    ),
                    const Gap(24),
                    _buildSectionHeader('Carrom', Icons.crop_square, Colors.brown),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour (30m)', _carrom30mController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('One Hour (1h)', _carrom1hController)),
                      ],
                    ),
                    const Gap(24),
                    _buildSectionHeader('Foosball', Icons.sports_soccer, Colors.green),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour (30m)', _foosball30mController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('One Hour (1h)', _foosball1hController)),
                      ],
                    ),
                    const Gap(24),
                    _buildSectionHeader('Chess', Icons.extension, Colors.grey),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour (30m)', _chess30mController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('One Hour (1h)', _chess1hController)),
                      ],
                    ),
                    const Gap(24),
                  ],
                ),'''

content = content.replace('''                    const Gap(24),
                  ],
                ),''', new_ui)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
