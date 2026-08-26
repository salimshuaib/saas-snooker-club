with open('lib/features/games/presentation/screens/manual_game_setup_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the missing brace for _startManualGame
content = content.replace("    });\n  \n  @override\n  Widget build(BuildContext context) {", "    });\n  }\n\n  @override\n  Widget build(BuildContext context) {")
content = content.replace("    });\n  @override\n  Widget build(BuildContext context) {", "    });\n  }\n\n  @override\n  Widget build(BuildContext context) {")
content = content.replace("    });\r\n  @override\r\n  Widget build(BuildContext context) {", "    });\n  }\n\n  @override\n  Widget build(BuildContext context) {")
content = content.replace("    });\r\n  \r\n  @override\r\n  Widget build(BuildContext context) {", "    });\n  }\n\n  @override\n  Widget build(BuildContext context) {")


with open('lib/features/games/presentation/screens/manual_game_setup_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
