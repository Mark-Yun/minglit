import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Payment flow simulation states.
enum PaymentFlowState {
  /// Order summary, awaiting user confirmation.
  confirm,

  /// Payment is being processed.
  processing,

  /// Payment completed successfully.
  success,

  /// Payment failed.
  failure,
}

/// Refund sub-flow simulation states.
enum RefundFlowState {
  /// Cancel request form shown to user.
  request,

  /// Refund amount is being calculated.
  calculating,

  /// Refund is being processed.
  processing,

  /// Refund completed.
  complete,
}

/// **TransactionFlowDemoPage**
///
/// Design-catalog demo page for P5 결제 플로우 패턴.
/// Simulates payment and refund sub-flow UI states via [SegmentedButton].
///
/// This is a DEMO widget — mock data is inlined and no real payment logic runs.
class TransactionFlowDemoPage extends StatefulWidget {
  /// Creates a [TransactionFlowDemoPage].
  const TransactionFlowDemoPage({super.key});

  @override
  State<TransactionFlowDemoPage> createState() =>
      _TransactionFlowDemoPageState();
}

class _TransactionFlowDemoPageState extends State<TransactionFlowDemoPage> {
  PaymentFlowState _paymentState = PaymentFlowState.confirm;
  RefundFlowState _refundState = RefundFlowState.request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('결제 플로우 패턴 데모')),
      body: ListView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        children: [
          const _SectionHeader(title: '결제 플로우'),
          const SizedBox(height: MinglitSpacing.small),
          _PaymentFlowStateSelector(
            selected: _paymentState,
            onChanged: (state) => setState(() => _paymentState = state),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          _PaymentFlowStatePanel(state: _paymentState),
          const SizedBox(height: MinglitSpacing.large),
          const Divider(),
          const SizedBox(height: MinglitSpacing.large),
          const _SectionHeader(title: '환불 플로우'),
          const SizedBox(height: MinglitSpacing.small),
          _RefundFlowStateSelector(
            selected: _refundState,
            onChanged: (state) => setState(() => _refundState = state),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          _RefundFlowStatePanel(state: _refundState),
          const SizedBox(height: MinglitSpacing.large),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

// ---------------------------------------------------------------------------
// Payment flow widgets
// ---------------------------------------------------------------------------

class _PaymentFlowStateSelector extends StatelessWidget {
  const _PaymentFlowStateSelector({
    required this.selected,
    required this.onChanged,
  });

  final PaymentFlowState selected;
  final ValueChanged<PaymentFlowState> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<PaymentFlowState>(
        segments: const [
          ButtonSegment(
            value: PaymentFlowState.confirm,
            label: Text('확인'),
          ),
          ButtonSegment(
            value: PaymentFlowState.processing,
            label: Text('처리 중'),
          ),
          ButtonSegment(
            value: PaymentFlowState.success,
            label: Text('성공'),
          ),
          ButtonSegment(
            value: PaymentFlowState.failure,
            label: Text('실패'),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (set) {
          if (set.isNotEmpty) onChanged(set.first);
        },
      ),
    );
  }
}

class _PaymentFlowStatePanel extends StatelessWidget {
  const _PaymentFlowStatePanel({required this.state});

  final PaymentFlowState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PaymentFlowState.confirm => const _PaymentConfirmPanel(),
      PaymentFlowState.processing => const _PaymentProcessingPanel(),
      PaymentFlowState.success => const _PaymentSuccessPanel(),
      PaymentFlowState.failure => const _PaymentFailurePanel(),
    };
  }
}

class _PaymentConfirmPanel extends StatelessWidget {
  const _PaymentConfirmPanel();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주문 요약',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          const _OrderSummaryRow(label: '이벤트', value: '밍글릿 봄 파티'),
          const SizedBox(height: MinglitSpacing.small),
          const _OrderSummaryRow(label: '티켓 수', value: '2매'),
          const SizedBox(height: MinglitSpacing.small),
          const _OrderSummaryRow(label: '결제 금액', value: '₩30,000'),
          const SizedBox(height: MinglitSpacing.large),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('결제하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentProcessingPanel extends StatelessWidget {
  const _PaymentProcessingPanel();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '결제 처리 중...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PaymentSuccessPanel extends StatelessWidget {
  const _PaymentSuccessPanel();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: MinglitColors.success,
            size: MinglitIconSize.xlarge,
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '결제 완료',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: MinglitColors.success,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          const _OrderSummaryRow(label: '이벤트', value: '밍글릿 봄 파티'),
          const SizedBox(height: MinglitSpacing.small),
          const _OrderSummaryRow(label: '티켓 수', value: '2매'),
          const SizedBox(height: MinglitSpacing.small),
          const _OrderSummaryRow(label: '결제 금액', value: '₩30,000'),
          const SizedBox(height: MinglitSpacing.small),
          const _OrderSummaryRow(label: '주문 번호', value: 'ORD-20260405-001'),
        ],
      ),
    );
  }
}

class _PaymentFailurePanel extends StatelessWidget {
  const _PaymentFailurePanel();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        children: [
          const Icon(
            Icons.cancel,
            color: MinglitColors.error,
            size: MinglitIconSize.xlarge,
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '결제 실패',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: MinglitColors.error,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '결제 처리 중 오류가 발생했습니다.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          ElevatedButton(
            onPressed: () {},
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Refund flow widgets
// ---------------------------------------------------------------------------

class _RefundFlowStateSelector extends StatelessWidget {
  const _RefundFlowStateSelector({
    required this.selected,
    required this.onChanged,
  });

  final RefundFlowState selected;
  final ValueChanged<RefundFlowState> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<RefundFlowState>(
        segments: const [
          ButtonSegment(
            value: RefundFlowState.request,
            label: Text('요청'),
          ),
          ButtonSegment(
            value: RefundFlowState.calculating,
            label: Text('계산 중'),
          ),
          ButtonSegment(
            value: RefundFlowState.processing,
            label: Text('처리 중'),
          ),
          ButtonSegment(
            value: RefundFlowState.complete,
            label: Text('완료'),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (set) {
          if (set.isNotEmpty) onChanged(set.first);
        },
      ),
    );
  }
}

class _RefundFlowStatePanel extends StatelessWidget {
  const _RefundFlowStatePanel({required this.state});

  final RefundFlowState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      RefundFlowState.request => const _RefundRequestPanel(),
      RefundFlowState.calculating => const _RefundCalculatingPanel(),
      RefundFlowState.processing => const _RefundProcessingPanel(),
      RefundFlowState.complete => const _RefundCompletePanel(),
    };
  }
}

class _RefundRequestPanel extends StatelessWidget {
  const _RefundRequestPanel();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '취소 요청',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          const _OrderSummaryRow(label: '이벤트', value: '밍글릿 봄 파티'),
          const SizedBox(height: MinglitSpacing.small),
          const _OrderSummaryRow(label: '티켓 번호', value: 'TKT-00123'),
          const SizedBox(height: MinglitSpacing.small),
          const _OrderSummaryRow(label: '결제 금액', value: '₩30,000'),
          const SizedBox(height: MinglitSpacing.large),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: MinglitColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('취소 요청'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundCalculatingPanel extends StatelessWidget {
  const _RefundCalculatingPanel();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '환불 금액 계산 중',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RefundProcessingPanel extends StatelessWidget {
  const _RefundProcessingPanel();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '환불 처리 중',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RefundCompletePanel extends StatelessWidget {
  const _RefundCompletePanel();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: MinglitColors.success,
            size: MinglitIconSize.xlarge,
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '환불 완료',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: MinglitColors.success,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          const _OrderSummaryRow(label: '환불 금액', value: '₩30,000'),
          const SizedBox(height: MinglitSpacing.small),
          const _OrderSummaryRow(label: '처리 완료', value: '2026-04-05'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helper widgets
// ---------------------------------------------------------------------------

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: MinglitColors.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: child,
    );
  }
}

class _OrderSummaryRow extends StatelessWidget {
  const _OrderSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: MinglitColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
