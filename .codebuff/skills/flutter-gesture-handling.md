# Flutter Gesture Handling for Image Viewers

## The Problem
Multiple gesture handlers (PageView swipe, InteractiveViewer zoom/pan, custom drag for WW/WL) conflict with each other. Resolved by using a **mode toggle** approach.

## Solution: Mode Toggle

```dart
enum AdjustMode { windowLevel, zoom }

// State
AdjustMode _adjustMode = AdjustMode.windowLevel;

// Toggle
void _toggleMode() => setState(() {
  _adjustMode = _adjustMode == AdjustMode.windowLevel
      ? AdjustMode.zoom
      : AdjustMode.windowLevel;
});
```

### In WW/WL Mode:
- `InteractiveViewer(panEnabled: false)` — disables pan but keeps pinch zoom
- Transparent `GestureDetector` overlay with **4 callbacks**:
  - `onDoubleTap` → reset WW/WL + flash HUD for 600ms confirmation
  - `onPanStart` → show floating HUD with current WW/WL values
  - `onPanUpdate` → update values (dy=WL/brightness, dx=WW/contrast) + HUD
  - `onPanEnd` → hide HUD
- HUD uses `AnimatedOpacity` for smooth 200ms fade in/out
- Pinch zoom still works via InteractiveViewer

**⚠️ Trade-off:** Adding `onDoubleTap` alongside `onPan*` introduces ~300ms delay before the pan gesture starts (Flutter's gesture arena waits for potential second tap).

### In Zoom Mode:
- `InteractiveViewer(panEnabled: true)` — full pan and zoom
- No GestureDetector overlay
- Single finger drag = pan, two fingers = pinch zoom

## Safe Area for Bottom Navigation
When placing buttons at the bottom, use `MediaQuery` padding to avoid system navigation bar:

```dart
Container(
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).padding.bottom + 24,  // + extra for clearance
  ),
  color: theme.colorScheme.surfaceContainerHighest,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(icon: const Icon(Icons.chevron_left), ...),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$current / $total', ...),
      ),
      IconButton(icon: const Icon(Icons.chevron_right), ...),
    ],
  ),
)
```

**⚠️ Do NOT use `SafeArea` + `MediaQuery.padding.bottom` together** — it creates double padding. Use only `MediaQuery.padding.bottom + X` where X is extra clearance (e.g., `+24`).

## Patient Info Overlay with IgnorePointer
To show info on top of an interactive image:

```dart
Stack(
  children: [
    // Interactive content below
    PageView(...),
    // Non-interactive overlay above
    Positioned(
      top: 0,
      child: IgnorePointer(
        child: Container(
          gradient: LinearGradient(...),
          child: SafeArea(child: Text(patientName, ...)),
        ),
      ),
    ),
  ],
)
```

## Key Principles
1. **Don't nest competing GestureDetectors** — one will consume events meant for the other
2. **Use `IgnorePointer`** for overlays that should be visual-only
3. **Use `panEnabled`** on InteractiveViewer to control single-finger behavior
4. **Mode toggle** is simpler than trying to detect finger count or gesture type
5. **Thumbnail strip** provides reliable navigation when swipe gestures conflict with image controls
