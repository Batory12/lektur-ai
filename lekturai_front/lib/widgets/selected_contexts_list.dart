import 'package:flutter/material.dart';
import '../api/contexts.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

class SelectedContextsList extends StatelessWidget {
  final List<ContextRequest> selectedContexts;
  final Map<String, TextEditingController> contextDescriptions;
  final Function(int) onContextRemoved;
  final Function(int, String) onDescriptionChanged;

  const SelectedContextsList({
    super.key,
    required this.selectedContexts,
    required this.contextDescriptions,
    required this.onContextRemoved,
    required this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedContexts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.cardPaddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wybrane konteksty',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedContexts.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _buildSelectedContextItem(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContextItem(int index) {
    final contextRequest = selectedContexts[index];
    final controller = contextDescriptions[contextRequest.contextType]!;
    
    return Container(
      padding: AppSpacing.cardPaddingAll,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContextHeader(contextRequest, index),
          const SizedBox(height: AppSpacing.sm),
          _buildContextDescription(contextRequest.contextType),
          const SizedBox(height: AppSpacing.md),
          _buildDescriptionField(controller, index),
        ],
      ),
    );
  }

  Widget _buildContextHeader(ContextRequest contextRequest, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            ContextsApi.getContextTypeDisplayName(contextRequest.contextType),
            style: AppTextStyles.heading4,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.error),
          onPressed: () => onContextRemoved(index),
          tooltip: 'Usuń kontekst',
        ),
      ],
    );
  }

  Widget _buildContextDescription(String contextType) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        ContextsApi.getContextTypeDescription(contextType),
        style: AppTextStyles.bodySmall,
      ),
    );
  }

  Widget _buildDescriptionField(TextEditingController controller, int index) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: 'Dodaj dodatkowy opis lub preferencje (opcjonalnie)',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.all(AppSpacing.md),
      ),
      maxLines: 2,
      style: AppTextStyles.bodyMedium,
      onChanged: (value) => onDescriptionChanged(index, value),
    );
  }
}
