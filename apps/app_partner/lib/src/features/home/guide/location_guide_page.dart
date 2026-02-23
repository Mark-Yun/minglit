import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Static informational page with tips for choosing event locations.
class LocationGuidePage extends StatelessWidget {
  const LocationGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '장소선정 가이드'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: 좋은 장소의 조건
            _SectionCard(
              icon: Icons.check_circle_outline,
              iconColor: colorScheme.primary,
              title: '좋은 장소의 조건',
              children: const [
                _BulletItem('대중교통 접근성이 좋은 곳 (역세권 도보 10분 이내)'),
                _BulletItem('주차 공간이 확보된 곳'),
                _BulletItem('소음이 적고 대화하기 편한 환경'),
                _BulletItem('단체 예약이 가능한 공간'),
                _BulletItem('참여자 수에 맞는 적절한 크기'),
              ],
            ),
            const SizedBox(height: MinglitSpacing.medium),

            // Section 2: 장소 등록 방법
            _SectionCard(
              icon: Icons.edit_note,
              iconColor: colorScheme.secondary,
              title: '장소 등록 방법',
              children: const [
                _StepItem(step: 1, text: '파트너 프로필에서 "장소 관리" 메뉴 진입'),
                _StepItem(step: 2, text: '주소 검색으로 장소 위치 설정'),
                _StepItem(step: 3, text: '상세 주소 및 찾아오는 길 안내 입력'),
                _StepItem(step: 4, text: '등록 완료 후 이벤트 생성 시 장소 선택'),
              ],
            ),
            const SizedBox(height: MinglitSpacing.medium),

            // Section 3: 주의사항
            _SectionCard(
              icon: Icons.warning_amber_rounded,
              iconColor: colorScheme.error,
              title: '주의사항',
              children: const [
                _BulletItem('실제 운영 가능한 장소만 등록해주세요'),
                _BulletItem('장소 변경 시 참여자에게 반드시 사전 공지해주세요'),
                _BulletItem('위생 및 안전 기준을 충족하는 공간을 선택해주세요'),
                _BulletItem('장소 사진은 실제 모습과 일치해야 합니다'),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.medium),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: theme.textTheme.bodyMedium),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({required this.step, required this.text});

  final int step;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$step',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
