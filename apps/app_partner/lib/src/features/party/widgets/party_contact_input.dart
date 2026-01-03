import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyContactInput extends StatelessWidget {
  const PartyContactInput({
    required this.phoneController,
    required this.emailController,
    required this.kakaoController,
    required this.enabledMethods,
    required this.onToggleMethod,
    this.onPhoneChanged,
    this.onEmailChanged,
    this.onKakaoChanged,
    this.phoneValidator,
    this.emailValidator,
    super.key,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController kakaoController;
  final Set<String> enabledMethods;
  final ValueChanged<String> onToggleMethod;
  final ValueChanged<String>? onPhoneChanged;
  final ValueChanged<String>? onEmailChanged;
  final ValueChanged<String>? onKakaoChanged;
  final FormFieldValidator<String>? phoneValidator;
  final FormFieldValidator<String>? emailValidator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone
        _ContactMethodRow(
          methodKey: 'phone',
          isSelected: enabledMethods.contains('phone'),
          onToggle: () => onToggleMethod('phone'),
          child: TextFormField(
            controller: phoneController,
            enabled: enabledMethods.contains('phone'),
            decoration: const InputDecoration(
              labelText: '전화번호',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.medium,
              ),
              prefixIcon: Icon(Icons.phone, size: 18),
            ),
            onChanged: onPhoneChanged,
            validator: phoneValidator,
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),

        // Email
        _ContactMethodRow(
          methodKey: 'email',
          isSelected: enabledMethods.contains('email'),
          onToggle: () => onToggleMethod('email'),
          child: TextFormField(
            controller: emailController,
            enabled: enabledMethods.contains('email'),
            decoration: const InputDecoration(
              labelText: '이메일',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.medium,
              ),
              prefixIcon: Icon(Icons.email, size: 18),
            ),
            onChanged: onEmailChanged,
            validator: emailValidator,
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),

        // Kakao Link
        _ContactMethodRow(
          methodKey: 'kakao',
          isSelected: enabledMethods.contains('kakao'),
          onToggle: () => onToggleMethod('kakao'),
          child: TextFormField(
            controller: kakaoController,
            enabled: enabledMethods.contains('kakao'),
            decoration: const InputDecoration(
              labelText: '오픈카카오톡 링크 (선택)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.medium,
              ),
              hintText: 'https://open.kakao.com/o/...',
              prefixIcon: Icon(Icons.chat_bubble_outline, size: 18),
              helperText: '참가자들과 소통할 오픈채팅방 링크를 입력해주세요.',
            ),
            onChanged: onKakaoChanged,
          ),
        ),

        // Error message placeholder
        SizedBox(
          height: MinglitSpacing.large,
          child: AnimatedSwitcher(
            duration: MinglitAnimation.fast,
            child: enabledMethods.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: MinglitSpacing.small,
                      ),
                      child: Text(
                        '최소 한 개의 연락처를 선택해야 합니다.',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _ContactMethodRow extends StatelessWidget {
  const _ContactMethodRow({
    required this.methodKey,
    required this.isSelected,
    required this.onToggle,
    required this.child,
  });

  final String methodKey;
  final bool isSelected;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final localTheme = theme.copyWith(
      colorScheme: colorScheme.copyWith(primary: colorScheme.secondary),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.input),
          borderSide: BorderSide(
            color: colorScheme.secondary,
            width: 2,
          ),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Theme(
            data: localTheme,
            child: AnimatedOpacity(
              duration: MinglitAnimation.fast,
              opacity: isSelected ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: !isSelected,
                child: child,
              ),
            ),
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.small,
              vertical: MinglitSpacing.medium,
            ),
            child: AnimatedSwitcher(
              duration: MinglitAnimation.fast,
              child: isSelected
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey('checked'),
                      color: colorScheme.secondary,
                      size: MinglitIconSize.large,
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      key: const ValueKey('unchecked'),
                      color: colorScheme.outlineVariant,
                      size: MinglitIconSize.large,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
