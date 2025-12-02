import 'package:flutter/material.dart';
import '../api/contexts.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

class EssayContextsResult extends StatelessWidget {
  final String essayTitle;
  final List<Context> contexts;
  final VoidCallback? onRegenerate;
  final bool isMockData;

  const EssayContextsResult({
    super.key,
    required this.essayTitle,
    required this.contexts,
    this.onRegenerate,
    this.isMockData = false,
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
            _buildHeader(),
            if (isMockData) _buildMockDataWarning(),
            const SizedBox(height: AppSpacing.lg),
            _buildEssayTitle(),
            const SizedBox(height: AppSpacing.xl),
            _buildContextsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          color: AppColors.success,
          size: 24,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Wygenerowane konteksty',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.success,
            ),
          ),
        ),
        if (onRegenerate != null)
          IconButton(
            onPressed: onRegenerate,
            icon: const Icon(Icons.refresh),
            tooltip: 'Wygeneruj ponownie',
          ),
      ],
    );
  }

  Widget _buildEssayTitle() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingAll,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temat rozprawki:',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            essayTitle,
            style: AppTextStyles.heading4,
          ),
        ],
      ),
    );
  }

  Widget _buildContextsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proponowane konteksty:',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contexts.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => _buildContextItem(contexts[index], index + 1),
        ),
      ],
    );
  }

  Widget _buildContextItem(Context context, int number) {
    return Container(
      padding: AppSpacing.cardPaddingAll,
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContextHeader(context, number),
          const SizedBox(height: AppSpacing.sm),
          _buildContextTitle(context.contextTitle),
          const SizedBox(height: AppSpacing.sm),
          _buildContextDescription(context.contextDescription),
        ],
      ),
    );
  }

  Widget _buildContextHeader(Context context, int number) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            ContextsApi.getContextTypeDisplayName(context.contextType),
            style: AppTextStyles.successTitle,
          ),
        ),
        Icon(
          Icons.lightbulb_outline,
          color: AppColors.success,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildContextTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        title,
        style: AppTextStyles.contextTitle,
      ),
    );
  }

  Widget _buildContextDescription(String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        description,
        style: AppTextStyles.contextDescription,
      ),
    );
  }

  Widget _buildMockDataWarning() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: AppSpacing.cardPaddingAll,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Przykładowe konteksty (brak połączenia z serwerem)',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
