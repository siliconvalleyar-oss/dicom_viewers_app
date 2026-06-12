import 'package:flutter/material.dart';
import '../services/dicom_loader.dart';
import '../widgets/dicom_image_viewer.dart';
import '../widgets/metadata_panel.dart';

/// Full-screen viewer with gallery, patient info overlay, and metadata.
class ViewerScreen extends StatefulWidget {
  final List<DicomStudyFile> studies;
  final int initialIndex;

  const ViewerScreen({
    super.key,
    required this.studies,
    this.initialIndex = 0,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DicomStudyFile get _currentStudy => widget.studies[_currentIndex];

  void _showMetadata() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 200),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MetadataPanel(studyFile: _currentStudy),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final study = _currentStudy;
    final total = widget.studies.length;
    final hasMultiple = total > 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              study.patientName ?? 'Unknown Patient',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (study.modality != null || study.studyDate != null)
              Text(
                [
                  if (study.modality != null) study.modality!,
                  if (study.studyDate != null) study.studyDate!,
                  if (study.patientId != null) 'ID: ${study.patientId}',
                ].join(' · '),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Metadata',
            onPressed: _showMetadata,
          ),
        ],
      ),
      body: Column(
        children: [
          // Main image viewer with PageView for swiping
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // PageView with images
                PageView.builder(
                  controller: _pageController,
                  itemCount: total,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final s = widget.studies[index];
                    return DicomImageViewer(
                      imageBytes: s.imageBytes,
                      modality: s.modality,
                    );
                  },
                ),

                // Patient info overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(160),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Patient name and ID
                            Text(
                              study.patientName ?? 'Unknown Patient',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Info line
                            Row(
                              children: [
                                if (study.patientId != null)
                                  _OverlayTag(
                                    label: study.patientId!,
                                    icon: Icons.badge_outlined,
                                  ),
                                if (study.patientId != null &&
                                    study.modality != null)
                                  const SizedBox(width: 6),
                                if (study.modality != null)
                                  _OverlayTag(
                                    label: study.modality!,
                                    icon: Icons.monitor_heart_outlined,
                                  ),
                                if (study.modality != null &&
                                    study.studyDate != null)
                                  const SizedBox(width: 6),
                                if (study.studyDate != null)
                                  _OverlayTag(
                                    label: study.studyDate!,
                                    icon: Icons.calendar_today_outlined,
                                  ),
                              ],
                            ),
                            if (study.studyDescription != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                study.studyDescription!,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 11,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Image counter overlay (bottom-right)
                if (hasMultiple)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Thumbnail strip (only when multiple images)
          if (hasMultiple)
            Container(
              height: 72,
              color: theme.colorScheme.surfaceContainerHighest,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                itemCount: total,
                itemBuilder: (context, index) {
                  final s = widget.studies[index];
                  final isSelected = index == _currentIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
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
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              s.imageBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image,
                                size: 20,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                color: theme.colorScheme.primary.withAlpha(30),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Nav buttons (prev/next) with counter
          if (hasMultiple)
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentIndex > 0
                        ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / $total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentIndex < total - 1
                        ? () => _pageController.nextPage(
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

/// Small chip for overlay tags (patient ID, modality, date)
class _OverlayTag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _OverlayTag({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white.withAlpha(200)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
