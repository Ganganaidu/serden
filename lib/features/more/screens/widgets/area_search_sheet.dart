import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/company_profile_model.dart';

/// Search a city, county, state or ZIP code and pick one. With [freeText]
/// (the API's location list isn't set up yet) the typed text itself is added.
/// Returns the picked [ServiceArea], or null if dismissed.
Future<ServiceArea?> showAreaSearchSheet({
  required BuildContext context,
  required Future<List<ServiceArea>> Function(String query) search,
  bool freeText = false,
}) {
  return showModalBottomSheet<ServiceArea>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AreaSearch(search: search, freeText: freeText),
  );
}

class _AreaSearch extends StatefulWidget {
  final Future<List<ServiceArea>> Function(String) search;
  final bool freeText;
  const _AreaSearch({required this.search, required this.freeText});

  @override
  State<_AreaSearch> createState() => _AreaSearchState();
}

class _AreaSearchState extends State<_AreaSearch> {
  Timer? _debounce;
  List<ServiceArea> _results = const [];
  bool _loading = false;
  String _text = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _text = value.trim();
    _debounce?.cancel();
    if (_text.length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      final found = await widget.search(_text);
      // Ignore answers for text that has since changed.
      if (!mounted || value.trim() != _text) return;
      setState(() {
        _results = found;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add an area served',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              autofocus: true,
              onChanged: _onChanged,
              onSubmitted: (_) {
                if (widget.freeText && _text.isNotEmpty) {
                  Navigator.pop(context, ServiceArea(areaName: _text));
                }
              },
              decoration: InputDecoration(
                hintText: 'Type a city, county, state or ZIP code',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.page,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in _results)
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          title: Text(
                            r.areaName,
                            style: AppTextStyles.rowTitle,
                          ),
                          trailing: r.typeLabel == null
                              ? null
                              : Text(
                                  r.typeLabel!,
                                  style: AppTextStyles.caption,
                                ),
                          onTap: () => Navigator.pop(context, r),
                        ),
                      ),
                    if (_results.isEmpty && _text.length >= 2)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No matching locations'),
                      ),
                    // Without the standardized location list, any text can
                    // still be added as an area.
                    if (widget.freeText && _text.isNotEmpty)
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: const Icon(Icons.add),
                          title: Text('Add "$_text"'),
                          onTap: () => Navigator.pop(
                            context,
                            ServiceArea(areaName: _text),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
