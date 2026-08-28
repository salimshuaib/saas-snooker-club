import os

def fix_pricing_edit_sheet():
    path = 'lib/features/settings/presentation/widgets/pricing_edit_sheet.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add controllers
    old_controllers = """  late TextEditingController _apFrameController;
  late TextEditingController _apMinController;
  late TextEditingController _apHalfController;
  late TextEditingController _apHourController;"""
    
    new_controllers = """  late TextEditingController _apFrameController;
  late TextEditingController _apMinController;
  late TextEditingController _apHalfController;
  late TextEditingController _apHourController;
  
  late TextEditingController _snookerRaceController;
  late TextEditingController _ipRaceController;
  late TextEditingController _apRaceController;
  late TextEditingController _snookerRummyController;"""
    
    content = content.replace(old_controllers, new_controllers)
    
    # 2. Init controllers
    old_init = """    _apFrameController = TextEditingController(text: widget.initialSettings.americanPoolPerFrame.toStringAsFixed(2));
    _apMinController = TextEditingController(text: widget.initialSettings.americanPoolPerMinute.toStringAsFixed(2));
    _apHalfController = TextEditingController(text: widget.initialSettings.americanPoolHalfHour.toStringAsFixed(2));
    _apHourController = TextEditingController(text: widget.initialSettings.americanPoolOneHour.toStringAsFixed(2));"""
    
    new_init = """    _apFrameController = TextEditingController(text: widget.initialSettings.americanPoolPerFrame.toStringAsFixed(2));
    _apMinController = TextEditingController(text: widget.initialSettings.americanPoolPerMinute.toStringAsFixed(2));
    _apHalfController = TextEditingController(text: widget.initialSettings.americanPoolHalfHour.toStringAsFixed(2));
    _apHourController = TextEditingController(text: widget.initialSettings.americanPoolOneHour.toStringAsFixed(2));
    
    _snookerRaceController = TextEditingController(text: widget.initialSettings.snookerRacePerMinute.toStringAsFixed(2));
    _ipRaceController = TextEditingController(text: widget.initialSettings.indianPoolRacePerMinute.toStringAsFixed(2));
    _apRaceController = TextEditingController(text: widget.initialSettings.americanPoolRacePerMinute.toStringAsFixed(2));
    _snookerRummyController = TextEditingController(text: widget.initialSettings.snookerRummyPerMinute.toStringAsFixed(2));"""
    
    content = content.replace(old_init, new_init)
    
    # 3. Dispose controllers
    old_dispose = """    _apFrameController.dispose();
    _apMinController.dispose();
    _apHalfController.dispose();
    _apHourController.dispose();
    super.dispose();"""
    
    new_dispose = """    _apFrameController.dispose();
    _apMinController.dispose();
    _apHalfController.dispose();
    _apHourController.dispose();
    _snookerRaceController.dispose();
    _ipRaceController.dispose();
    _apRaceController.dispose();
    _snookerRummyController.dispose();
    super.dispose();"""
    
    content = content.replace(old_dispose, new_dispose)
    
    # 4. Save values
    old_save = """        americanPoolPerMinute: double.tryParse(_apMinController.text.trim()) ?? 4.00,
        americanPoolHalfHour: double.tryParse(_apHalfController.text.trim()) ?? 150.00,
        americanPoolOneHour: double.tryParse(_apHourController.text.trim()) ?? 240.00,
      );"""
      
    new_save = """        americanPoolPerMinute: double.tryParse(_apMinController.text.trim()) ?? 4.00,
        americanPoolHalfHour: double.tryParse(_apHalfController.text.trim()) ?? 150.00,
        americanPoolOneHour: double.tryParse(_apHourController.text.trim()) ?? 240.00,
        snookerRacePerMinute: double.tryParse(_snookerRaceController.text.trim()) ?? 3.00,
        indianPoolRacePerMinute: double.tryParse(_ipRaceController.text.trim()) ?? 3.00,
        americanPoolRacePerMinute: double.tryParse(_apRaceController.text.trim()) ?? 4.00,
        snookerRummyPerMinute: double.tryParse(_snookerRummyController.text.trim()) ?? 4.00,
      );"""
      
    content = content.replace(old_save, new_save)
    
    # 5. UI elements
    # I need to insert them under the respective sections.
    # Snooker Section
    old_snooker = """                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour', _snookerHalfController)),
                        const Gap(16),
                        Expanded(child: _buildTextField('One Hour', _snookerHourController)),
                      ],
                    ),
                    const Divider(height: 32),"""
                    
    new_snooker = """                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour', _snookerHalfController)),
                        const Gap(16),
                        Expanded(child: _buildTextField('One Hour', _snookerHourController)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Race (Per Min)', _snookerRaceController)),
                        const Gap(16),
                        Expanded(child: _buildTextField('Rummy (Per Min)', _snookerRummyController)),
                      ],
                    ),
                    const Divider(height: 32),"""
                    
    content = content.replace(old_snooker, new_snooker)
    
    # Indian Pool Section
    old_indian_pool = """                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour', _ipHalfController)),
                        const Gap(16),
                        Expanded(child: _buildTextField('One Hour', _ipHourController)),
                      ],
                    ),
                    const Divider(height: 32),"""
                    
    new_indian_pool = """                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour', _ipHalfController)),
                        const Gap(16),
                        Expanded(child: _buildTextField('One Hour', _ipHourController)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Race (Per Min)', _ipRaceController)),
                        const Gap(16),
                        Expanded(child: SizedBox()),
                      ],
                    ),
                    const Divider(height: 32),"""
                    
    content = content.replace(old_indian_pool, new_indian_pool)
    
    # American Pool Section
    old_american_pool = """                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour', _apHalfController)),
                        const Gap(16),
                        Expanded(child: _buildTextField('One Hour', _apHourController)),
                      ],
                    ),
                  ],"""
                  
    new_american_pool = """                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour', _apHalfController)),
                        const Gap(16),
                        Expanded(child: _buildTextField('One Hour', _apHourController)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Race (Per Min)', _apRaceController)),
                        const Gap(16),
                        Expanded(child: SizedBox()),
                      ],
                    ),
                  ],"""
                  
    content = content.replace(old_american_pool, new_american_pool)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_pricing_edit_sheet()
