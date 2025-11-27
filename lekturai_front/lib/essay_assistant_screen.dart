import 'package:flutter/material.dart';
import 'api/contexts.dart';

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
          content: Text('Proszę wprowadzić tytuł rozprawki i wybrać przynajmniej jeden kontekst'),
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

      final contexts = await _contextsApi.getContexts(request);
      setState(() {
        _generatedContexts = contexts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas generowania kontekstów: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildContextSelector() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wybierz konteksty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ContextsApi.availableContextTypes.map((contextType) {
                final isSelected = _selectedContexts.any((c) => c.contextType == contextType);
                return FilterChip(
                  label: Text(contextType),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _addContext(contextType);
                    } else {
                      final index = _selectedContexts.indexWhere((c) => c.contextType == contextType);
                      if (index != -1) {
                        _removeContext(index);
                      }
                    }
                  },
                  tooltip: ContextsApi.getContextTypeDescription(contextType),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContexts() {
    if (_selectedContexts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wybrane konteksty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedContexts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final contextRequest = _selectedContexts[index];
                final controller = _contextDescriptions[contextRequest.contextType]!;
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ContextsApi.getContextTypeDisplayName(contextRequest.contextType),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _removeContext(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ContextsApi.getContextTypeDescription(contextRequest.contextType),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Dodaj dodatkowy opis lub preferencje (opcjonalnie)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                        onChanged: (value) => _updateContextDescription(index, value),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedContexts() {
    if (_generatedContexts == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wygenerowane konteksty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _generatedContexts!.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final generatedContext = _generatedContexts![index];
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ContextsApi.getContextTypeDisplayName(generatedContext.contextType),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        generatedContext.contextTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        generatedContext.contextDescription,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asystent Rozprawki'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tytuł rozprawki',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Wprowadź tytuł rozprawki...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            _buildContextSelector(),
            _buildSelectedContexts(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateContexts,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Generowanie...' : 'Wygeneruj konteksty'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            _buildGeneratedContexts(),
          ],
        ),
      ),
    );
  }
}
