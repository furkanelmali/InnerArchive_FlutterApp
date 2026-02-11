import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/theme/app_colors.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/rating_slider.dart';

class EditMediaScreen extends ConsumerStatefulWidget {
  final String? itemId;
  final MediaItem? searchResult;

  const EditMediaScreen({super.key, this.itemId, this.searchResult});

  @override
  ConsumerState<EditMediaScreen> createState() => _EditMediaScreenState();
}

class _EditMediaScreenState extends ConsumerState<EditMediaScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  MediaType _type = MediaType.movie;
  MediaStatus _status = MediaStatus.watchlist;
  int? _rating;

  MediaItem? _source;

  bool get _isEditing => widget.itemId != null;
  bool get _isFromSearch => widget.searchResult != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final item = ref
          .read(mediaProvider)
          .asData
          ?.value
          .where((e) => e.id == widget.itemId)
          .firstOrNull;
      if (item != null) _prefill(item);
    } else if (_isFromSearch) {
      _prefill(widget.searchResult!);
    }
  }

  void _prefill(MediaItem item) {
    _source = item;
    _titleController.text = item.title;
    _descriptionController.text = item.description ?? '';
    _noteController.text = item.note ?? '';
    _type = item.type;
    _status = item.status;
    _rating = item.rating;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final notifier = ref.read(mediaProvider.notifier);

    if (_isEditing) {
      final existing = ref
          .read(mediaProvider)
          .asData
          ?.value
          .firstWhere((e) => e.id == widget.itemId);
      if (existing != null) {
        notifier.updateItem(existing.copyWith(
          title: title,
          description: _descriptionController.text.trim(),
          type: _type,
          status: _status,
          rating: _rating,
          note: _noteController.text.trim(),
          updatedAt: now,
        ));
      }
    } else {
      notifier.add(MediaItem(
        id: now.millisecondsSinceEpoch.toString(),
        externalId: _source?.externalId,
        title: title,
        description: _descriptionController.text.trim(),
        imageUrl: _source?.imageUrl,
        releaseDate: _source?.releaseDate,
        type: _type,
        status: _status,
        rating: _rating,
        note: _noteController.text.trim(),
        createdAt: now,
        updatedAt: now,
      ));
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit' : 'Add to Library'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: theme.textTheme.headlineMedium,
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 24),
              _buildDropdown<MediaType>(
                label: 'Type',
                value: _type,
                items: MediaType.values,
                itemLabel: (t) => t.label,
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              _buildDropdown<MediaStatus>(
                label: 'Status',
                value: _status,
                items: MediaStatus.values,
                itemLabel: (s) => s.label,
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              RatingSlider(
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _descriptionController,
                style: theme.textTheme.bodyLarge,
                maxLines: null,
                minLines: 4,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const Divider(height: 32),
              TextField(
                controller: _noteController,
                style: theme.textTheme.bodyLarge,
                maxLines: null,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Personal notes (optional)',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceLight,
              style: Theme.of(context).textTheme.bodyLarge,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(itemLabel(item)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

}
