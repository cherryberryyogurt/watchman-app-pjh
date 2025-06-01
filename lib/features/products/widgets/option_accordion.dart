import 'package:flutter/material.dart';
import '../../../core/theme/index.dart';

class OptionAccordion extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final Function(String, String) onOptionSelected;
  final Map<String, String> selectedOptions;

  const OptionAccordion({
    super.key,
    required this.options,
    required this.onOptionSelected,
    required this.selectedOptions,
  });

  @override
  _OptionAccordionState createState() => _OptionAccordionState();
}

class _OptionAccordionState extends State<OptionAccordion> {
  final Map<String, bool> _expandedMap = {};

  @override
  void initState() {
    super.initState();
    // Initialize all options to collapsed state
    for (final option in widget.options) {
      final name = option['name'] as String;
      _expandedMap[name] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.options.map((option) {
        final name = option['name'] as String;
        final values = option['values'] as List<dynamic>;
        final isExpanded = _expandedMap[name] ?? false;
        final selectedValue = widget.selectedOptions[name];

        return Container(
          margin: const EdgeInsets.only(bottom: Dimensions.spacingSm),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(Dimensions.radiusSm),
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedMap[name] = !isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyles.titleSmall,
                            ),
                            if (selectedValue != null)
                              Text(
                                selectedValue,
                                style: TextStyles.bodySmall.copyWith(
                                  color: ColorPalette.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content
              if (isExpanded)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? ColorPalette.backgroundDark
                        : ColorPalette.backgroundLight,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(Dimensions.radiusSm),
                      bottomRight: Radius.circular(Dimensions.radiusSm),
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: values.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final value = values[index] as String;
                      final isSelected = selectedValue == value;
                      
                      return InkWell(
                        onTap: () {
                          widget.onOptionSelected(name, value);
                          setState(() {
                            _expandedMap[name] = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                value,
                                style: isSelected
                                    ? TextStyles.bodyMedium.copyWith(
                                        color: ColorPalette.primary,
                                        fontWeight: FontWeight.bold,
                                      )
                                    : TextStyles.bodyMedium,
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check,
                                  color: ColorPalette.primary,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 