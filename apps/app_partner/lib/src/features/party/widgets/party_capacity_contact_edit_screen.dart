import 'package:app_partner/src/features/party/widgets/party_capacity_input.dart';
import 'package:app_partner/src/features/party/widgets/party_contact_input.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCapacityContactEditScreen extends StatefulWidget {
  const PartyCapacityContactEditScreen({
    required this.party,
    required this.onSave,
    super.key,
  });

  final Party party;
  final void Function(
    int minCount,
    int maxCount,
    Map<String, String> contactOptions,
  ) onSave;

  @override
  State<PartyCapacityContactEditScreen> createState() =>
      _PartyCapacityContactEditScreenState();
}

class _PartyCapacityContactEditScreenState
    extends State<PartyCapacityContactEditScreen> {
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _kakaoController;
  late int _minCount;
  late int _maxCount;
  late Set<String> _enabledMethods;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.party.contactOptions['phone'] as String?,
    );
    _emailController = TextEditingController(
      text: widget.party.contactOptions['email'] as String?,
    );
    _kakaoController = TextEditingController(
      text: widget.party.contactOptions['kakao_open_chat'] as String?,
    );
    _minCount = widget.party.minConfirmedCount;
    _maxCount = widget.party.maxParticipants;
    _enabledMethods = Set<String>.from(
      widget.party.contactOptions.keys.map((k) {
        if (k == 'kakao_open_chat') return 'kakao';
        return k;
      }),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _kakaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '인원 및 연락처 수정'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Capacity Section
            Text(
              context.l10n.partyCreate_label_capacity,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            PartyCapacityInput(
              minCount: _minCount,
              maxCount: _maxCount,
              onMinChanged: (val) => setState(() => _minCount = val),
            ),
            const SizedBox(height: MinglitSpacing.xlarge),

            // 2. Contact Section
            Text(
              context.l10n.partyCreate_label_contact,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            PartyContactInput(
              phoneController: _phoneController,
              emailController: _emailController,
              kakaoController: _kakaoController,
              enabledMethods: _enabledMethods,
              onToggleMethod: (method) {
                setState(() {
                  if (_enabledMethods.contains(method)) {
                    _enabledMethods.remove(method);
                  } else {
                    _enabledMethods.add(method);
                  }
                });
              },
            ),
            const SizedBox(height: MinglitSpacing.xlarge),

            ElevatedButton(
              onPressed: () {
                final options = <String, String>{};
                if (_enabledMethods.contains('phone')) {
                  options['phone'] = _phoneController.text;
                }
                if (_enabledMethods.contains('email')) {
                  options['email'] = _emailController.text;
                }
                if (_enabledMethods.contains('kakao')) {
                  options['kakao_open_chat'] = _kakaoController.text;
                }

                widget.onSave(_minCount, _maxCount, options);
                Navigator.pop(context);
              },
              child: Text(context.l10n.common_button_save),
            ),
            const SizedBox(height: MinglitSpacing.large),
          ],
        ),
      ),
    );
  }
}
