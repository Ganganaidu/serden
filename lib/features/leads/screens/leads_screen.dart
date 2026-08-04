import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../../core/widgets/pill_tabs.dart';
import '../models/lead_model.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  // Real leads API isn't wired up yet — show sample data only in
  // mock mode; a real logged-in user starts with none (empty state).
  final List<Lead> _leads = AppConfig.useMockData ? mockLeads : const [];
  int _tabIndex = 0;
  String _search = '';

  bool _inTab(Lead lead, int tab) => switch (tab) {
        0 => lead.status == LeadStatus.newLead,
        1 => lead.status == LeadStatus.contacted ||
            lead.status == LeadStatus.quoted,
        2 => lead.status == LeadStatus.won,
        _ => true,
      };

  List<Lead> get _filtered {
    final q = _search.trim().toLowerCase();
    return _leads
        .where((l) =>
            _inTab(l, _tabIndex) &&
            (q.isEmpty ||
                l.name.toLowerCase().contains(q) ||
                l.project.toLowerCase().contains(q) ||
                l.place.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final newCount =
        _leads.where((l) => l.status == LeadStatus.newLead).length;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Leads',
            subtitleSpans: newCount > 0
                ? [
                    TextSpan(
                      text: '$newCount new',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' · reply fast to win the job'),
                  ]
                : [
                    const TextSpan(
                        text: 'All caught up — nothing waiting on you'),
                  ],
            actions: [
              HeaderIconButton(
                icon: Icons.notifications_outlined,
                showDot: true,
                onTap: () {},
              ),
            ],
            bottom: HeaderSearchBar(
              hint: 'Search name, project, or city',
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          PillTabs(
            tabs: [
              PillTab('New',
                  count: _leads.where((l) => _inTab(l, 0)).length,
                  activeColor: AppColors.orange500),
              PillTab('Working',
                  count: _leads.where((l) => _inTab(l, 1)).length),
              PillTab('Won', count: _leads.where((l) => _inTab(l, 2)).length),
              PillTab('All', count: _leads.length),
            ],
            selectedIndex: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
          Expanded(child: _list()),
        ],
      ),
      floatingActionButton: AppFab(label: 'Add lead', onPressed: () {}),
    );
  }

  Widget _list() {
    final rows = _filtered;
    if (rows.isEmpty) {
      final searching = _search.trim().isNotEmpty;
      return EmptyState(
        title: searching
            ? 'No matches'
            : (_tabIndex == 0 ? 'No new leads right now' : 'Nothing here yet'),
        description: searching
            ? 'Try a different name, project, or city.'
            : (_tabIndex == 0
                ? 'New requests from homeowners near you will land here.'
                : 'Leads in this stage will show up here.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: rows.length,
      itemBuilder: (context, index) => _LeadRow(lead: rows[index]),
    );
  }
}

class _LeadRow extends StatelessWidget {
  final Lead lead;
  const _LeadRow({required this.lead});

  @override
  Widget build(BuildContext context) {
    final isNew = lead.status == LeadStatus.newLead;
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: AppColors.line),
              left: isNew
                  ? const BorderSide(color: AppColors.orange500, width: 3)
                  : BorderSide.none,
            ),
          ),
          padding: EdgeInsets.fromLTRB(isNew ? 17 : 20, 14, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      lead.name,
                      style: AppTextStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    lead.time,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: lead.fresh
                          ? AppColors.orangeDeep
                          : AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                lead.project,
                style: AppTextStyles.bodySmall
                    .copyWith(fontSize: 13.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 2),
              Text(lead.place, style: AppTextStyles.caption),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statusChip(),
                  Row(
                    children: [
                      _QuickButton(
                          icon: Icons.call_outlined, onTap: () {}),
                      const SizedBox(width: 8),
                      _QuickButton(
                          icon: Icons.chat_bubble_outline, onTap: () {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip() {
    final (bg, fg, icon, label) = switch (lead.status) {
      LeadStatus.newLead => (
          AppColors.orangeTint,
          AppColors.orangeDeep,
          Icons.bolt_outlined,
          'New — reach out'
        ),
      LeadStatus.contacted => (
          AppColors.grayTint,
          AppColors.grayDeep,
          Icons.chat_bubble_outline,
          'Contacted'
        ),
      LeadStatus.quoted => (
          AppColors.greenTint,
          AppColors.greenDeep,
          Icons.send_outlined,
          'Estimate sent'
        ),
      LeadStatus.won => (
          AppColors.greenDeep,
          Colors.white,
          Icons.check,
          'Won'
        ),
      LeadStatus.lost => (
          AppColors.redTint,
          AppColors.redDeep,
          Icons.close,
          'Lost'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.chip.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuickButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.greenTint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 16, color: AppColors.greenDeep),
        ),
      ),
    );
  }
}
