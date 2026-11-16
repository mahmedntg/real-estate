import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import 'labels.dart';

class GovernorateAutocomplete extends StatefulWidget {
  const GovernorateAutocomplete({
    super.key,
    required this.governorates,
    required this.selected,
    required this.label,
    required this.hint,
    required this.clearTooltip,
    required this.onChanged,
  });

  final List<Governorate> governorates;
  final String? selected;
  final String label;
  final String hint;
  final String clearTooltip;
  final ValueChanged<String?> onChanged;

  @override
  State<GovernorateAutocomplete> createState() =>
      _GovernorateAutocompleteState();
}

class _GovernorateAutocompleteState extends State<GovernorateAutocomplete> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _controller.text = _labelFor(widget.selected);
    }
  }

  @override
  void didUpdateWidget(GovernorateAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      final text = _labelFor(widget.selected);
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _labelFor(String? code) {
    if (code == null) {
      return '';
    }
    for (final governorate in widget.governorates) {
      if (governorate.code == code) {
        return governorateLabel(context, governorate, code);
      }
    }
    return code;
  }

  void _clear() {
    _controller.clear();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<Governorate>(
        textEditingController: _controller,
        focusNode: _focusNode,
        displayStringForOption: (option) =>
            governorateLabel(context, option, option.code),
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          if (query.isEmpty) {
            return widget.governorates;
          }
          return widget.governorates.where(
            (governorate) => governorateLabel(context, governorate, governorate.code)
                .toLowerCase()
                .contains(query),
          );
        },
        onSelected: (option) => widget.onChanged(option.code),
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.location_city_outlined),
            suffixIcon: widget.selected == null
                ? null
                : IconButton(
                    tooltip: widget.clearTooltip,
                    onPressed: _clear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(
                        governorateLabel(context, option, option.code),
                      ),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
