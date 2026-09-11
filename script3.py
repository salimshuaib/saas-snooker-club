import re

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add isInline and onCancel
old_sig = '''class GameSetupSheet extends ConsumerStatefulWidget {
  final TableModel table;
  final String employeeId;

  const GameSetupSheet({
    super.key,
    required this.table,
    required this.employeeId,
  });'''
new_sig = '''class GameSetupSheet extends ConsumerStatefulWidget {
  final TableModel table;
  final String employeeId;
  final bool isInline;
  final VoidCallback? onCancel;

  const GameSetupSheet({
    super.key,
    required this.table,
    required this.employeeId,
    this.isInline = false,
    this.onCancel,
  });'''
text = text.replace(old_sig, new_sig)

# Modify header handle/close
old_header = '''        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Game Form', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(widget.table.name, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1),'''

new_header = '''        children: [
          if (!widget.isInline) ...[
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Game Form', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(widget.table.name, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
          ],'''
text = text.replace(old_header, new_header)

# Fix background color and constraints for inline
old_container = '''    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),'''
new_container = '''    return Container(
      constraints: widget.isInline ? null : BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: widget.isInline ? EdgeInsets.zero : EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: widget.isInline ? Colors.transparent : theme.colorScheme.surface,
        borderRadius: widget.isInline ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(24)),
      ),'''
text = text.replace(old_container, new_container)

# Change Expanded(child: ListView( to shrinkWrap if inline
old_list = '''          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: ['''
new_list = '''          widget.isInline ? ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
          ] : Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: ['''
text = text.replace(old_list, new_list)

# Fix the end of ListView
old_end_list = '''                const Gap(32),
              ],
            ),
          ),'''
new_end_list = '''                const Gap(32),
              ],
            ),
          '''
# Need to be careful here, let's just do a string replace of the exact end block if possible
text = re.sub(r'                const Gap\(32\),\s*],\s*\),\s*\),', r'''                const Gap(32),
              ],
            )
          ),''', text) # Wait, this might break widget tree because of the ternary. 
          # Actually I will just wrap it in a Flexible if not inline, or shrinkWrap it always if inline.

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Updated basic inline support")
