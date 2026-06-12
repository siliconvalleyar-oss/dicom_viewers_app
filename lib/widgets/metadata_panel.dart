import 'package:flutter/material.dart';
import 'package:dicom_parser/dicom_parser.dart';
import '../services/dicom_loader.dart';

/// Tags DICOM considerados importantes para mostrar al usuario.
const _importantTagDescriptions = [
  'Patient Name',
  'Patient ID',
  'Patient Birth Date',
  'Patient Sex',
  'Patient Age',
  'Patient Weight',
  'Patient Size',
  'Study Date',
  'Study Time',
  'Study Description',
  'Study ID',
  'Accession Number',
  'Modality',
  'Manufacturer',
  'Manufacturer Model Name',
  'Institution Name',
  'Station Name',
  'Series Description',
  'Series Number',
  'Series Date',
  'Series Time',
  'Body Part Examined',
  'Protocol Name',
  'Slice Thickness',
  'Spacing Between Slices',
  'Pixel Spacing',
  'Rows',
  'Columns',
  'Bits Allocated',
  'Bits Stored',
  'High Bit',
  'Pixel Representation',
  'Rescale Intercept',
  'Rescale Slope',
  'Window Center',
  'Window Width',
  'SOP Class UID',
  'SOP Instance UID',
  'Study Instance UID',
  'Series Instance UID',
];

class MetadataPanel extends StatelessWidget {
  final DicomStudyFile studyFile;

  const MetadataPanel({super.key, required this.studyFile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = studyFile.tags;

    // Filtrar solo tags importantes, manteniendo el orden
    final importantTags = tags.where((t) =>
        _importantTagDescriptions.any((desc) =>
            t.tagDescription.toLowerCase() == desc.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Metadata',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${importantTags.length} tags',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Tags importantes
        Expanded(
          child: importantTags.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No metadata available',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline)),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: importantTags.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final tag = importantTags.elementAt(index);
                    return _TagTile(tag: tag, theme: theme);
                  },
                ),
        ),

        // Footer con info del archivo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 14, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  studyFile.fileName,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagTile extends StatelessWidget {
  final TagModel tag;
  final ThemeData theme;

  const _TagTile({required this.tag, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isHighlightedTag(tag.tagDescription);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label column
          SizedBox(
            width: 130,
            child: Text(
              tag.tagDescription,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                color: isHighlighted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Value column
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? theme.colorScheme.primaryContainer.withAlpha(80)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag.value,
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isHighlightedTag(String description) {
    const highlighted = [
      'Patient Name',
      'Patient ID',
      'Study Description',
      'Modality',
      'Series Description',
    ];
    return highlighted.any((h) => h.toLowerCase() == description.toLowerCase());
  }
}
