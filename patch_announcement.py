import re

with open('lib/features/announcements/presentation/widgets/announcements_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add currentStaffId at the top of build
content = content.replace(
    "final theme = Theme.of(context);",
    "final theme = Theme.of(context);\n    final currentStaffId = ref.watch(currentStaffProvider).value?.id;"
)

# Replace the itemBuilder inside ListView.separated
new_item_builder = """                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    final isMe = announcement.senderId == currentStaffId;
                    
                    final dateStr = DateFormat('dd MMM').format(announcement.createdAt);
                    final timeStr = DateFormat('hh:mm a').format(announcement.createdAt);
                    final timestamp = '\'; // WhatsApp usually just shows time for today, but let's keep it simple

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          left: isMe ? 48.0 : 0.0,
                          right: isMe ? 0.0 : 48.0,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  announcement.senderName,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            Text(
                              announcement.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                            ),
                            const Gap(4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '\, \',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isMe
                                      ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },"""

# Regex to find the old itemBuilder
pattern = re.compile(r"itemBuilder:\s*\(context,\s*index\)\s*\{[\s\S]*?\},", re.MULTILINE)
content = pattern.sub(new_item_builder + ",", content, count=1)

with open('lib/features/announcements/presentation/widgets/announcements_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)
