import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/lead_bloc.dart';
import '../cubit/lead_detail_cubit.dart';
import '../models/lead_model.dart';

class LeadDetailScreen extends StatefulWidget {
  final String id;
  final Lead? previewLead;

  const LeadDetailScreen({
    super.key,
    required this.id,
    this.previewLead,
  });

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  bool _statusUpdatePending = false;

  @override
  void initState() {
    super.initState();
    final requestId = int.tryParse(widget.id) ?? 0;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<LeadDetailCubit>().fetch(
            requestId,
            authState.user.userId,
            preview: widget.previewLead,
          );
    }
  }

  Future<void> _handleEdit(Lead lead) async {
    final result = await context.push<Map<String, dynamic>>(
      AppRoutes.addLead,
      extra: {'leadToEdit': lead},
    );
    if (!mounted || result == null) return;

    if (result['deleted'] == true) {
      if (context.canPop()) context.pop();
    } else if (result['lead'] != null) {
      final updated = result['lead'] as Lead;
      context.read<LeadDetailCubit>().applyUpdate(updated);
    }
  }

  void _changeStatus(Lead lead) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    _showStatusPicker(lead, authState.user.userId);
  }

  void _showStatusPicker(Lead lead, int userId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _StatusPickerSheet(
        currentStatus: lead.status,
        onSelected: (status) {
          Navigator.pop(sheetContext);
          setState(() => _statusUpdatePending = true);
          context.read<LeadBloc>().add(LeadStatusUpdateRequested(
                requestId: lead.requestId,
                userId: userId,
                status: status,
              ));
          context.read<LeadDetailCubit>().applyUpdate(
                lead.copyWith(status: status),
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadBloc, LeadsState>(
      listenWhen: (_, curr) =>
          curr is LeadUpdateSuccess || curr is LeadUpdateFailure,
      listener: (context, state) {
        if (state is LeadUpdateSuccess && _statusUpdatePending) {
          setState(() => _statusUpdatePending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status updated'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state is LeadUpdateFailure) {
          setState(() => _statusUpdatePending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.orangeDeep,
            ),
          );
        }
      },
      child: BlocBuilder<LeadDetailCubit, LeadDetailState>(
        builder: (context, state) {
          final lead = switch (state) {
            LeadDetailLoaded(:final lead) => lead,
            LeadDetailLoading(:final preview) => preview,
            LeadDetailError(:final stale) => stale,
            LeadNoteAdding(:final lead) => lead,
            LeadNoteAddSuccess(:final lead) => lead,
            LeadNoteAddFailure(:final lead) => lead,
            _ => null,
          };

          final isLoading = state is LeadDetailLoading && lead == null;
          final errorMessage =
              state is LeadDetailError ? state.message : null;
          final isNoteAdding = state is LeadNoteAdding;

          final authState = context.read<AuthBloc>().state;
          final userId = authState is AuthAuthenticated
              ? authState.user.userId
              : 0;

          return LoadingOverlay(
            isLoading: isNoteAdding,
            child: Scaffold(
              body: Column(
                children: [
                  _Header(
                    lead: lead,
                    isLoading: isLoading,
                    onEdit: lead != null ? () => _handleEdit(lead) : null,
                    onStatusChange:
                        lead != null ? () => _changeStatus(lead) : null,
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : errorMessage != null && lead == null
                            ? _ErrorBody(
                                message: errorMessage,
                                onRetry: () {
                                  final requestId =
                                      int.tryParse(widget.id) ?? 0;
                                  final auth = context.read<AuthBloc>().state;
                                  if (auth is AuthAuthenticated) {
                                    context.read<LeadDetailCubit>().fetch(
                                          requestId,
                                          auth.user.userId,
                                          preview: widget.previewLead,
                                        );
                                  }
                                },
                              )
                            : _Body(lead: lead!, userId: userId),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Lead? lead;
  final bool isLoading;
  final VoidCallback? onEdit;
  final VoidCallback? onStatusChange;

  const _Header({
    required this.lead,
    required this.isLoading,
    this.onEdit,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final l = lead;
    return Container(
      color: AppColors.green800,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(8),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new,
                        size: 14, color: Color(0xD9FFFFFF)),
                    SizedBox(width: 4),
                    Text(
                      'Leads',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xD9FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (l != null) ...[
                _HeaderButton(
                  icon: Icons.swap_horiz_outlined,
                  onTap: onStatusChange ?? () {},
                ),
                const SizedBox(width: 8),
                _HeaderButton(
                  icon: Icons.edit_outlined,
                  onTap: onEdit ?? () {},
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading || l == null)
            _headerSkeleton()
          else ...[
            Row(
              children: [
                AvatarWidget(name: l.fullName, size: 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.fullName,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (l.place.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          l.place,
                          style: AppTextStyles.headerSubtitle
                              .copyWith(fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _statusChip(l.status),
            const SizedBox(height: 14),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  onTap: () => ContactLauncher.call(context, l.phone),
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.chat_bubble_outline,
                  label: 'Text',
                  onTap: () => ContactLauncher.text(context, l.phone),
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () => ContactLauncher.email(context, l.email),
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.note_add_outlined,
                  label: 'Estimate',
                  primary: true,
                  onTap: () => context.push(AppRoutes.newEstimate),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(LeadStatus status) {
    final (bg, fg, label) = switch (status) {
      LeadStatus.newLead => (AppColors.orangeTint, AppColors.orangeDeep, 'New'),
      LeadStatus.contacted =>
        (AppColors.grayTint, AppColors.grayDeep, 'Contacted'),
      LeadStatus.quoted =>
        (AppColors.greenTint, AppColors.greenDeep, 'Estimate sent'),
      LeadStatus.won => (AppColors.greenDeep, Colors.white, 'Won'),
      LeadStatus.lost => (AppColors.redTint, AppColors.redDeep, 'Lost'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _headerSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final Lead lead;
  final int userId;

  const _Body({required this.lead, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        // Contact
        const SectionHeader(title: 'Contact'),
        _contactCard(context, lead),

        // Details
        const SectionHeader(title: 'Details'),
        _detailsCard(context, lead),

        // Activity notes
        SectionHeader(
          title: 'Activity notes',
          trailingWidget: _AddNoteButton(lead: lead),
        ),
        _notesSection(context, lead),

        // History & Photos tabs
        const SizedBox(height: 4),
        _HistoryPhotosSection(lead: lead, userId: userId),
      ],
    );
  }

  Widget _contactCard(BuildContext context, Lead lead) {
    final items = <(IconData, String, String)>[
      if (lead.email != null && lead.email!.isNotEmpty)
        (Icons.mail_outline, 'Email', lead.email!),
      if (lead.phone != null && lead.phone!.isNotEmpty)
        (Icons.call_outlined, 'Phone', lead.phone!),
      if (lead.streetAddress != null && lead.streetAddress!.isNotEmpty)
        (Icons.place_outlined, 'Address',
            [
              lead.streetAddress!,
              if (lead.addressLine2 != null && lead.addressLine2!.isNotEmpty)
                lead.addressLine2!,
              lead.place,
            ].where((s) => s.isNotEmpty).join(', ')),
    ];

    if (items.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Text('No contact info on file', style: AppTextStyles.caption),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _ContactRow(
              icon: items[i].$1,
              label: items[i].$2,
              value: items[i].$3,
              showDivider: i < items.length - 1,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: items[i].$3));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${items[i].$2} copied'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _detailsCard(BuildContext context, Lead lead) {
    final dateFmt = DateFormat("EEEE, MMMM d, yyyy 'at' hh:mm a");
    final dateStr = dateFmt.format(lead.createdDate.toLocal());

    final items = <(IconData, String, String)>[
      (Icons.calendar_today_outlined, 'Lead date', dateStr),
      (Icons.tag_outlined, 'Lead number', '#${lead.requestId}'),
      if (lead.categoryName != null && lead.categoryName!.isNotEmpty)
        (Icons.build_outlined, 'Project type', lead.categoryName!),
      if (lead.requestText != null && lead.requestText!.isNotEmpty)
        (Icons.description_outlined, 'Project description', lead.requestText!),
      if (lead.leadSource != null && lead.leadSource!.isNotEmpty)
        (Icons.source_outlined, 'Lead source', lead.leadSource!),
      if (lead.leadCost != null)
        (Icons.attach_money_outlined, 'Lead cost',
            '\$${lead.leadCost!.toStringAsFixed(2)}'),
    ];

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _ContactRow(
              icon: items[i].$1,
              label: items[i].$2,
              value: items[i].$3,
              showDivider: i < items.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _notesSection(BuildContext context, Lead lead) {
    final sorted = [...lead.leadNotes]
      ..sort((a, b) => (b.createdDateUtc ?? DateTime(0))
          .compareTo(a.createdDateUtc ?? DateTime(0)));

    if (sorted.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              const Icon(Icons.notes_outlined,
                  size: 28, color: AppColors.inkFaint),
              const SizedBox(height: 8),
              Text('No notes yet',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.inkSoft)),
              const SizedBox(height: 4),
              Text('Tap + above to add an activity note.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++)
            _NoteRow(
              note: sorted[i],
              showDivider: i < sorted.length - 1,
              onDelete: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is! AuthAuthenticated) return;
                context.read<LeadDetailCubit>().deleteNote(
                      lead.requestId,
                      authState.user.userId,
                      sorted[i].leadNoteId,
                    );
              },
            ),
        ],
      ),
    );
  }
}

// ─── History & Photos tab section ─────────────────────────────────────────────

class _HistoryPhotosSection extends StatefulWidget {
  final Lead lead;
  final int userId;

  const _HistoryPhotosSection({required this.lead, required this.userId});

  @override
  State<_HistoryPhotosSection> createState() => _HistoryPhotosSectionState();
}

class _HistoryPhotosSectionState extends State<_HistoryPhotosSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<LeadPhotoDto>? _photos;
  bool _photosLoading = false;
  String? _photosError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _photos == null && !_photosLoading) {
        _loadPhotos();
      }
    });
  }

  @override
  void didUpdateWidget(_HistoryPhotosSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lead != widget.lead) {
      _photos = null;
      _photosError = null;
      if (_tabController.index == 1) _loadPhotos();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _photosLoading = true;
      _photosError = null;
    });
    final result = await Injection.leadRepository
        .fetchPhotos(widget.lead.requestId, widget.userId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _photosLoading = false;
        _photosError = failure.message;
      }),
      (photos) => setState(() {
        _photosLoading = false;
        _photos = photos;
      }),
    );
  }

  Future<void> _deletePhoto(LeadPhotoDto photo) async {
    if (photo.blobPath == null) return;
    setState(() => _photos?.remove(photo));
    await Injection.leadRepository
        .deletePhoto(widget.lead.requestId, widget.userId, photo.blobPath!);
  }

  @override
  Widget build(BuildContext context) {
    final history = [...widget.lead.leadHistories]
      ..sort((a, b) => (b.createdDateUtc ?? DateTime(0))
          .compareTo(a.createdDateUtc ?? DateTime(0)));
    final photoCount = _photos?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(
              top: BorderSide(color: AppColors.line),
              bottom: BorderSide(color: AppColors.line),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.greenDeep,
            unselectedLabelColor: AppColors.inkSoft,
            indicatorColor: AppColors.greenDeep,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              const Tab(text: 'History'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Photos'),
                    if (photoCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.inkFaint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$photoCount',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return IndexedStack(
              index: _tabController.index,
              children: [
                _HistoryTab(history: history),
                _PhotosTab(
                  photos: _photos,
                  isLoading: _photosLoading,
                  error: _photosError,
                  onRetry: _loadPhotos,
                  onDelete: _deletePhoto,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<LeadHistory> history;
  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('No history yet',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.inkFaint)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (var i = 0; i < history.length; i++)
            _HistoryRow(
              item: history[i],
              showDivider: i < history.length - 1,
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final LeadHistory item;
  final bool showDivider;

  const _HistoryRow({required this.item, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final date = item.createdDateUtc?.toLocal();
    String dateStr = '';
    if (date != null) {
      final datePart = DateFormat('MMM d').format(date);
      final timePart = DateFormat('h:mm a').format(date);
      dateStr = '$datePart, $timePart';
    }

    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.greenDeep,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkFaint,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  item.eventText ?? '',
                  style: AppTextStyles.rowTitle
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosTab extends StatelessWidget {
  final List<LeadPhotoDto>? photos;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<LeadPhotoDto> onDelete;

  const _PhotosTab({
    required this.photos,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null && photos == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error!,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    final list = photos ?? [];
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 32, color: AppColors.inkFaint),
            const SizedBox(height: 10),
            Text('No photos yet',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: 4),
            Text('Tap the edit button to add photos.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 12)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) => _PhotoTile(
          photo: list[i],
          onDelete: () => _confirmDelete(context, list[i]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LeadPhotoDto photo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo?'),
        content:
            const Text('This photo will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(photo);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final LeadPhotoDto photo;
  final VoidCallback onDelete;

  const _PhotoTile({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          photo.url != null
              ? CachedNetworkImage(
                  imageUrl: photo.url!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.grayTint,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.grayTint,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.inkFaint),
                  ),
                )
              : Container(
                  color: AppColors.grayTint,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.inkFaint),
                ),
          // Action buttons overlay
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              children: [
                _PhotoAction(
                  icon: Icons.download_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 4),
                _PhotoAction(
                  icon: Icons.close,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PhotoAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

// ─── Error body ───────────────────────────────────────────────────────────────

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
            Text(message,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: 20),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

// ─── Status picker sheet ──────────────────────────────────────────────────────

class _StatusPickerSheet extends StatelessWidget {
  final LeadStatus currentStatus;
  final ValueChanged<LeadStatus> onSelected;

  const _StatusPickerSheet({
    required this.currentStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      (LeadStatus.newLead, Icons.bolt_outlined, 'New'),
      (LeadStatus.contacted, Icons.chat_bubble_outline, 'Contacted'),
      (LeadStatus.quoted, Icons.send_outlined, 'Estimate sent'),
      (LeadStatus.won, Icons.check_circle_outline, 'Won'),
      (LeadStatus.lost, Icons.cancel_outlined, 'Lost'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Update status',
                  style: AppTextStyles.rowTitle
                      .copyWith(fontSize: 16, color: AppColors.ink)),
            ),
            ...statuses.map((entry) {
              final (status, icon, label) = entry;
              final isSelected = status == currentStatus;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  icon,
                  color:
                      isSelected ? AppColors.greenDeep : AppColors.inkSoft,
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? AppColors.greenDeep : AppColors.ink,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.greenDeep)
                    : null,
                onTap: () => onSelected(status),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Add note button ──────────────────────────────────────────────────────────

class _AddNoteButton extends StatelessWidget {
  final Lead lead;
  const _AddNoteButton({required this.lead});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddNote(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.greenTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.greenDeep),
            SizedBox(width: 3),
            Text(
              'Add',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.greenDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNote(BuildContext context) {
    final controller = TextEditingController();
    // Capture BLoC references before entering the bottom sheet
    final cubit = context.read<LeadDetailCubit>();
    final authState = context.read<AuthBloc>().state;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _AddNoteSheet(
        controller: controller,
        onSave: (text) {
          if (authState is! AuthAuthenticated) return;
          cubit.addNote(
            lead.requestId,
            authState.user.userId,
            text,
          );
        },
      ),
    );
  }
}

class _AddNoteSheet extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSave;

  const _AddNoteSheet({required this.controller, required this.onSave});

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  bool get _canSave => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add note',
              style: AppTextStyles.rowTitle
                  .copyWith(fontSize: 17, color: AppColors.ink)),
          const SizedBox(height: 14),
          TextField(
            controller: widget.controller,
            maxLines: 5,
            autofocus: true,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Left voicemail, sent estimate, visited site…',
              hintStyle:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.inkFaint),
              filled: true,
              fillColor: AppColors.page,
              contentPadding: const EdgeInsets.all(13),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    const BorderSide(color: AppColors.line, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                    color: AppColors.greenDeep, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _canSave
                    ? AppColors.orange500
                    : AppColors.orange500.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _canSave
                  ? () {
                      final text = widget.controller.text.trim();
                      Navigator.pop(context);
                      widget.onSave(text);
                    }
                  : null,
              child: const Text(
                'Save note',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: primary
            ? AppColors.orange500
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Column(
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
  final VoidCallback? onCopy;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.grayTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.inkSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkFaint,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined,
                  size: 16, color: AppColors.inkFaint),
            ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final LeadNote note;
  final bool showDivider;
  final VoidCallback onDelete;

  const _NoteRow({
    required this.note,
    required this.onDelete,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final date = note.createdDateUtc?.toLocal();
    final dateStr = date == null
        ? ''
        : '${_month(date.month)} ${date.day}, ${date.year}';

    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkFaint,
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  note.noteText ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline,
                size: 17, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }

  String _month(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}
