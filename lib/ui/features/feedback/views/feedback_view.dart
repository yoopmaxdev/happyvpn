import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/app_view_model.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final TextEditingController _messageController = TextEditingController();
  bool _includeDiagnostics = true;
  bool _showPreview = false;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the problem first.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final openedMail = await widget.viewModel.submitFeedback(
        message: text,
        includeDiagnostics: _includeDiagnostics,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              openedMail
                  ? 'Opening email app to send feedback.'
                  : 'No email app found. Feedback copied — email ${AppViewModel.supportEmail}.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final diagnostics = widget.viewModel.buildDiagnosticsPreview();

    return Scaffold(
      appBar: AppBar(title: const Text('Send feedback')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Opens your email app addressed to ${AppViewModel.supportEmail}. Do not include passwords or sensitive personal information.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 5,
            minLines: 4,
            decoration: const InputDecoration(
              labelText: 'Describe the problem',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Include diagnostic details'),
                  subtitle: const Text(
                    'Connection states, timings, app version, and platform.',
                  ),
                  value: _includeDiagnostics,
                  onChanged: (v) => setState(() => _includeDiagnostics = v),
                ),
                if (_includeDiagnostics) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Review diagnostic details'),
                    trailing: Icon(
                      _showPreview
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    onTap: () => setState(() => _showPreview = !_showPreview),
                  ),
                  if (_showPreview)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SelectableText(
                              diagnostics,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: diagnostics),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Report copied'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('Copy report'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSending ? null : _send,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _isSending ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
