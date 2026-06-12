import 'package:flutter/material.dart';
import '../services/dicom_loader.dart';

class MetadataPanel extends StatelessWidget {
  final DicomStudyFile studyFile;

  const MetadataPanel({super.key, required this.studyFile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = studyFile.tags;

    final relevantTags = <String, String?>{
      'Patient Name': studyFile.patientName,
      'Patient ID': studyFile.patientId,
      'Study Date': studyFile.studyDate,
      'Modality': studyFile.modality,
      'Study Description': studyFile.studyDescription,
      'Series Description': studyFile.seriesDescription,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Metadata',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...relevantTags.entries
            .where((e) => e.value != null && e.value!.isNotEmpty)
            .map((e) => _MetadataRow(label: e.key, value: e.value!)),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'All DICOM Tags (${tags.length})',
            style: theme.textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return ListTile(
                dense: true,
                title: Text(
                  tag.tagDescription,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  tag.value,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: Text(
                  '(${tag.group},${tag.element})',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: theme.colorScheme.outline,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
