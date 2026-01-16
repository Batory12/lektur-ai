import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api/contexts.dart';
import 'theme/colors.dart';
import 'theme/spacing.dart';
import 'theme/text_styles.dart';
import 'widgets/context_selector.dart';
import 'widgets/selected_contexts_list.dart';
import 'widgets/essay_contexts_result.dart';
import 'widgets/common_scaffold.dart';

class EssayAssistantScreen extends StatefulWidget {
  const EssayAssistantScreen({super.key});

  @override
  State<EssayAssistantScreen> createState() => _EssayAssistantScreenState();
}

class _EssayAssistantScreenState extends State<EssayAssistantScreen> {
  final TextEditingController _titleController = TextEditingController();
  final List<ContextRequest> _selectedContexts = [];
  final Map<String, TextEditingController> _contextDescriptions = {};
  List<Context>? _generatedContexts;
  bool _isLoading = false;
  bool _isUsingMockData = false;
  String? _apiErrorMessage;
  late ContextsApi _contextsApi;

  @override
  void initState() {
    super.initState();
    _contextsApi = ContextsApi();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _contextDescriptions.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addContext(String contextType) {
    setState(() {
      final contextRequest = ContextRequest(
        contextType: contextType,
        contextAdditionalDescription: '',
      );
      _selectedContexts.add(contextRequest);
      _contextDescriptions[contextType] = TextEditingController();
    });
  }

  void _removeContext(int index) {
    setState(() {
      final contextType = _selectedContexts[index].contextType;
      _selectedContexts.removeAt(index);
      _contextDescriptions[contextType]?.dispose();
      _contextDescriptions.remove(contextType);
    });
  }

  void _updateContextDescription(int index, String description) {
    setState(() {
      _selectedContexts[index] = ContextRequest(
        contextType: _selectedContexts[index].contextType,
        contextAdditionalDescription: description,
      );
    });
  }

  Future<void> _generateContexts() async {
    if (_titleController.text.isEmpty || _selectedContexts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proszę wprowadzić tytuł rozprawki i wybrać przynajmniej jeden kontekst',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = EssayContextsRequest(
        title: _titleController.text,
        contexts: _selectedContexts,
      );

      final result = await _contextsApi.getContexts(request);
      setState(() {
        _generatedContexts = result.contexts;
        _isUsingMockData = result.isMockData;
        _apiErrorMessage = result.errorMessage;
      });

      // Show info message if using mock data
      if (result.isMockData && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Błąd połączenia z serwerem. Pokazano przykładowe konteksty.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nieoczekiwany błąd: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateMockContexts() async {
    if (_titleController.text.isEmpty || _selectedContexts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proszę wprowadzić tytuł rozprawki i wybrać przynajmniej jeden kontekst',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final request = EssayContextsRequest(
      title: _titleController.text,
      contexts: _selectedContexts,
    );

    setState(() {
      _generatedContexts = ContextsApi.generateMockContexts(request);
      _isUsingMockData = true;
      _apiErrorMessage = 'Mock data generated for testing';
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wygenerowano przykładowe konteksty do testowania'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _testApiError() async {
    if (_titleController.text.isEmpty || _selectedContexts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proszę wprowadzić tytuł rozprawki i wybrać przynajmniej jeden kontekst',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call with error
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      throw Exception('Simulated network error for testing');
    } catch (e) {
      final request = EssayContextsRequest(
        title: _titleController.text,
        contexts: _selectedContexts,
      );

      setState(() {
        _generatedContexts = ContextsApi.generateMockContexts(request);
        _isUsingMockData = true;
        _apiErrorMessage = 'Simulated API error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Błąd połączenia z serwerem. Pokazano przykładowe konteksty.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTitleCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.cardPaddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tytuł rozprawki', style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Wprowadź tytuł rozprawki...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(AppSpacing.md),
              ),
              maxLines: 2,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSelector() {
    return ContextSelector(
      selectedContexts: _selectedContexts,
      onContextAdded: _addContext,
      onContextRemoved: _removeContext,
    );
  }

  Widget _buildSelectedContexts() {
    return SelectedContextsList(
      selectedContexts: _selectedContexts,
      contextDescriptions: _contextDescriptions,
      onContextRemoved: _removeContext,
      onDescriptionChanged: _updateContextDescription,
    );
  }

  Widget _buildGeneratedContexts() {
    if (_generatedContexts == null) {
      return const SizedBox.shrink();
    }

    return EssayContextsResult(
      essayTitle: _titleController.text,
      contexts: _generatedContexts!,
      onRegenerate: _generateContexts,
      isMockData: _isUsingMockData,
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generateContexts,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isLoading ? 'Generowanie...' : 'Wygeneruj konteksty'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDebugButtons() {
    // Show debug buttons only in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _generateMockContexts,
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text(
                  'Test: Mock Data',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  side: BorderSide(color: Colors.blue.shade300),
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _testApiError,
                icon: const Icon(Icons.error_outline, size: 16),
                label: const Text(
                  'Test: API Error',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  side: BorderSide(color: Colors.orange.shade300),
                  foregroundColor: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _generatedContexts = null;
                    _isUsingMockData = false;
                    _apiErrorMessage = null;
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text(
                  'Clear Results',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ),
            if (_apiErrorMessage != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: _apiErrorMessage!,
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Asystent Rozprawki',
      showDrawer: true,
      useResponsiveLayout: false,
      useSafeArea: false, // SafeArea is applied directly to body below
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800.0),
            child: SingleChildScrollView(
              padding: AppSpacing.safeAreaPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleCard(),
                  _buildContextSelector(),
                  _buildSelectedContexts(),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  _buildGenerateButton(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDebugButtons(),
                  _buildGeneratedContexts(),
                  // Add extra bottom padding to ensure content is always visible
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
