import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../shared/widgets/paper_document.dart';
import '../cubit/estimate_detail_cubit.dart';
import '../models/estimate_model.dart';

/// Estimate detail — a straightforward data view driven by the API
/// (`GET /api/Estimates/{id}`): header, action bar, status, line items,
/// totals, and notes.
class EstimateDetailScreen extends StatefulWidget {
  final String id;
  const EstimateDetailScreen({super.key, required this.id});

  @override
  State<EstimateDetailScreen> createState() => _EstimateDetailScreenState();
}

class _EstimateDetailScreenState extends State<EstimateDetailScreen> {
  int get _estimateId => int.tryParse(widget.id) ?? 0;

  @override
  void initState() {
    super.initState();
    context.read<EstimateDetailCubit>().fetch(_estimateId);
  }

  Future<void> _handleEdit(Estimate estimate) async {
    final result = await context.push<Map<String, dynamic>>(
      AppRoutes.newEstimate,
      extra: {'estimateToEdit': estimate},
    );
    if (!mounted || result == null) return;
    if (result['estimate'] is Estimate) {
      context.read<EstimateDetailCubit>().applyUpdate(result['estimate'] as Estimate);
    } else {
      context.read<EstimateDetailCubit>().fetch(_estimateId);
    }
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete estimate?'),
        content: const Text('This permanently removes the estimate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<EstimateDetailCubit>().delete(_estimateId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EstimateDetailCubit, EstimateDetailState>(
      listener: (context, state) {
        if (state is EstimateDetailDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estimate deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (context.canPop()) context.pop();
        } else if (state is EstimateDetailActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is EstimateDetailActionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.orangeDeep,
            ),
          );
        }
      },
      builder: (context, state) {
        final estimate = switch (state) {
          EstimateDetailLoaded(:final estimate) => estimate,
          EstimateDetailLoading(:final preview) => preview,
          EstimateDetailError(:final stale) => stale,
          EstimateDetailBusy(:final estimate) => estimate,
          EstimateDetailActionSuccess(:final estimate) => estimate,
          EstimateDetailActionFailure(:final estimate) => estimate,
          _ => null,
        };
        final isLoading = state is EstimateDetailLoading;
        final isBusy = state is EstimateDetailBusy;
        final errorMessage =
            state is EstimateDetailError ? state.message : null;

        return LoadingOverlay(
          isLoading: isBusy,
          child: Scaffold(
            body: Column(
              children: [
                DetailHeader(
                  backLabel: 'Estimates',
                  title: estimate != null
                      ? '#${estimate.number}'
                      : '#${widget.id}',
                  actions: [
                    if (estimate != null)
                      TextButton(
                        onPressed: () => _handleEdit(estimate),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.white),
                        child: const Text('Edit'),
                      ),
                  ],
                ),
                if (estimate != null)
                  DocumentToolbar(
                    actions: [
                      ToolbarAction(Icons.send_outlined, 'Send',
                          onTap: () => context
                              .read<EstimateDetailCubit>()
                              .send(_estimateId)),
                      ToolbarAction(Icons.receipt_long_outlined, 'Invoice',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Convert to invoice is coming soon.')),
                              )),
                      ToolbarAction(Icons.delete_outline, 'Delete',
                          onTap: _confirmDelete),
                    ],
                  ),
                Expanded(
                  child: isLoading && estimate == null
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null && estimate == null
                          ? _ErrorBody(
                              message: errorMessage,
                              onRetry: () => context
                                  .read<EstimateDetailCubit>()
                                  .fetch(_estimateId),
                            )
                          : _Body(estimate: estimate!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final Estimate estimate;
  const _Body({required this.estimate});

  @override
  Widget build(BuildContext context) {
    final items = estimate.allLineItems
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estimate.clientName?.trim().isNotEmpty == true
                        ? estimate.clientName!
                        : 'No client',
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimate #${estimate.number} · ${Formatters.dateMedium(estimate.estimateDate)}',
                    style: AppTextStyles.caption,
                  ),
                  if (estimate.expirationDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Valid until ${Formatters.dateMedium(estimate.expirationDate!)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ),
            StatusChip(status: estimate.docStatus),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Line items'),
        if (items.isEmpty)
          const AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 4),
              child: Text('No line items on this estimate yet.',
                  style: AppTextStyles.caption),
            ),
          )
        else
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  _LineItemRow(item: items[i], showDivider: i < items.length - 1),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _TotalsCard(estimate: estimate),
        if ((estimate.notes ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          DocNotesCard(text: estimate.notes!.trim()),
        ],
      ],
    );
  }
}

class _LineItemRow extends StatelessWidget {
  final EstimateLineItem item;
  final bool showDivider;
  const _LineItemRow({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description.isEmpty ? 'Item' : item.description,
                  style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.quantity} × ${Formatters.currency(item.unitPrice)}',
                  style: AppTextStyles.caption,
                ),
                if ((item.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.notes!.trim(),
                      style: AppTextStyles.caption.copyWith(height: 1.4)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(Formatters.currency(item.lineTotal),
              style: AppTextStyles.rowAmount.copyWith(fontSize: 14.5)),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final Estimate estimate;
  const _TotalsCard({required this.estimate});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, bool)>[
      ('Subtotal', Formatters.currency(estimate.subtotal), false),
    ];
    if ((estimate.discountValue ?? 0) > 0) {
      rows.add(('Discount', '−${_modifier(estimate.discountType, estimate.discountValue!)}', false));
    }
    if ((estimate.markupValue ?? 0) > 0) {
      rows.add(('Markup', '+${_modifier(estimate.markupType, estimate.markupValue!)}', false));
    }
    if ((estimate.taxRate ?? 0) > 0) {
      rows.add((
        estimate.taxName?.trim().isNotEmpty == true
            ? 'Tax (${estimate.taxName})'
            : 'Tax',
        '${estimate.taxRate!.toStringAsFixed(2)}%',
        false,
      ));
    }
    rows.add(('Total', Formatters.currency(estimate.total), true));
    if (estimate.depositAmount > 0) {
      rows.add(('Deposit due', Formatters.currency(estimate.depositAmount), false));
    }

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.line))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: rows[i].$3
                        ? AppTextStyles.rowTitle
                        : AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.inkSoft),
                  ),
                  Text(
                    rows[i].$2,
                    style: rows[i].$3
                        ? AppTextStyles.rowAmount
                        : AppTextStyles.labelMedium.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _modifier(String? type, double value) =>
      AmountType.fromApi(type) == AmountType.percent
          ? '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}%'
          : Formatters.currency(value);
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.inkFaint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
