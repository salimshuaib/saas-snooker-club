import os

filepath = 'lib/features/dashboard/presentation/screens/main_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """    return Scaffold(
      extendBody: false,
      body: widget.navigationShell,
      bottomNavigationBar: SafeArea("""

new_code = """    final isDesktop = MediaQuery.sizeOf(context).width > 800;
    return Scaffold(
      extendBody: false,
      body: widget.navigationShell,
      bottomNavigationBar: isDesktop ? null : SafeArea("""

if old_code in text:
    text = text.replace(old_code, new_code)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS")
else:
    print("FAILED TO FIND MAIN_SCREEN CODE BLOCK")
