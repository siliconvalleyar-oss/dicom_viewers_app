# DICOM Image Viewer

## Core Components

### DicomImageViewer
- Shows DICOM image with adjustable window width/level
- Supports pinch zoom via InteractiveViewer
- Has mode toggle: WW/WL drag mode vs Zoom/Pan mode

### Mode Toggle Pattern
```dart
enum AdjustMode { windowLevel, zoom }

// In build:
InteractiveViewer(
  transformationController: _transformController,
  minScale: 1.0,        // start at fill-level, can only zoom in
  maxScale: 10,
  panEnabled: !isWlMode, // disable pan in WL mode
  child: ColorFiltered(  // ⚠️ NO Center wrapper!
    colorFilter: ColorFilter.matrix(_buildColorMatrix()),
    child: Image.memory(
      imageBytes,
      fit: BoxFit.contain,  // fills width, maintains aspect ratio
    ),
  ),
)

// Transparent overlay for WW/WL drag (only in WL mode)
if (isWlMode)
  GestureDetector(
    onPanStart: _onPanStart,  // show HUD
    onPanUpdate: _onPanUpdate, // update values + HUD
    onPanEnd: _onPanEnd,       // hide HUD
    child: Container(color: Colors.transparent),
  )
```

### 📊 WW/WL Drag HUD (Heads-Up Display)
A floating overlay shows real-time WW (contrast) and WL (brightness) values while dragging. Appears with fade animation:

```dart
// State
bool _showDragHud = false;

void _onPanStart(DragStartDetails) => setState(() => _showDragHud = true);
void _onPanEnd(DragEndDetails) => setState(() => _showDragHud = false);

// In Stack overlay:
if (isWlMode)
  Positioned(
    bottom: 50,
    left: 0, right: 0,
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
  );
```

### _WwHud Widget
```dart
class _WwHud extends StatelessWidget {
  final double windowWidth;
  final double windowLevel;

  @override
  Widget build(BuildContext context) {
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
          _HudColumn(
            label: 'WW', value: '$wwValue',
            progress: wwProgress,
            barColor: Colors.blueAccent,
            icon: Icons.contrast,
          ),
          const SizedBox(width: 24),
          _HudColumn(
            label: 'WL', value: '$wlValue',
            progress: wlProgress,
            barColor: Colors.orangeAccent,
            icon: Icons.brightness_6,
          ),
        ],
      ),
    );
  }
}
```

### _HudColumn Widget
```dart
class _HudColumn extends StatelessWidget {
  // Shows icon + label + large value + progress bar
  // Uses FontFeature.tabularFigures() to prevent number jitter
  // Progress bar: FractionallySizedBox(widthFactor: progress)
}
```

### ⚠️ Critical: No Center wrapper!
**Do NOT wrap the image in a `Center` widget** inside `InteractiveViewer`:
- `Center` gives **loose constraints** → image renders at its **natural (small) size**
- Without `Center`, `InteractiveViewer` gives **tight constraints** → `Image.memory` with `BoxFit.contain` **fills the available width** while maintaining aspect ratio
- If zoom doesn't seem to work, it's likely because the image was rendering at its natural small size → removing `Center` fixes both zoom visibility and width

### Window Width/Level Formula
```dart
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

// Apply:
ColorFilter.matrix(_buildColorMatrix())
```

## Patient Info Overlay
Overlay on top of image showing patient data:
- Name (bold, white text with shadow)
- ID, Modality, Date (small chips with icons)
- Study Description

```dart
Stack(
  children: [
    DicomImageViewer(...),
    Positioned(
      top: 0,
      child: IgnorePointer(  // allows gestures to pass through
        child: Container(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withAlpha(160), Colors.transparent],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Text(patientName, style: TextStyle(color: Colors.white, ...)),
                Row(children: [_OverlayTag(...), ...]),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
)
```

## Gallery (Multiple Images)
Use `PageView.builder` for swiping between images, with a `ListView.builder` thumbnail strip below:

```dart
PageView.builder(
  controller: _pageController,
  itemCount: total,
  onPageChanged: (index) => setState(() => _currentIndex = index),
  itemBuilder: (context, index) => DicomImageViewer(...),
)

// Thumbnail strip
ListView.builder(
  scrollDirection: Axis.horizontal,
  itemCount: total,
  itemBuilder: (context, index) => GestureDetector(
    onTap: () => _pageController.animateToPage(index, ...),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? primary : transparent),
      ),
      child: Image.memory(thumbnailBytes, fit: BoxFit.cover),
    ),
  ),
)
```

## Loading DICOM Tags by Hex Code
Search for DICOM tags in flattened tag list by hex code (more reliable than by description):

```dart
String? _getTagByHex(String hex) {
  final tag = tags.cast<TagModel?>().firstWhere(
        (t) => t?.getTag() == hex,
        orElse: () => null,
      );
  return tag?.value;
}

// Common tags:
// 0010,0010 = Patient Name
// 0010,0020 = Patient ID
// 0008,0020 = Study Date
// 0008,1030 = Study Description
// 0008,0060 = Modality
// 0008,103e = Series Description
```

## Important Metadata Tags (40 total)
Key tags to display: Patient Name, Patient ID, Study Date, Modality, Study Description, Manufacturer, Institution, Series Description, Slice Thickness, Pixel Spacing, Rows, Columns, Bits Allocated, Window Center, Window Width, SOP Class UID, etc.
