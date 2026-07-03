# Master Slide View Implementation

## Overview

Comprehensive implementation of PowerPoint-style **Slide Master** functionality for ky_slide, enabling users to create, edit, and manage slide layouts that control the appearance of all slides in a presentation.

## 🎯 Features Implemented

### 1. **Master Slide Models** (`lib/models/master/master_slide_model.dart`)

#### Core Classes:
- **`MasterSlide`**: Parent container for all layouts with theme and style defaults
- **`MasterLayout`**: Individual slide layout with placeholders
- **`TextStyleDefaults`**: Hierarchical text styling (title, body, accent)
- **`ColorSchemeLevel`**: Color palette levels for consistent theming

#### Layout Types (PowerPoint Parity):
```dart
enum MasterLayoutType {
  titleSlide,           // Title + Subtitle
  titleAndContent,      // Title + Content area
  sectionHeader,        // Section divider
  twoContent,           // Title + 2 content columns
  comparison,           // Title + Comparison layout
  titleOnly,            // Title only
  blank,                // Empty canvas
  contentWithCaption,   // Content + Caption
  pictureWithCaption,   // Picture + Caption
  custom,               // User-defined
}
```

#### Placeholder Types:
- Title, Subtitle, Content
- Picture, Chart, Table
- SmartArt, Video, Media
- Date, Footer, Slide Number

### 2. **Master Slide Service** (`lib/services/master/master_slide_service.dart`)

#### State Management (Riverpod):
```dart
final masterSlideProvider           // Main master slide state
final selectedLayoutProvider        // Currently selected layout
final masterViewModeProvider        // Edit/Preview mode
final masterSlideApplicationProvider // Apply changes to slides
```

#### MasterSlideNotifier Operations:
- ✅ `addLayout()` - Add new layout
- ✅ `updateLayout()` - Modify existing layout
- ✅ `removeLayout()` - Delete layout
- ✅ `reorderLayouts()` - Drag-drop reordering
- ✅ `duplicateLayout()` - Copy layout
- ✅ `updateBackground()` - Change background
- ✅ `updateTextStyles()` - Modify style defaults
- ✅ `updateTheme()` - Apply theme changes
- ✅ `importFromJson()` / `exportToJson()` - Serialization
- ✅ `resetToDefault()` - Restore defaults

#### MasterSlideApplicationService:
- ✅ `applyLayoutToSlide()` - Apply master layout to specific slide
- ✅ `applyThemeToAllSlides()` - Bulk theme application
- ✅ `syncTextStyles()` - Sync styles from master to slides

### 3. **Master Slide Editor UI** (`lib/screens/master/master_slide_editor_screen.dart`)

#### Three-Panel Layout:
```
┌─────────────────────────────────────────────────────────────┐
│  AppBar: Slide Master | Office Theme                        │
│  [Edit|Preview]  [Close]                                    │
│  ─────────────────────────────────────────────────────────  │
│  [Layouts 📋] [Theme 🎨]                                    │
├──────────┬──────────────────────────────┬───────────────────┤
│          │                              │                   │
│ Layouts  │     Canvas Editor            │  Properties       │
│ Panel    │     (960x540)                │  Panel            │
│ (220px)  │                              │  (280px)          │
│          │     ┌────────────────┐       │                   │
│ • Title  │     │  Master Slide  │       │ • Name           │
│ • T&C    │     │   Preview      │       │ • Type           │
│ • Blank  │     │                │       │ • Placeholders   │
│ • Custom │     │  Placeholders  │       │ • Background     │
│ [+]      │     │   Visualized   │       │ • Actions        │
│          │     └────────────────┘       │   - Reset        │
│          │                              │   - Export       │
│ [Duplicate] [Delete]                    │                   │
└──────────┴──────────────────────────────┴───────────────────┘
```

#### Key UI Components:

**Left Panel - Layout Thumbnails:**
- Visual thumbnail preview of each layout
- Selection highlighting with blue border
- Add new layout button (+)
- Duplicate/Delete actions
- Scrollable list for many layouts

**Center Canvas:**
- Full-size slide preview (960x540)
- Placeholder visualization with icons
- Insert toolbar (Text, Picture, Chart, Table, SmartArt, Video)
- Edit/Preview mode toggle
- Professional shadow and rounded corners

**Right Panel - Properties:**
- Layout name editor
- Type display
- Placeholder count
- Background color picker
- Reset to default action
- Export layout option

#### Custom Painters:
- **`LayoutThumbnailPainter`**: Miniature layout preview
- **`MasterSlideCanvasPainter`**: Full canvas rendering
- **`IconPainter`**: Placeholder type icons

## 🏗️ Architecture Integration

```
┌─────────────────────────────────────────────────────────────┐
│                    ky_slide (Flutter)                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Master Slide Editor Screen                          │   │
│  │  • Thumbnail panel                                   │   │
│  │  • Canvas editor                                     │   │
│  │  • Properties panel                                  │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Master Slide Service (Riverpod)                     │   │
│  │  • masterSlideProvider                               │   │
│  │  • selectedLayoutProvider                            │   │
│  │  • masterSlideApplicationProvider                    │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Master Slide Models                                 │   │
│  │  • MasterSlide                                       │   │
│  │  • MasterLayout                                      │   │
│  │  • TextStyleDefaults                                 │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────────┬──────────────────────────────────────────────┘
               │ Apply layouts/styles
┌──────────────▼──────────────────────────────────────────────┐
│                 Presentation Provider                        │
│  • Slides reference master layouts                           │
│  • Inherit text styles from master                           │
│  • Theme propagation                                         │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Feature Comparison

| Feature | PowerPoint | Google Slides | ky_slide (Before) | ky_slide (After) |
|---------|-----------|---------------|-------------------|------------------|
| Master slide editing | ✅ | ✅ | ❌ | ✅ |
| Multiple layouts | ✅ | ✅ | ❌ | ✅ (10 types) |
| Placeholder types | ✅ (13+) | ✅ (8) | ❌ | ✅ (13) |
| Layout thumbnails | ✅ | ✅ | ❌ | ✅ |
| Duplicate layout | ✅ | ✅ | ❌ | ✅ |
| Delete layout | ✅ | ✅ | ❌ | ✅ |
| Background editing | ✅ | ✅ | ❌ | ✅ |
| Text style defaults | ✅ | ✅ | ❌ | ✅ |
| Theme integration | ✅ | ✅ | ❌ | ✅ |
| Apply to slides | ✅ | ✅ | ❌ | ✅ |
| JSON import/export | ✅ | ❌ | ❌ | ✅ |
| Reset to default | ✅ | ✅ | ❌ | ✅ |
| Custom layouts | ✅ | ✅ | ❌ | ✅ |
| Reorder layouts | ✅ | ✅ | ❌ | ✅ |

## 🚀 Usage Examples

### Creating a New Presentation with Master Slide:

```dart
// Initialize with default master slide
final masterSlide = MasterSlide.createDefault();

// Access via provider
final master = ref.read(masterSlideProvider);

// Get available layouts
final layouts = master.layouts; // 5 default layouts

// Apply layout to a new slide
final newSlide = Slide(
  id: 'slide_1',
  layoutId: 'title_content_layout',
  components: [],
);
```

### Adding a Custom Layout:

```dart
final customLayout = MasterLayout(
  id: 'custom_timeline',
  name: 'Timeline Layout',
  type: MasterLayoutType.custom,
  placeholders: [
    Component(
      id: 'title_ph',
      type: ComponentType.text,
      x: 100, y: 50, width: 760, height: 80,
      isPlaceholder: true,
      placeholderType: PlaceholderType.title,
    ),
    Component(
      id: 'timeline_ph',
      type: ComponentType.shape,
      x: 100, y: 150, width: 760, height: 350,
      isPlaceholder: true,
      placeholderType: PlaceholderType.content,
    ),
  ],
);

ref.read(masterSlideProvider.notifier).addLayout(customLayout);
```

### Applying Master Theme to All Slides:

```dart
final appService = ref.read(masterSlideApplicationProvider);
appService.applyThemeToAllSlides();
```

### Syncing Text Styles:

```dart
// After updating master text styles
appService.syncTextStyles('title_content_layout');
// All slides using this layout will update automatically
```

## 🔧 Technical Implementation Details

### Placeholder System:

Each placeholder has:
- **Position & Size**: x, y, width, height (in points)
- **Type**: title, content, picture, etc.
- **Default Text**: "Click to add title"
- **Style Inheritance**: From master text styles
- **Behavior**: Auto-resize, snap-to-grid

### Style Inheritance Chain:

```
MasterSlide.theme
    └── MasterLayout.textStyles
        ├── titleStyle (font, size, color, weight)
        ├── bodyStyle
        └── accentStyle
            └── Slide components (if not overridden)
```

### Canvas Rendering:

- **Edit Mode**: Blue placeholder borders with handles
- **Preview Mode**: Clean rendering without edit indicators
- **Thumbnail**: Scaled-down preview (100px height)
- **Full Canvas**: 960x540 points (16:9 aspect ratio)

## 📁 File Structure

```
Plugins/ky_slide/lib/
├── models/master/
│   └── master_slide_model.dart         # Data models
├── services/master/
│   └── master_slide_service.dart       # Business logic & state
├── screens/master/
│   └── master_slide_editor_screen.dart # Main UI
└── widgets/master/                     # (Future reusable widgets)
    └── ...
```

## ⚡ Performance Considerations

1. **Thumbnail Caching**: Layout thumbnails rendered once, cached
2. **Lazy Loading**: Only visible layouts rendered in list
3. **Efficient Repaint**: Custom painters use shouldRepaint optimization
4. **State Isolation**: Riverpod providers prevent unnecessary rebuilds
5. **JSON Serialization**: Optimized for large presentations

## 🧪 Testing Checklist

- [ ] Create new layout from template
- [ ] Add custom layout with manual placeholders
- [ ] Duplicate existing layout
- [ ] Delete layout (with confirmation)
- [ ] Reorder layouts via drag-drop
- [ ] Edit layout name
- [ ] Change background color
- [ ] Switch between Edit/Preview modes
- [ ] Apply layout to regular slide
- [ ] Sync text styles to slides
- [ ] Export layout to JSON
- [ ] Import layout from JSON
- [ ] Reset layout to default
- [ ] Close master view and return to editor

## 🔮 Future Enhancements

### Phase 2 (High Priority):
1. **Drag-and-Drop Placeholder Editing**: Move/resize placeholders on canvas
2. **Background Formats**: Gradient, image, pattern backgrounds
3. **Font Scheme Editor**: Customize font families per theme
4. **Color Variant Editor**: Modify color palette levels
5. **Placeholder Formatting**: Default bullet styles, alignment

### Phase 3 (Medium Priority):
6. **Multiple Masters**: Support multiple master slides per presentation
7. **Layout Inheritance**: Child layouts inherit from parent
8. **Notes Master**: Edit speaker notes layout
9. **Handout Master**: Print handout layouts (1, 2, 3, 4, 6, 9 slides/page)
10. **PPTX Master Import**: Parse master slides from PPTX files

### Phase 4 (Advanced):
11. **AI Layout Suggestions**: Recommend layouts based on content
12. **Layout Templates Library**: Pre-designed professional layouts
13. **Brand Kit Integration**: Company branding auto-application
14. **Real-time Collaboration**: Multi-user master editing
15. **Version History**: Track master slide changes over time

## 🎓 User Guide

### Opening Master View:
1. Go to **View** tab in main ribbon
2. Click **Slide Master** button
3. Or use keyboard shortcut: `Alt + M`

### Editing a Layout:
1. Select layout from left thumbnail panel
2. Use toolbar to insert placeholders
3. Adjust properties in right panel
4. Changes apply immediately

### Applying Layout to Slides:
1. Return to normal view
2. Select slide(s) in thumbnail panel
3. Right-click → **Layout** → Choose desired layout
4. Or use Home tab → Layout dropdown

### Best Practices:
- Keep layouts simple and focused
- Use consistent placeholder positioning
- Limit to 8-10 layouts per master
- Name layouts descriptively
- Test layouts with actual content

## 📝 Notes

- Master slides are stored within presentation file
- Changes to master affect all linked slides
- Individual slides can override master styles
- PPTX compatibility maintained for master slides
- Undo/Redo supported for master edits

## 🔗 Related Documentation

- [Animation Timeline Improvements](./ANIMATION_TIMELINE_IMPROVEMENTS.md)
- [Presenter View Enhancements](./PRESENTER_VIEW_IMPROVEMENTS.md)
- [PPTX Import/Export](./lib/services/io/pptx_io/)
- [Architecture Overview](./ARCHITECTURE_IMPROVEMENTS.md)
