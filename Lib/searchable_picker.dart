import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const String searchPickerAddSentinel = '__search_picker_add__';

typedef SearchPickerOptionBuilder =
    Widget Function(BuildContext context, String option);

class SearchablePickerField extends StatelessWidget {
  const SearchablePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.searchHint = 'Type to search',
    this.addLabel,
    this.optionBuilder,
    this.emptyMessage = 'No matches found.',
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final String searchHint;
  final String? addLabel;
  final SearchPickerOptionBuilder? optionBuilder;
  final String emptyMessage;

  Future<void> _open(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _SearchPickerDialog(
        title: label,
        options: options,
        value: value,
        searchHint: searchHint,
        addLabel: addLabel,
        optionBuilder: optionBuilder,
        emptyMessage: emptyMessage,
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        ),
        isEmpty: value.isEmpty,
        child: Text(
          value.isEmpty ? 'Select $label' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: value.isEmpty ? const Color(0xFF94A3B8) : null,
          ),
        ),
      ),
    );
  }
}

class _SearchPickerDialog extends StatefulWidget {
  const _SearchPickerDialog({
    required this.title,
    required this.options,
    required this.value,
    required this.searchHint,
    required this.emptyMessage,
    this.addLabel,
    this.optionBuilder,
  });

  final String title;
  final List<String> options;
  final String value;
  final String searchHint;
  final String? addLabel;
  final SearchPickerOptionBuilder? optionBuilder;
  final String emptyMessage;

  @override
  State<_SearchPickerDialog> createState() => _SearchPickerDialogState();
}

class _SearchPickerDialogState extends State<_SearchPickerDialog> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _matches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options
        .where((option) => option.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final list = matches.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text(
                widget.emptyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF64748B)),
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final option = matches[index];
              final isSelected = option == widget.value;
              return ListTile(
                key: ValueKey('search-picker-option-$option'),
                dense: true,
                selected: isSelected,
                selectedTileColor: const Color(0xFFEFF6FF),
                title: widget.optionBuilder == null
                    ? Text(option)
                    : widget.optionBuilder!(context, option),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Color(0xFF2563EB),
                      )
                    : null,
                onTap: () => Navigator.pop(context, option),
              );
            },
          );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('search-picker-field'),
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() {
                            _controller.clear();
                            _query = '';
                          }),
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: widget.addLabel == null
                    ? list
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            key: const Key('search-picker-add'),
                            leading: const Icon(Icons.add_rounded),
                            title: Text(
                              widget.addLabel!,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            onTap: () =>
                                Navigator.pop(context, searchPickerAddSentinel),
                          ),
                          Flexible(child: list),
                        ],
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                'Keep typing to filter. The newest match stays in reach.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
