import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
const List<({String status, String label, IconData icon})> kJobStatusSteps = [
  (status: 'accepted',    label: 'Accepted',  icon: Icons.check_circle_outline),
  (status: 'en_route',    label: 'En Route',  icon: Icons.directions_car_outlined),
  (status: 'arrived',     label: 'Arrived',   icon: Icons.place_outlined),
  (status: 'in_progress', label: 'Working',   icon: Icons.build_circle_outlined),
  (status: 'completed',   label: 'Done',      icon: Icons.task_alt),
  (status: 'paid',        label: 'Paid',      icon: Icons.payments_outlined),
];
int jobStatusIndex(String status) =>
    kJobStatusSteps.indexWhere((s) => s.status == status);
class JobStatusTracker extends StatelessWidget {
  final String currentStatus;
  final void Function(String nextStatus)? onNextStepTap;
  const JobStatusTracker({
    super.key,
    required this.currentStatus,
    this.onNextStepTap,
  });
  @override
  Widget build(BuildContext context) {
    final currentIdx = jobStatusIndex(currentStatus);
    final nextIdx    = currentIdx + 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(kJobStatusSteps.length, (i) {
        final step      = kJobStatusSteps[i];
        final isDone    = currentIdx >= 0 && i < currentIdx;
        final isCurrent = i == currentIdx;
        final isNext    = onNextStepTap != null &&
                          i == nextIdx &&
                          nextIdx < kJobStatusSteps.length;
        final Color circleColor = isDone
            ? AppTheme.primaryCyan
            : isCurrent
                ? AppTheme.deepBlue
                : Colors.grey.shade200;
        final Color iconColor =
            (isDone || isCurrent) ? Colors.white : Colors.grey.shade400;
        final Color labelColor = isDone
            ? AppTheme.primaryCyan
            : isCurrent
                ? AppTheme.deepBlue
                : isNext
                    ? AppTheme.deepBlue
                    : Colors.grey.shade400;
        Widget circle = Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: isNext
                ? Border.all(color: AppTheme.deepBlue, width: 1.5)
                : null,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.deepBlue.withValues(alpha: 0.35),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : step.icon,
            size: 14,
            color: iconColor,
          ),
        );
        if (isNext) {
          circle = Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onNextStepTap!(step.status),
              child: circle,
            ),
          );
        }
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= currentIdx && currentIdx >= 0
                            ? AppTheme.primaryCyan
                            : Colors.grey.shade300,
                      ),
                    ),
                  circle,
                  if (i < kJobStatusSteps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < currentIdx && currentIdx >= 0
                            ? AppTheme.primaryCyan
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                step.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      (isCurrent || isNext) ? FontWeight.w700 : FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}