import 'dart:async' show unawaited;

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:app_partner/src/features/settlement/settlement_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class BankAccountPage extends ConsumerStatefulWidget {
  const BankAccountPage({super.key});

  @override
  ConsumerState<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends ConsumerState<BankAccountPage> {
  Map<String, dynamic>? _accountData;
  bool _isLoading = true;

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
    } on Exception catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('계좌 관리')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountCard(accountData: _accountData),
                  const SizedBox(height: 16),
                  AccountEditForm(
                    accountData: _accountData,
                    onSaved: _loadAccount,
                  ),
                ],
              ),
            ),
    );
  }
}

class AccountCard extends StatelessWidget {
  const AccountCard({required this.accountData, super.key});
  final Map<String, dynamic>? accountData;

  @override
  Widget build(BuildContext context) {
    if (accountData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('등록된 계좌 정보가 없습니다.'),
        ),
      );
    }
    final bankName = accountData!['bank_name'] as String? ?? '-';
    final holder = accountData!['account_holder'] as String? ?? '-';
    final number = accountData!['account_number'] as String? ?? '';
    final masked = number.length > 4
        ? '${'*' * (number.length - 4)}${number.substring(number.length - 4)}'
        : number;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 계좌', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _InfoRow('은행', bankName),
            _InfoRow('예금주', holder),
            _InfoRow('계좌번호', masked),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bankCtrl = TextEditingController(
      text: widget.accountData?['bank_name'] as String? ?? '',
    );
    _holderCtrl = TextEditingController(
      text: widget.accountData?['account_holder'] as String? ?? '',
    );
    _numberCtrl = TextEditingController(
      text: widget.accountData?['account_number'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _holderCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) return;
      final repo = ref.read(settlementRepositoryProvider);
      await repo.upsertBankAccount(
        partnerId: partner.id,
        bankName: _bankCtrl.text.trim(),
        accountHolder: _holderCtrl.text.trim(),
        accountNumber: _numberCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계좌 정보가 저장되었습니다.')),
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('계좌 수정', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankCtrl,
                decoration: const InputDecoration(labelText: '은행명'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '은행명을 입력해 주세요.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _holderCtrl,
                decoration: const InputDecoration(labelText: '예금주'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '예금주를 입력해 주세요.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numberCtrl,
                decoration: const InputDecoration(labelText: '계좌번호'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.isEmpty) ? '계좌번호를 입력해 주세요.' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? '저장 중...' : '저장'),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재지급 요청이 완료되었습니다.')),
      );
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
