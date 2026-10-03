import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';

class PlayerSelection {
  final String? id;
  final String name;
  const PlayerSelection({this.id, required this.name});
}

class PlayerSearchField extends ConsumerStatefulWidget {
  final String hint;
  final PlayerSelection? initialSelection;
  final ValueChanged<PlayerSelection> onSelected;

  const PlayerSearchField({
    super.key,
    required this.hint,
    this.initialSelection,
    required this.onSelected,
  });

  @override
  ConsumerState<PlayerSearchField> createState() => _PlayerSearchFieldState();
}

class _PlayerSearchFieldState extends ConsumerState<PlayerSearchField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allProfiles = ref.watch(allCustomersProvider).value ?? [];

    return Autocomplete<PlayerProfile>(
      initialValue: TextEditingValue(text: widget.initialSelection?.name ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return allProfiles;
        }
        final query = textEditingValue.text.toLowerCase();
        return allProfiles.where((PlayerProfile profile) {
          final matchesName = profile.name.toLowerCase().contains(query);
          final matchesPhone =
              profile.mobileNumber != null &&
              profile.mobileNumber!.contains(query);
          return matchesName || matchesPhone;
        });
      },
      displayStringForOption: (PlayerProfile option) => option.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        String lastText = controller.text;
        controller.addListener(() {
          if (lastText != controller.text) {
            lastText = controller.text;
            widget.onSelected(PlayerSelection(name: controller.text));
          }
        });

        focusNode.addListener(() {
          if (focusNode.hasFocus && controller.text.toLowerCase().startsWith('default')) {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          }
        });

        return TextField(
          controller: controller,
          focusNode: focusNode,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
          ],
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final PlayerProfile option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.name),
                    subtitle: option.mobileNumber != null
                        ? Text('📱 ${option.mobileNumber}')
                        : const Text('📱 Number not available'),
                    onTap: () {
                      onSelected(option);
                      widget.onSelected(
                        PlayerSelection(id: option.id, name: option.name),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (PlayerProfile selection) {
        widget.onSelected(
          PlayerSelection(id: selection.id, name: selection.name),
        );
      },
    );
  }
}
