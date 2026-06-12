import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/orthanc_service.dart';
import '../services/dicom_loader.dart';
import '../widgets/metadata_panel.dart';
import '../widgets/dicom_image_viewer.dart';

class OrthancBrowser extends StatefulWidget {
  final OrthancService service;
  final String? label;

  const OrthancBrowser({super.key, required this.service, this.label});

  @override
  State<OrthancBrowser> createState() => OrthancBrowserState();
}

class OrthancBrowserState extends State<OrthancBrowser> {
  List<OrthancPatient> _patients = [];
  List<OrthancPatient> _filteredPatients = [];
  bool _isLoading = true;
  bool _isLoadingStudies = false;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Cache studies for date/accession search
  Map<String, List<OrthancStudy>> _patientStudies = {};

  // Date filter
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
        _filteredPatients = patients;
        _isLoading = false;
      });
      // Pre-load studies in background for search
      _loadAllStudies();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllStudies() async {
    setState(() => _isLoadingStudies = true);
    try {
      final studies = await widget.service.getStudiesForPatients(
        _patients.map((p) => p.id).toList(),
      );
      if (mounted) {
        setState(() {
          _patientStudies = studies;
          _isLoadingStudies = false;
          // Re-apply current filter with new data
          _applyFilter();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudies = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.toLowerCase());
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchQuery;
    final dateFrom = _dateFrom;
    final dateTo = _dateTo;

    if (query.isEmpty && dateFrom == null && dateTo == null) {
      setState(() => _filteredPatients = _patients);
      return;
    }

    setState(() {
      _filteredPatients = _patients.where((p) {
        final studies = _patientStudies[p.id] ?? [];

        // Check date range match
        bool matchesDate = true;
        if (dateFrom != null || dateTo != null) {
          matchesDate = studies.any((s) {
            if (s.date == null || s.date!.length != 8) return false;
            final y = int.tryParse(s.date!.substring(0, 4)) ?? 0;
            final m = int.tryParse(s.date!.substring(4, 6)) ?? 0;
            final d = int.tryParse(s.date!.substring(6, 8)) ?? 0;
            final studyDate = DateTime(y, m, d);
            if (dateFrom != null && studyDate.isBefore(dateFrom)) return false;
            if (dateTo != null && studyDate.isAfter(dateTo)) return false;
            return true;
          });
        }

        // Check text match in name/ID or study data
        bool matchesText = true;
        if (query.isNotEmpty) {
          final formattedName = _PatientTile.formatName(p.name).toLowerCase();
          final rawName = (p.name ?? '').toLowerCase();
          final nameMatch = rawName.contains(query) ||
              formattedName.contains(query) ||
              (p.patientId ?? '').toLowerCase().contains(query);

          if (nameMatch) {
            matchesText = true;
          } else {
            matchesText = studies.any((s) {
              // Search by date (supports YYYYMMDD, YYYY-MM-DD, DD/MM/YYYY)
              if (s.date != null && _normalizeDateQuery(s.date!).contains(query)) return true;
              // Search by accession number
              if (s.accessionNumber != null &&
                  s.accessionNumber!.toLowerCase().contains(query)) return true;
              // Search by description
              if (s.description != null &&
                  s.description!.toLowerCase().contains(query)) return true;
              return false;
            });
          }
        }

        return matchesDate && matchesText;
      }).toList();
    });
  }

  /// Normalize date YYYYMMDD to searchable formats
  String _normalizeDateQuery(String dateStr) {
    if (dateStr.length != 8) return dateStr.toLowerCase();
    final y = dateStr.substring(0, 4);
    final m = dateStr.substring(4, 6);
    final d = dateStr.substring(6, 8);
    return '$dateStr $y-$m-$d $d/$m/$y'.toLowerCase();
  }

  void _clearFilters() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _searchCtrl.clear();
      _searchQuery = '';
      _filteredPatients = _patients;
    });
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Filter by study date range',
    );
    if (range != null) {
      setState(() {
        _dateFrom = range.start;
        _dateTo = range.end;
      });
      _applyFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilter = _dateFrom != null || _dateTo != null || _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label ?? 'Orthanc'),
        actions: [
          if (hasActiveFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
            ),
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
                          style: theme.textTheme.titleMedium),
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
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by name, ID, date, accession...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => _searchCtrl.clear(),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // Date filter chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All dates',
                            selected: _dateFrom == null,
                            onSelected: () {
                              setState(() {
                                _dateFrom = null;
                                _dateTo = null;
                              });
                              _applyFilter();
                            },
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Last 7d',
                            selected: _dateFrom != null &&
                                _dateFrom == DateTime.now().subtract(const Duration(days: 7)),
                            onSelected: () {
                              setState(() {
                                _dateTo = DateTime.now();
                                _dateFrom = DateTime.now().subtract(const Duration(days: 7));
                              });
                              _applyFilter();
                            },
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Last 30d',
                            selected: _dateFrom != null &&
                                _dateFrom == DateTime.now().subtract(const Duration(days: 30)),
                            onSelected: () {
                              setState(() {
                                _dateTo = DateTime.now();
                                _dateFrom = DateTime.now().subtract(const Duration(days: 30));
                              });
                              _applyFilter();
                            },
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            avatar: const Icon(Icons.date_range, size: 14),
                            label: const Text('Range', style: TextStyle(fontSize: 11)),
                            onPressed: _pickDateRange,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    // Info bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${_filteredPatients.length} patients',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          if (hasActiveFilter)
                            Text(
                              ' (filtered)',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          if (_isLoadingStudies) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'loading studies...',
                              style: TextStyle(
                                fontSize: 10, color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Patient list
                    Expanded(
                      child: _filteredPatients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 48,
                                      color: theme.colorScheme.outlineVariant),
                                  const SizedBox(height: 12),
                                  Text('No patients match your search',
                                      style: TextStyle(
                                          color: theme.colorScheme.outline)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadPatients,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                itemCount: _filteredPatients.length,
                                itemBuilder: (_, i) => _PatientTile(
                                  patient: _filteredPatients[i],
                                  service: widget.service,
                                  cachedStudies: _patientStudies[_filteredPatients[i].id],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onSelected,
      color: selected
          ? WidgetStatePropertyAll(Theme.of(context).colorScheme.primaryContainer)
          : null,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PatientTile extends StatelessWidget {
  final OrthancPatient patient;
  final OrthancService service;
  final List<OrthancStudy>? cachedStudies;

  const _PatientTile({
    required this.patient,
    required this.service,
    this.cachedStudies,
  });

  /// Format DICOM name: replace ^ with spaces
  static String formatName(String? name) {
    if (name == null || name.isEmpty) return '';
    return name.replaceAll('^', ' ').trim();
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final clean = formatName(name);
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasName = patient.name != null && patient.name!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: hasName
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.errorContainer,
          radius: 22,
          child: Text(
            _getInitials(patient.name),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: hasName ? 14 : 18,
              color: hasName
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
        ),
        title: Text(
          hasName ? formatName(patient.name) : 'Unknown Patient',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (patient.patientId != null) 'ID: ${patient.patientId}',
            if (patient.birthDate != null && patient.birthDate!.isNotEmpty)
              patient.birthDate!,
            if (patient.sex != null && patient.sex!.isNotEmpty)
              patient.sex! == 'M' ? 'Male' : 'Female',
          ].join(' · '),
          style: const TextStyle(fontSize: 11),
        ),
        children: [
          _StudyList(
            patientId: patient.id,
            service: service,
            cachedStudies: cachedStudies,
          ),
        ],
      ),
    );
  }
}

class _StudyList extends StatefulWidget {
  final String patientId;
  final OrthancService service;
  final List<OrthancStudy>? cachedStudies;

  const _StudyList({
    required this.patientId,
    required this.service,
    this.cachedStudies,
  });

  @override
  State<_StudyList> createState() => _StudyListState();
}

class _StudyListState extends State<_StudyList> {
  List<OrthancStudy>? _studies;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cachedStudies != null) {
      _studies = widget.cachedStudies;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final studies = await widget.service.getStudies(widget.patientId);
    studies.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });
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
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(48, 8, 16, 4),
          child: Row(
            children: [
              Text(
                '${_studies!.length} studies',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ..._studies!.map((s) => _StudyTile(study: s, service: widget.service)),
      ],
    );
  }
}

class _StudyTile extends StatelessWidget {
  final OrthancStudy study;
  final OrthancService service;

  const _StudyTile({required this.study, required this.service});

  String _formatDate(String? date) {
    if (date == null || date.length != 8) return date ?? '';
    return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      title: Text(
        study.description ?? 'Study',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          if (study.date != null) ...[
            Icon(Icons.calendar_today, size: 10, color: theme.colorScheme.outline),
            const SizedBox(width: 3),
            Text(
              _formatDate(study.date),
              style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.collections, size: 10, color: theme.colorScheme.outline),
          const SizedBox(width: 3),
          Text(
            '${study.seriesCount} series',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
          ),
          if (study.accessionNumber != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.tag, size: 10, color: theme.colorScheme.outline),
            const SizedBox(width: 3),
            Text(
              study.accessionNumber!,
              style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
            ),
          ],
        ],
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
  List<Uint8List?> _images = [];
  bool _imageLoading = false;

  final DicomLoader _dicomLoader = DicomLoader();
  DicomStudyFile? _currentStudy;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    final instances = await widget.service.getInstances(widget.seriesId);
    if (mounted) {
      setState(() {
        _instances = instances;
        _loading = false;
        _images = List.filled(instances.length, null);
      });
      _pageController = PageController();
    }
    if (instances.isNotEmpty) _loadImage(0);
  }

  Future<void> _loadImage(int index) async {
    if (_instances == null || index >= _instances!.length) return;
    if (_images[index] != null) return;

    setState(() { _imageLoading = true; _currentIndex = index; });

    final dicomBytes = await widget.service.getDicomFile(_instances![index].id);
    if (dicomBytes != null) {
      final study = await _dicomLoader.loadFromBytes(
        bytes: dicomBytes,
        name: 'Instance ${_instances![index].instanceNumber ?? index + 1}',
      );
      if (mounted && study != null) {
        setState(() {
          _currentStudy = study;
          _images[index] = study.imageBytes;
          _imageLoading = false;
        });
        return;
      }
    }
    final preview = await widget.service.getPreview(_instances![index].id);
    if (mounted) {
      setState(() {
        _images[index] = preview;
        _imageLoading = false;
      });
    }
  }

  void _showMetadata() {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final total = _instances?.length ?? 0;
    final hasNav = total > 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instance ${_instances?[_currentIndex].instanceNumber ?? _currentIndex + 1}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '$total images · ${_currentStudy?.modality ?? ""}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          if (_currentStudy != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Metadata',
              onPressed: _showMetadata,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _imageLoading && _images[_currentIndex] == null
                ? const Center(child: CircularProgressIndicator())
                : PageView.builder(
                    controller: _pageController,
                    itemCount: total,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      _loadImage(index);
                    },
                    itemBuilder: (context, index) {
                      final img = _images[index];
                      if (img == null) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      return DicomImageViewer(
                        imageBytes: img,
                        modality: _currentStudy?.modality,
                      );
                    },
                  ),
          ),

          if (hasNav)
            Container(
              height: 72,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                itemCount: total,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController?.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_images[index] != null)
                              Image.memory(
                                _images[index]!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.broken_image,
                                  size: 20,
                                ),
                              )
                            else
                              const Icon(Icons.image, size: 20),
                            if (isSelected)
                              Container(
                                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (hasNav)
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentIndex > 0
                          ? () => _pageController?.previousPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentIndex < total - 1
                          ? () => _pageController?.nextPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
