import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Identity Verification Screen (Mock)**
///
/// A screen where users input their PII (Personally Identifiable Information).
/// In a real scenario, this would integrate with PASS/SMS verification.
/// Currently, it mocks the process and updates the `user_profiles`
/// table directly.
class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form State
  String _name = '';
  DateTime? _birthDate;
  String _gender = 'male'; // 'male' | 'female'
  String _carrier = 'SKT';
  String _phoneNumber = '';
  bool _isLoading = false;

  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      handleMinglitError(context, const MinglitUserException('생년월일을 선택해주세요.'));
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      // Mock Delay
      await Future<void>.delayed(const Duration(seconds: 1));

      await ref
          .read(identityRepositoryProvider)
          .verifyIdentity(
            name: _name,
            birthDate: _birthDate!,
            gender: _gender,
            phoneNumber: _phoneNumber,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 본인인증이 완료되었습니다.')),
        );
        Navigator.of(context).pop(true); // Return success result
      }
    } on Object catch (e, st) {
      if (mounted) {
        handleMinglitError(context, e, st);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('ko', 'KR'),
    );
    if (date != null) {
      setState(() => _birthDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '본인인증'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안전한 서비스 이용을 위해\n본인인증을 진행해주세요.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '입력하신 정보는 인증 목적으로만 사용되며 안전하게 보호됩니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Name
              _buildLabel('이름'),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: '실명을 입력해주세요',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? '이름을 입력해주세요.' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 24),

              // Birth Date
              _buildLabel('생년월일'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) {
                          final bd = _birthDate;
                          final text = bd == null
                              ? '생년월일 선택'
                              : '''${bd.year}.${bd.month.toString().padLeft(2, '0')}.${bd.day.toString().padLeft(2, '0')}''';
                          return Text(
                            text,
                            style: TextStyle(
                              color: bd == null
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                          );
                        },
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Gender
              _buildLabel('성별'),
              Row(
                children: [
                  Expanded(child: _buildGenderButton('male', '남성')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGenderButton('female', '여성')),
                ],
              ),
              const SizedBox(height: 24),

              // Phone
              _buildLabel('휴대폰 번호'),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      initialValue: _carrier,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'SKT', child: Text('SKT')),
                        DropdownMenuItem(value: 'KT', child: Text('KT')),
                        DropdownMenuItem(value: 'LGU+', child: Text('LGU+')),
                      ],
                      onChanged: (v) => setState(() => _carrier = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '01012345678',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '번호를 입력해주세요.';
                        if (v.length < 10) return '올바른 번호를 입력해주세요.';
                        return null;
                      },
                      onSaved: (v) => _phoneNumber = v!,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => unawaited(_submit()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '인증하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildGenderButton(String value, String label) {
    final isSelected = _gender == value;
    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => setState(() => _gender = value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
