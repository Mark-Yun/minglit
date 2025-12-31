import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyContactInput extends StatelessWidget {
  const PartyContactInput({
    required this.phoneController,
    required this.emailController,
    required this.kakaoController,
    required this.state,
    required this.controller,
    super.key,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController kakaoController;
  final PartyCreateState state;
  final PartyCreateController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone
        _ContactMethodRow(
          methodKey: 'phone',
          isSelected: state.enabledContactMethods.contains('phone'),
          onToggle: () => controller.toggleContactMethod('phone'),
          child: TextFormField(
            controller: phoneController,
            enabled: state.enabledContactMethods.contains('phone'),
            decoration: const InputDecoration(
              labelText: '전화번호',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.medium,
              ),
              prefixIcon: Icon(Icons.phone, size: 18),
            ),
            validator: (v) => state.enabledContactMethods.contains('phone')
                ? controller.validatePhone(v)
                : null,
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),

        // Email
        _ContactMethodRow(
          methodKey: 'email',
          isSelected: state.enabledContactMethods.contains('email'),
          onToggle: () => controller.toggleContactMethod('email'),
          child: TextFormField(
            controller: emailController,
            enabled: state.enabledContactMethods.contains('email'),
            decoration: const InputDecoration(
              labelText: '이메일',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.medium,
              ),
              prefixIcon: Icon(Icons.email, size: 18),
            ),
            validator: (v) => state.enabledContactMethods.contains('email')
                ? controller.validateEmail(v)
                : null,
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),

        // Kakao Link
        _ContactMethodRow(
          methodKey: 'kakao',
          isSelected: state.enabledContactMethods.contains('kakao'),
          onToggle: () => controller.toggleContactMethod('kakao'),
          child: TextFormField(
            controller: kakaoController,
            enabled: state.enabledContactMethods.contains('kakao'),
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
          ),
        ),

        // Error message placeholder
        SizedBox(
          height: MinglitSpacing.large,
          child: AnimatedSwitcher(
            duration: MinglitAnimation.fast,
            child: state.enabledContactMethods.isEmpty
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
