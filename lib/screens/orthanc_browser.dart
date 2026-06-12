import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/orthanc_service.dart';
import '../services/dicom_loader.dart';
import '../widgets/metadata_panel.dart';

class OrthancBrowser extends StatefulWidget {
  final OrthancService service;
  final String? label;

  const OrthancBrowser({super.key, required this.service, this.label});

  @override
  State<OrthancBrowser> createState() => OrthancBrowserState();
}

class OrthancBrowserState extends State<OrthancBrowser> {
  List<OrthancPatient> _patients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final patients = await widget.service.getPatients();
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label ?? 'Orthanc Server'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 64),
                      const SizedBox(height: 16),
                      Text('Connection error',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadPatients,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _patients.isEmpty
                  ? const Center(child: Text('No patients found'))
                  : RefreshIndicator(
                      onRefresh: _loadPatients,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _patients.length,
                        itemBuilder: (_, i) => _PatientTile(
                          patient: _patients[i],
                          service: widget.service,
                        ),
                      ),
                    ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final OrthancPatient patient;
  final OrthancService service;

  const _PatientTile({required this.patient, required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            (patient.name?.isNotEmpty == true
                    ? patient.name![0]
                    : '?')
                .toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: Text(patient.name ?? 'Unknown'),
        subtitle: Text(
          [
            if (patient.patientId != null) 'ID: ${patient.patientId}',
            if (patient.birthDate != null) patient.birthDate,
            if (patient.sex != null) patient.sex,
          ].join(' · '),
          style: const TextStyle(fontSize: 11),
        ),
        children: [
          _StudyList(patientId: patient.id, service: service),
        ],
      ),
    );
  }
}

class _StudyList extends StatefulWidget {
  final String patientId;
  final OrthancService service;

  const _StudyList({required this.patientId, required this.service});

  @override
  State<_StudyList> createState() => _StudyListState();
}

class _StudyListState extends State<_StudyList> {
  List<OrthancStudy>? _studies;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final studies = await widget.service.getStudies(widget.patientId);
    if (mounted) {
      setState(() { _studies = studies; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_studies == null || _studies!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No studies', style: TextStyle(fontSize: 12)),
      );
    }
    return Column(
      children: _studies!.map((s) => _StudyTile(study: s, service: widget.service)).toList(),
    );
  }
}

class _StudyTile extends StatelessWidget {
  final OrthancStudy study;
  final OrthancService service;

  const _StudyTile({required this.study, required this.service});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      title: Text(
        study.description ?? 'Study',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        [
          if (study.date != null) study.date!,
          '${study.seriesCount} series',
        ].join(' · '),
        style: const TextStyle(fontSize: 11),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _SeriesScreen(studyId: study.id, service: service),
          ),
        );
      },
    );
  }
}

class _SeriesScreen extends StatelessWidget {
  final String studyId;
  final OrthancService service;

  const _SeriesScreen({required this.studyId, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Series')),
      body: _SeriesList(studyId: studyId, service: service),
    );
  }
}

class _SeriesList extends StatefulWidget {
  final String studyId;
  final OrthancService service;

  const _SeriesList({required this.studyId, required this.service});

  @override
  State<_SeriesList> createState() => _SeriesListState();
}

class _SeriesListState extends State<_SeriesList> {
  List<OrthancSeries>? _series;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final series = await widget.service.getSeries(widget.studyId);
    if (mounted) setState(() { _series = series; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_series == null || _series!.isEmpty) {
      return const Center(child: Text('No series found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _series!.length,
      itemBuilder: (_, i) {
        final s = _series![i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              child: Text(
                s.modality ?? '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
            title: Text(
              'Series ${s.seriesNumber ?? ''}',
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              [
                if (s.description != null) s.description!,
                '${s.instanceCount} images',
              ].join(' · '),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _InstanceViewer(
                    seriesId: s.id,
                    service: widget.service,
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

class _InstanceViewer extends StatefulWidget {
  final String seriesId;
  final OrthancService service;

  const _InstanceViewer({required this.seriesId, required this.service});

  @override
  State<_InstanceViewer> createState() => _InstanceViewerState();
}

class _InstanceViewerState extends State<_InstanceViewer> {
  List<OrthancInstance>? _instances;
  bool _loading = true;
  int _currentIndex = 0;
  Uint8List? _currentImage;
  bool _imageLoading = false;

  final DicomLoader _dicomLoader = DicomLoader();
  DicomStudyFile? _currentStudy;

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    final instances = await widget.service.getInstances(widget.seriesId);
    if (mounted) setState(() { _instances = instances; _loading = false; });
    if (instances.isNotEmpty) _loadImage(0);
  }

  Future<void> _loadImage(int index) async {
    if (_instances == null || index >= _instances!.length) return;
    setState(() { _imageLoading = true; _currentIndex = index; });

    final dicomBytes = await widget.service.getDicomFile(_instances![index].id);
    if (dicomBytes != null) {
      final study = await _dicomLoader.loadFromBytes(
        bytes: dicomBytes,
        name: 'Instance ${_instances![index].instanceNumber ?? index + 1}',
      );
      if (mounted && study != null) {
        setState(() { _currentStudy = study; _currentImage = study.imageBytes; _imageLoading = false; });
        return;
      }
    }
    final preview = await widget.service.getPreview(_instances![index].id);
    if (mounted) setState(() { _currentImage = preview; _imageLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final total = _instances?.length ?? 0;
    final hasNav = total > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_instances?.firstOrNull?.instanceNumber ?? ""} ($total images)'),
        actions: [
          if (_currentStudy != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Metadata',
              onPressed: () => _showMetadata(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _imageLoading
                  ? const CircularProgressIndicator()
                  : _currentImage != null
                      ? Image.memory(_currentImage!, fit: BoxFit.contain)
                      : const Icon(Icons.broken_image, size: 64),
            ),
          ),
          if (hasNav)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentIndex > 0
                        ? () => _loadImage(_currentIndex - 1)
                        : null,
                  ),
                  Text('${_currentIndex + 1} / $total'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentIndex < total - 1
                        ? () => _loadImage(_currentIndex + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showMetadata(BuildContext context) {
    if (_currentStudy == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MetadataPanel(studyFile: _currentStudy!),
      ),
    );
  }
}
