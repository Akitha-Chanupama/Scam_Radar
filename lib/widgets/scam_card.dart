import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/community_report.dart';

class ScamCard extends StatelessWidget {
  final CommunityReport report;
  final VoidCallback? onTap;

  const ScamCard({
    super.key,
    required this.report,
    this.onTap,
  });

  IconData _typeIcon() {
    return report.reportType == 'message'
        ? Icons.message_outlined
        : Icons.phone_outlined;
  }

  Color _typeColor(BuildContext context) {
    return report.reportType == 'message'
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.tertiary;
  }

  String _preview() {
    if (report.reportType == 'message' && report.scamMessage != null) {
      final text = report.scamMessage!.messageText;
      return text.length > 100 ? '${text.substring(0, 100)}...' : text;
    }
    if (report.reportType == 'number' && report.scamNumber != null) {
      return '${report.scamNumber!.phoneNumber} — ${report.scamNumber!.scamType}';
    }
    return report.description;
  }

  String _trailingText() {
    if (report.reportType == 'message' && report.scamMessage != null) {
      return '${report.scamMessage!.scamScore}%';
    }
    if (report.reportType == 'number' && report.scamNumber != null) {
      return '${report.scamNumber!.reportsCount} reports';
    }
    return '';
  }

  Color _scoreBadgeColor() {
    if (report.scamMessage == null) return Colors.grey;
    final score = report.scamMessage!.scamScore;
    if (score < 30) return Colors.green;
    if (score < 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(), color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.reportType == 'message'
                              ? 'Scam Message'
                              : 'Scam Number',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const Spacer(),
                        if (_trailingText().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: report.reportType == 'message'
                                  ? _scoreBadgeColor().withValues(alpha: 0.15)
                                  : Theme.of(context)
                                      .colorScheme
                                      .tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _trailingText(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: report.reportType == 'message'
                                    ? _scoreBadgeColor()
                                    : Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _preview(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (report.reporterName != null) ...[
                          Icon(Icons.person_outline,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            report.reporterName!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.access_time,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(report.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
