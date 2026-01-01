import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Enhanced search bar with recent searches and suggestions
class SearchBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onSearch;
  final ValueChanged<String>? onChanged;
  final List<String>? recentSearches;
  final VoidCallback? onClearRecent;
  final bool autofocus;
  final TextEditingController? controller;

  const SearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onSearch,
    this.onChanged,
    this.recentSearches,
    this.onClearRecent,
    this.autofocus = false,
    this.controller,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _controller;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      setState(() {
        _showClear = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onSubmit(String value) {
    if (value.trim().isNotEmpty) {
      widget.onSearch?.call(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.offWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            onSubmitted: _onSubmit,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: AppTheme.gray),
              prefixIcon: const Icon(Icons.search, color: AppTheme.gray),
              suffixIcon: _showClear
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged?.call('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        
        // Recent Searches
        if (widget.recentSearches != null && widget.recentSearches!.isNotEmpty && !_showClear) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal,
                  fontSize: 14,
                ),
              ),
              if (widget.onClearRecent != null)
                TextButton(
                  onPressed: widget.onClearRecent,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.recentSearches!.map((search) {
              return GestureDetector(
                onTap: () {
                  _controller.text = search;
                  _onSubmit(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.lightGray),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 16, color: AppTheme.gray),
                      const SizedBox(width: 6),
                      Text(search, style: TextStyle(color: AppTheme.charcoal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Filter chips row for category/status filtering
class FilterChips extends StatelessWidget {
  final List<String> filters;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool showAll;

  const FilterChips({
    super.key,
    required this.filters,
    this.selected,
    required this.onSelected,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showAll)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: selected == null,
                onSelected: (_) => onSelected(null),
                selectedColor: AppTheme.primaryRed.withOpacity(0.15),
                checkmarkColor: AppTheme.primaryRed,
                labelStyle: TextStyle(
                  color: selected == null ? AppTheme.primaryRed : AppTheme.charcoal,
                  fontWeight: selected == null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ...filters.map((filter) {
            final isSelected = filter == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => onSelected(filter),
                selectedColor: AppTheme.primaryRed.withOpacity(0.15),
                checkmarkColor: AppTheme.primaryRed,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryRed : AppTheme.charcoal,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
