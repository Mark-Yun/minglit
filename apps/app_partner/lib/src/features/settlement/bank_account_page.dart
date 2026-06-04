import 'dart:async' show unawaited;

import 'package:app_partner/src/features/settlement/bank_catalog.dart';
import 'package:app_partner/src/features/settlement/settlement_coordinator.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/logic/dashboard_refresh_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minglit_kit/minglit_kit.dart';

const _bankStatusNotStarted = 'not_started';
const _bankStatusFailed = 'verification_failed';
const _bankStatusPending = 'manual_review_pending';
const _bankStatusManualApproved = 'manual_review_approved';
const _bankStatusVerified = 'verified';

String _bankStatus(Map<String, dynamic>? accountData) {
  return accountData?['bank_verification_status'] as String? ??
      _bankStatusNotStarted;
}

class BankAccountPage extends ConsumerStatefulWidget {
  const BankAccountPage({super.key});

  @override
  ConsumerState<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends ConsumerState<BankAccountPage> {
  Map<String, dynamic>? _accountData;
  bool _isLoading = true;
  bool _isRequestingManualReview = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAccount());
  }

  Future<void> _loadAccount() async {
    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final repo = ref.read(settlementRepositoryProvider);
      final data = await repo.getBankAccount(partner.id);
      if (mounted) {
        setState(() {
          _accountData = data;
          _isLoading = false;
        });
      }
      // Fix #459: 계좌 로딩 실패 시 에러 로깅 추가 — 프로덕션 장애 추적 불가 방지
    } on Exception catch (e, st) {
      Log.e('[BankAccountPage] _loadAccount failed', e, st);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSaved() async {
    await _loadAccount();
    ref.read(dashboardRefreshProvider.notifier).bump();
  }

  Future<void> _requestManualReview() async {
    setState(() => _isRequestingManualReview = true);
    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) return;
      await ref
          .read(settlementRepositoryProvider)
          .requestManualBankAccountReview(partnerId: partner.id);
      await _handleSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수동 검증 요청이 접수되었습니다.')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수동 검증 요청 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRequestingManualReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('계좌 관리')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountCard(
                    accountData: _accountData,
                    isRequestingManualReview: _isRequestingManualReview,
                    onRequestManualReview: _requestManualReview,
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  AccountEditForm(
                    accountData: _accountData,
                    onSaved: () => unawaited(_handleSaved()),
                  ),
                ],
              ),
            ),
    );
  }
}

class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.accountData,
    required this.isRequestingManualReview,
    required this.onRequestManualReview,
    super.key,
  });
  final Map<String, dynamic>? accountData;
  final bool isRequestingManualReview;
  final VoidCallback onRequestManualReview;

  @override
  Widget build(BuildContext context) {
    if (accountData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(MinglitSpacing.medium),
          child: Text('등록된 계좌 정보가 없습니다.'),
        ),
      );
    }
    final bankName = accountData!['bank_name'] as String? ?? '-';
    final holder = accountData!['account_holder'] as String? ?? '-';
    final number = accountData!['account_number'] as String? ?? '';
    final status = _bankStatus(accountData);
    final masked = number.length > 4
        ? '${'*' * (number.length - 4)}${number.substring(number.length - 4)}'
        : number;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 계좌', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: MinglitSpacing.sm),
            _InfoRow('은행', bankName),
            _InfoRow('예금주', holder),
            _InfoRow('계좌번호', masked),
            _InfoRow('확인 상태', _statusLabel(status)),
            const SizedBox(height: MinglitSpacing.sm),
            _BankStatusCallout(
              status: status,
              isRequestingManualReview: isRequestingManualReview,
              onRequestManualReview: onRequestManualReview,
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case _bankStatusVerified:
      return '확인 완료';
    case _bankStatusManualApproved:
      return '운영 확인 완료';
    case _bankStatusFailed:
      return '확인 실패';
    case _bankStatusPending:
      return '확인 중';
    case _bankStatusNotStarted:
    default:
      return '미확인';
  }
}

class _BankStatusCallout extends StatelessWidget {
  const _BankStatusCallout({
    required this.status,
    required this.isRequestingManualReview,
    required this.onRequestManualReview,
  });

  final String status;
  final bool isRequestingManualReview;
  final VoidCallback onRequestManualReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReady =
        status == _bankStatusVerified || status == _bankStatusManualApproved;
    final isFailed = status == _bankStatusFailed;
    final color = isReady
        ? MinglitColors.success
        : isFailed
        ? colorScheme.error
        : colorScheme.primary;
    final title = isReady
        ? '정산 받을 계좌로 확인되었습니다.'
        : isFailed
        ? '계좌 정보를 다시 확인해주세요.'
        : '운영팀이 계좌를 확인 중입니다.';
    final body = isReady
        ? '다음 정산부터 이 계좌 정보가 사용됩니다.'
        : isFailed
        ? '은행, 계좌번호, 예금주를 수정해 다시 저장하거나 수동 검증을 요청할 수 있습니다.'
        : '확인이 끝나기 전까지 PartnerHome의 계좌 todo는 유지됩니다.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MinglitSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: MinglitOpacity.tintFill),
        border: Border.all(
          color: color.withValues(alpha: MinglitOpacity.subtle),
        ),
        borderRadius: BorderRadius.circular(MinglitRadius.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReady
                    ? Icons.check_circle_outline
                    : isFailed
                    ? Icons.error_outline
                    : Icons.hourglass_top_outlined,
                color: color,
                size: MinglitIconSize.small,
              ),
              const SizedBox(width: MinglitSpacing.xsmall),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (isFailed) ...[
            const SizedBox(height: MinglitSpacing.small),
            OutlinedButton.icon(
              onPressed: isRequestingManualReview
                  ? null
                  : onRequestManualReview,
              icon: isRequestingManualReview
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.support_agent_outlined),
              label: Text(isRequestingManualReview ? '요청 중...' : '수동 검증 요청'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xsmall),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class AccountEditForm extends ConsumerStatefulWidget {
  const AccountEditForm({
    required this.onSaved,
    super.key,
    this.accountData,
  });
  final Map<String, dynamic>? accountData;
  final VoidCallback onSaved;

  @override
  ConsumerState<AccountEditForm> createState() => _AccountEditFormState();
}

class _AccountEditFormState extends ConsumerState<AccountEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankCtrl;
  late final TextEditingController _holderCtrl;
  late final TextEditingController _numberCtrl;
  BankOption? _selectedBank;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bankCtrl = TextEditingController();
    _holderCtrl = TextEditingController();
    _numberCtrl = TextEditingController();
    _syncFromAccountData();
  }

  @override
  void didUpdateWidget(covariant AccountEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountData != widget.accountData) {
      _syncFromAccountData();
    }
  }

  void _syncFromAccountData() {
    _selectedBank =
        bankOptionByCode(widget.accountData?['bank_code'] as String?) ??
        bankOptionByName(widget.accountData?['bank_name'] as String?);
    _bankCtrl.text =
        _selectedBank?.name ??
        (widget.accountData?['bank_name'] as String? ?? '');
    _holderCtrl.text = widget.accountData?['account_holder'] as String? ?? '';
    _numberCtrl.text = widget.accountData?['account_number'] as String? ?? '';
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _holderCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _showBankSheet() async {
    final selected = await showMinglitBottomSheet<BankOption>(
      context: context,
      title: '은행 선택',
      isScrollControlled: true,
      padding: const EdgeInsets.only(
        left: MinglitSpacing.small,
        right: MinglitSpacing.small,
        bottom: MinglitSpacing.medium,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...partnerBankCatalog.map(
              (bank) => MinglitListTile(
                title: bank.name,
                trailing: _selectedBank?.code == bank.code
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(bank),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedBank = selected;
      _bankCtrl.text = selected.name;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bank = _selectedBank;
    if (bank == null) return;
    setState(() => _isSaving = true);
    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) return;
      final repo = ref.read(settlementRepositoryProvider);
      await repo.upsertBankAccount(
        partnerId: partner.id,
        bankCode: bank.code,
        bankName: bank.name,
        accountHolder: _holderCtrl.text.trim(),
        accountNumber: _numberCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계좌 확인 요청이 접수되었습니다.')),
      );
      widget.onSaved();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.accountData == null ? '계좌 등록' : '계좌 수정',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: MinglitSpacing.sm),
              TextFormField(
                controller: _bankCtrl,
                readOnly: true,
                onTap: _isSaving ? null : _showBankSheet,
                decoration: const InputDecoration(
                  labelText: '은행 선택',
                  suffixIcon: Icon(Icons.expand_more),
                ),
                validator: (_) => _selectedBank == null ? '은행을 선택해 주세요.' : null,
              ),
              const SizedBox(height: MinglitSpacing.small),
              TextFormField(
                controller: _holderCtrl,
                decoration: const InputDecoration(labelText: '예금주'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '예금주를 입력해 주세요.' : null,
              ),
              const SizedBox(height: MinglitSpacing.small),
              TextFormField(
                controller: _numberCtrl,
                decoration: const InputDecoration(labelText: '계좌번호'),
                keyboardType: TextInputType.number,
                // Fix #1938: reject non-digit keystrokes; regex validates
                // the 10-16 digit range.
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return '계좌번호를 입력해 주세요.';
                  if (!RegExp(r'^\d{10,16}$').hasMatch(v)) {
                    return '계좌번호는 10~16자리 숫자여야 합니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: MinglitSpacing.medium),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? '확인 중...' : '저장하고 확인 요청'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RetryPayoutButton extends ConsumerStatefulWidget {
  const RetryPayoutButton({
    required this.payoutId,
    required this.partnerId,
    required this.onSuccess,
    super.key,
  });
  final String payoutId;
  final String partnerId;
  final VoidCallback onSuccess;

  @override
  ConsumerState<RetryPayoutButton> createState() => _RetryPayoutButtonState();
}

class _RetryPayoutButtonState extends ConsumerState<RetryPayoutButton> {
  bool _isLoading = false;

  Future<void> _retry() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(settlementCoordinatorProvider.notifier)
          .retryPayout(
            context,
            payoutId: widget.payoutId,
            partnerId: widget.partnerId,
          );
      // Fix #1928: coordinator already shows success toast via
      // showMinglitSuccess.
      if (!mounted) return;
      widget.onSuccess();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _retry,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
      label: Text(_isLoading ? '요청 중...' : '재지급 요청'),
    );
  }
}
