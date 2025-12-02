import 'package:flutter/material.dart';
import '../api/contexts.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

class ContextSelector extends StatelessWidget {
  final List<ContextRequest> selectedContexts;
  final Function(String) onContextAdded;
  final Function(int) onContextRemoved;

  const ContextSelector({
    super.key,
    required this.selectedContexts,
    required this.onContextAdded,
    required this.onContextRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.cardPaddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wybierz konteksty',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildContextChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildContextChips() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: ContextsApi.availableContextTypes.map((contextType) {
        final isSelected = selectedContexts.any((c) => c.contextType == contextType);
        return FilterChip(
          label: Text(
            ContextsApi.getContextTypeDisplayName(contextType),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onContextAdded(contextType);
            } else {
              final index = selectedContexts.indexWhere((c) => c.contextType == contextType);
              if (index != -1) {
                onContextRemoved(index);
              }
            }
          },
          tooltip: ContextsApi.getContextTypeDescription(contextType),
          backgroundColor: AppColors.white,
          selectedColor: AppColors.primary.withOpacity(0.1),
          checkmarkColor: AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        );
      }).toList(),
    );
  }
}
