import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

class NumberStepperInput extends StatefulWidget {
  const NumberStepperInput({
    required this.value,
    required this.onChanged,
    this.label,
    this.min = 0,
    this.max = 999999,
    this.step = 1,
    this.suffixText,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String? label;
  final int min;
  final int max;
  final int step;
  final String? suffixText;

  @override
  State<NumberStepperInput> createState() => _NumberStepperInputState();
}

class _NumberStepperInputState extends State<NumberStepperInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant NumberStepperInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (_controller.text != widget.value.toString()) {
        _controller.text = widget.value.toString();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateValue(int newValue) {
    if (newValue < widget.min || newValue > widget.max) return;
    widget.onChanged(newValue);
  }

  void _onFieldSubmitted(String value) {
    final intValue = int.tryParse(value);
    if (intValue == null) {
      _controller.text = widget.value.toString();
      return;
    }
    final clamped = intValue.clamp(widget.min, widget.max);
    _updateValue(clamped);
    _controller.text = clamped.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(MinglitRadius.input),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: widget.value > widget.min
                    ? () => _updateValue(widget.value - widget.step)
                    : null,
              ),
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                    suffixText: widget.suffixText,
                    suffixStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  onChanged: (val) {},
                  onFieldSubmitted: _onFieldSubmitted,
                  onTapOutside: (_) => _onFieldSubmitted(_controller.text),
                ),
              ),
              _StepperButton(
                icon: Icons.add,
                onTap: widget.value < widget.max
                    ? () => _updateValue(widget.value + widget.step)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = onTap == null;

    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: isDisabled
            ? colorScheme.outlineVariant
            : colorScheme.onSurfaceVariant,
        size: 20,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(40, 40),
      ),
    );
  }
}
