import 'dart:typed_data';
import 'package:flutter/material.dart';

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

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _windowLevel += details.delta.dy;
      _windowWidth += details.delta.dx;
      _windowLevel = _windowLevel.clamp(-255, 510);
      _windowWidth = _windowWidth.clamp(1, 1020);
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
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onPanUpdate: _onPanUpdate,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 10,
              child: Center(
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
            ),
          ),
        ),
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
