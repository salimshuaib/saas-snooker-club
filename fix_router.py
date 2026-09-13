import os

filepath = 'lib/core/routes/app_router.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# We want to wrap from StatefulShellRoute down to the end of the routes list.
# Let's find the start of StatefulShellRoute.
start_idx = text.find('// -')
if start_idx == -1:
    start_idx = text.find('StatefulShellRoute.indexedStack(')

end_idx = text.rfind('],') # The end of the routes list of the main GoRouter

if start_idx != -1 and end_idx != -1:
    routes_str = text[start_idx:end_idx]
    
    wrapper = """      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveScaffoldWrapper(child: child);
        },
        routes: [
"""
    
    # Indent the routes_str by 2 spaces
    indented_routes = "\n".join(["  " + line for line in routes_str.split('\n')])
    
    new_text = text[:start_idx] + wrapper + indented_routes + "\n        ],\n      )" + text[end_idx:]
    
    # Add import for ResponsiveScaffoldWrapper
    if "responsive_scaffold_wrapper.dart" not in new_text:
        new_text = "import 'package:snooker_club/core/widgets/responsive_scaffold_wrapper.dart';\n" + new_text
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("SUCCESS")
else:
    print("FAILED")
