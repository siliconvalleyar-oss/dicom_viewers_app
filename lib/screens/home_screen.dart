import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/dicom_loader.dart';
import 'server_list_screen.dart';
import 'viewer_screen.dart';

class DicomAppState extends ChangeNotifier {
  final DicomLoader _loader = DicomLoader();
  final List<DicomStudyFile> _studies = [];
  bool _isLoading = false;

  List<DicomStudyFile> get studies => _studies;
  bool get isLoading => _isLoading;

  Future<void> pickAndLoadFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dcm'],
      allowMultiple: true,
    );
    if (result == null) return;

    _isLoading = true;
    notifyListeners();

    for (final file in result.files) {
      if (file.path == null) continue;
      final study = await _loader.loadFile(file.path!);
      if (study != null) {
        _studies.add(study);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDirectory() async {
    final dir = await FilePicker.getDirectoryPath();
    if (dir == null) return;

    _isLoading = true;
    notifyListeners();

    final dirObj = Directory(dir);
    final files = dirObj.listSync().whereType<File>().where(
          (f) => f.path.toLowerCase().endsWith('.dcm'),
        );

    for (final file in files) {
      final study = await _loader.loadFile(file.path);
      if (study != null) {
        _studies.add(study);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _studies.clear();
    notifyListeners();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _connectOrthanc(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ServerListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DicomAppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DICOM Viewer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_outlined),
            tooltip: 'Orthanc Server',
            onPressed: () => _connectOrthanc(context),
          ),
          if (state.studies.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: state.clear,
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.studies.isEmpty
              ? _EmptyState(theme: theme)
              : _StudyGrid(studies: state.studies),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'dir',
            onPressed: () => state.loadDirectory(),
            tooltip: 'Open directory',
            child: const Icon(Icons.folder_open),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'files',
            onPressed: () => state.pickAndLoadFiles(),
            tooltip: 'Select DICOM files',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            Text(
              'No DICOM files loaded',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to select .dcm files\nor the folder icon to pick a directory',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyGrid extends StatelessWidget {
  final List<DicomStudyFile> studies;

  const _StudyGrid({required this.studies});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: studies.length,
      itemBuilder: (context, index) {
        final study = studies[index];
        return Card(
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                study.imageBytes,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              study.patientName ?? 'Unknown Patient',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  study.fileName,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (study.modality != null)
                  Text(
                    'Modality: ${study.modality}',
                    style: const TextStyle(fontSize: 11),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewerScreen(
                    studies: studies,
                    initialIndex: index,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
