import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/widgets/address_search_dialog.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step3ContactSettlement extends ConsumerStatefulWidget {
  const Step3ContactSettlement({super.key});

  @override
  ConsumerState<Step3ContactSettlement> createState() =>
      _Step3ContactSettlementState();
}

class _Step3ContactSettlementState
    extends ConsumerState<Step3ContactSettlement> {
  final _roadAddressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _roadAddressController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  void _initFromState(String savedAddress) {
    if (_initialized) return;
    _initialized = true;
    // On first load, treat the entire saved address as the road address.
    _roadAddressController.text = savedAddress;
  }

  String get _combinedAddress {
    final road = _roadAddressController.text.trim();
    final detail = _detailAddressController.text.trim();
    if (road.isEmpty) return '';
    if (detail.isEmpty) return road;
    return '$road $detail';
  }

  Future<void> _openAddressSearch(
    BuildContext context,
    PartnerApplyController notifier,
  ) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const AddressSearchDialog(),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _roadAddressController.text = selected;
    });
    notifier.updateField('address', _combinedAddress);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnerApplyControllerProvider);
    final notifier = ref.read(partnerApplyControllerProvider.notifier);
    final theme = Theme.of(context);

    _initFromState(state.address);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.partnerApplication_field_phone,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.contactPhone,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_phone,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (val) => notifier.updateField('contactPhone', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            context.l10n.partnerApplication_field_email,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.contactEmail,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_email,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) => notifier.updateField('contactEmail', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            '사업자 등록 주소',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          // 도로명주소 필드 (readOnly, 탭 → 검색 다이얼로그)
          TextFormField(
            controller: _roadAddressController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_address,
              suffixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onTap: () => _openAddressSearch(context, notifier),
          ),
          const SizedBox(height: MinglitSpacing.small),
          // 상세주소 필드 (동/층/호, 선택사항)
          TextFormField(
            controller: _detailAddressController,
            enabled: _roadAddressController.text.isNotEmpty,
            decoration: InputDecoration(
              hintText: '상세주소 입력 (동/층/호)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onChanged: (_) => notifier.updateField('address', _combinedAddress),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '등록된 주소는 파트너 정보에 공개됩니다',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            context.l10n.partnerApplication_field_bankName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.bankName,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_bankName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onChanged: (val) => notifier.updateField('bankName', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            context.l10n.partnerApplication_field_accountNum,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.accountNumber,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_accountNum,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) => notifier.updateField('accountNumber', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            context.l10n.partnerApplication_field_holder,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.accountHolder,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_field_holder,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onChanged: (val) => notifier.updateField('accountHolder', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            '세금계산서 수신 이메일',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.taxEmail,
            decoration: InputDecoration(
              hintText: '이메일 주소를 입력해주세요 (선택)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) => notifier.updateField('taxEmail', val),
          ),
        ],
      ),
    );
  }
}
