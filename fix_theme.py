def fix_theme():
    with open('lib/features/team/presentation/screens/team_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # We need to add `final theme = Theme.of(context);` in `_TeamMemberCard.build`
    target = """  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentStaffProvider).value?.id;"""
    replacement = """  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUid = ref.watch(currentStaffProvider).value?.id;"""
    if "final theme = Theme.of(context);" not in content:
        content = content.replace(target, replacement)
    
    with open('lib/features/team/presentation/screens/team_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_theme()
    print("Done")
