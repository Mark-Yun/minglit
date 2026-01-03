import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Ticket Form**
///
/// A reusable form widget for creating and editing tickets.
/// Adheres to Minglit design system and minimalism.
class TicketForm extends StatefulWidget {
  const TicketForm({
    required this.entryGroups,
    required this.onSaved,
    required this.submitButtonLabel,
    this.initialTicket,
    this.initialQuantity,
    this.isLoading = false,
    super.key,
  });

  final List<PartyEntryGroup> entryGroups;
  final Ticket? initialTicket;
  final int? initialQuantity;
  final bool isLoading;
  final String submitButtonLabel;
  final void Function({
    required String name,
    required int price,
    required int quantity,
    required List<String> targetEntryGroupIds,
  })
  onSaved;

  @override
  State<TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<TicketForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  int _price = 0;
  int _quantity = 10;
  final Set<String> _selectedGroupIds = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    // Set initial quantity from prop or default
    if (widget.initialQuantity != null) {
      _quantity = widget.initialQuantity!;
    }

    if (widget.initialTicket != null) {
      final ticket = widget.initialTicket!;
      _nameController.text = ticket.name;
      _price = ticket.price;
      _quantity = ticket.quantity;
      _selectedGroupIds.addAll(ticket.targetEntryGroupIds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGroupIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ticket_error_minOneGroup)),
      );
      return;
    }

    widget.onSaved(
      name: _nameController.text,
      price: _price,
      quantity: _quantity,
      targetEntryGroupIds: _selectedGroupIds.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ticket Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.l10n.ticket_label_name,
              hintText: context.l10n.ticket_hint_name,
            ),
            validator: (value) => value == null || value.isEmpty
                ? context.l10n.partnerApplication_error_required
                : null,
          ),
          const SizedBox(height: MinglitSpacing.large),

          // 2. Price & Quantity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NumberStepperInput(
                  label: context.l10n.ticket_label_price,
                  value: _price,
                  step: 1000,
                  suffixText: '원',
                  onChanged: (val) => setState(() => _price = val),
                ),
              ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: NumberStepperInput(
                  label: context.l10n.ticket_label_quantity,
                  value: _quantity,
                  min: 1,
                  max: 999,
                  suffixText: '매',
                  onChanged: (val) => setState(() => _quantity = val),
                ),
              ),
            ],
          ),

          const SizedBox(height: MinglitSpacing.xlarge),

          // 3. Entry Groups Selection
          Text(
            context.l10n.ticket_label_targetGroups,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          if (widget.entryGroups.isEmpty)
            _buildEmptyGroupsState(theme)
          else
            ...widget.entryGroups.map((group) {
              final isSelected = _selectedGroupIds.contains(group.id);
              return CheckboxListTile(
                title: Text(
                  group.label ?? _getGroupSummary(group),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
                subtitle: Text(
                  _getGroupDetail(group),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: isSelected,
                activeColor: colorScheme.primary,
                onChanged: (v) {
                  setState(() {
                    if (v ?? false) {
                      _selectedGroupIds.add(group.id);
                    } else {
                      _selectedGroupIds.remove(group.id);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                visualDensity: VisualDensity.compact,
              );
            }),
          const SizedBox(height: MinglitSpacing.xlarge),

          // 4. Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.submitButtonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGroupsState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Text(context.l10n.ticket_empty_groups),
    );
  }

  String _getGroupSummary(PartyEntryGroup group) {
    final gender = group.gender == 'male'
        ? context.l10n.entryGroup_option_male
        : group.gender == 'female'
        ? context.l10n.entryGroup_option_female
        : context.l10n.entryGroup_option_any;
    return '$gender (${_getAgeText(group.birthYearRange)})';
  }

  String _getGroupDetail(PartyEntryGroup group) {
    if (group.requiredVerificationIds.isEmpty) return '추가 인증 없음';
    return '필수 인증 ${group.requiredVerificationIds.length}개';
  }

  String _getAgeText(Map<String, dynamic>? range) {
    if (range == null) return context.l10n.entryGroup_option_anyYear;
    final min = range['min'];
    final max = range['max'];
    if (min != null && max != null) return '$min~$max년생';
    if (min != null) return '$min년생~';
    if (max != null) return '~$max년생';
    return context.l10n.entryGroup_option_anyYear;
  }
}
