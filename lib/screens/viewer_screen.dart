import 'package:flutter/material.dart';
import '../services/dicom_loader.dart';
import '../widgets/dicom_image_viewer.dart';
import '../widgets/metadata_panel.dart';

class ViewerScreen extends StatelessWidget {
  final DicomStudyFile studyFile;

  const ViewerScreen({super.key, required this.studyFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          studyFile.patientName ?? studyFile.fileName,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Toggle metadata',
            onPressed: () => _showMetadata(context),
          ),
        ],
      ),
      body: DicomImageViewer(
        imageBytes: studyFile.imageBytes,
        modality: studyFile.modality,
      ),
    );
  }

  void _showMetadata(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 200),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MetadataPanel(studyFile: studyFile),
      ),
    );
  }
}
