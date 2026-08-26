import os
import re

def fix_player_search():
    path = 'lib/features/credit/presentation/widgets/player_search_field.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The issue is the text controller listener firing and clearing the ID
    # We should only update the name if the text actually changed
    old_listener = """      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.addListener(() {
           widget.onSelected(PlayerSelection(name: controller.text));
        });"""
        
    new_listener = """      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        String lastText = controller.text;
        controller.addListener(() {
           if (lastText != controller.text) {
             lastText = controller.text;
             widget.onSelected(PlayerSelection(name: controller.text));
           }
        });"""
        
    content = content.replace(old_listener, new_listener)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_player_search()
