path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\settings\presentation\screens\settings_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''                ),
                const Gap(8),
              ],
            ),''', '''                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourceManagementScreen()));
                    },
                    icon: const Icon(Icons.settings_suggest),
                    label: const Text('Manage Games & Tables'),
                  ),
                ),
                const Gap(8),
              ],
            ),''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
