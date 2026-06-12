import 'dart:typed_data';
import 'package:flutter/material.dart';

enum AdjustMode { windowLevel, zoom }

class DicomImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String? modality;

  const DicomImageViewer({
    super.key,
    required this.imageBytes,
    this.modality,
  });

  @override
  State<DicomImageViewer> createState() => _DicomImageViewerState();
}

class _DicomImageViewerState extends State<DicomImageViewer> {
  final TransformationController _transformController =
      TransformationController();

  double _windowWidth = 255;
  double _windowLevel = 128;
  AdjustMode _adjustMode = AdjustMode.windowLevel;
  bool _showDragHud = false;

  void _onPanStart(DragStartDetails details) {
    setState(() => _showDragHud = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _windowLevel += details.delta.dy;
      _windowWidth += details.delta.dx;
      _windowLevel = _windowLevel.clamp(-255, 510);
      _windowWidth = _windowWidth.clamp(1, 1020);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _showDragHud = false);
  }

  void _onDoubleTap() {
    resetWindowLevel();
    // Flash HUD briefly as confirmation
    setState(() => _showDragHud = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showDragHud = false);
    });
  }

  void resetWindowLevel() {
    setState(() {
      _windowWidth = 255;
      _windowLevel = 128;
    });
  }

  void resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _toggleMode() {
    setState(() {
      _adjustMode = _adjustMode == AdjustMode.windowLevel
          ? AdjustMode.zoom
          : AdjustMode.windowLevel;
    });
  }

  List<double> _buildColorMatrix() {
    final c = _windowWidth / 255;
    final b = (_windowLevel - 128) / 255;
    return [
      c, 0, 0, 0, b,
      0, c, 0, 0, b,
      0, 0, c, 0, b,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWlMode = _adjustMode == AdjustMode.windowLevel;

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // InteractiveViewer handles zoom/pan
              InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 10,
                panEnabled: !isWlMode,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(_buildColorMatrix()),
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image,
                      size: 64,
                    ),
                  ),
                ),
              ),

              // Transparent overlay for WW/WL drag (only in WL mode)
              if (isWlMode)
                GestureDetector(
                  onDoubleTap: _onDoubleTap,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Container(color: Colors.transparent),
                ),

              // WW/WL drag HUD (floating values overlay)
              if (isWlMode)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showDragHud ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      child: Center(
                        child: _WwHud(
                          windowWidth: _windowWidth,
                          windowLevel: _windowLevel,
                        ),
                      ),
                    ),
                  ),
                ),

              // Mode toggle button
              Positioned(
                top: 8,
                left: 8,
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withAlpha(200),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _toggleMode,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isWlMode
                                ? Icons.touch_app
                                : Icons.pan_tool,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isWlMode ? 'WW/WL' : 'Zoom',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // WW/WL sliders
        _WindowLevelBar(
          windowWidth: _windowWidth,
          windowLevel: _windowLevel,
          onChanged: (w, l) {
            setState(() {
              _windowWidth = w;
              _windowLevel = l;
            });
          },
        ),

        // Bottom actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _ActionChip(
                icon: Icons.refresh,
                label: 'WW/WL',
                onTap: resetWindowLevel,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.zoom_out_map,
                label: 'Reset Zoom',
                onTap: resetZoom,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: isWlMode ? Icons.pan_tool_outlined : Icons.touch_app_outlined,
                label: isWlMode ? 'Zoom mode' : 'WW/WL mode',
                onTap: _toggleMode,
              ),
              if (widget.modality != null) ...[
                const Spacer(),
                Chip(
                  label: Text(
                    widget.modality!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WindowLevelBar extends StatelessWidget {
  final double windowWidth;
  final double windowLevel;
  final void Function(double width, double level) onChanged;

  const _WindowLevelBar({
    required this.windowWidth,
    required this.windowLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.contrast, size: 18),
              const SizedBox(width: 8),
              const Text('WW', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: windowWidth,
                  min: 1,
                  max: 1020,
                  divisions: 1019,
                  label: 'WW: ${windowWidth.round()}',
                  onChanged: (v) => onChanged(v, windowLevel),
                ),
              ),
              Text('${windowWidth.round()}',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.brightness_6, size: 18),
              const SizedBox(width: 8),
              const Text('WL', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: windowLevel,
                  min: -255,
                  max: 510,
                  divisions: 765,
                  label: 'WL: ${windowLevel.round()}',
                  onChanged: (v) => onChanged(windowWidth, v),
                ),
              ),
              Text('${windowLevel.round()}',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Floating HUD that appears during WW/WL drag, showing real-time values.
class _WwHud extends StatelessWidget {
  final double windowWidth;
  final double windowLevel;

  const _WwHud({
    required this.windowWidth,
    required this.windowLevel,
  });

  @override
  Widget build(BuildContext context) {
    final wwValue = windowWidth.round();
    final wlValue = windowLevel.round();

    // Normalize for progress bars (WW: 1-1020, WL: -255 to 510)
    final wwProgress = ((windowWidth - 1) / (1020 - 1)).clamp(0.0, 1.0);
    final wlProgress = ((windowLevel + 255) / (510 + 255)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WW — Window Width (contrast)
          _HudColumn(
            label: 'WW',
            value: '$wwValue',
            progress: wwProgress,
            barColor: Colors.blueAccent,
            icon: Icons.contrast,
          ),
          const SizedBox(width: 24),
          // WL — Window Level (brightness)
          _HudColumn(
            label: 'WL',
            value: '$wlValue',
            progress: wlProgress,
            barColor: Colors.orangeAccent,
            icon: Icons.brightness_6,
          ),
        ],
      ),
    );
  }
}

class _HudColumn extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color barColor;
  final IconData icon;

  const _HudColumn({
    required this.label,
    required this.value,
    required this.progress,
    required this.barColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: Colors.white54),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            width: 56,
            height: 4,
            color: Colors.white24,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
    );
  }
}
