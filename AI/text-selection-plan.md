# Text Selection Implementation Plan

## Overview
Add text selection capabilities to Clarify Swift app while preserving current UI/UX and functionality.

## Current State Analysis
- ✅ App uses native SwiftUI `Text` views for all text rendering
- ✅ No embedded web browser - all content rendered natively  
- ✅ Text rendering functions: `headingView()`, `paragraphView()`, `bionicText()`, `richParagraphView()`, `quoteView()`, `listView()`
- ✅ Advanced reading features: Center Stage, Tunnel Vision, Bionic Reading
- ✅ Custom typography with font selection, sizing, line spacing

## Implementation Strategy
Replace SwiftUI `Text` with `UITextView` wrapped in `UIViewRepresentable` to enable text selection while preserving all styling and functionality.

## Task Breakdown

### 🏗️ Phase 1: Core Infrastructure

#### Task 1.1: Create SelectableTextView Component
- [ ] Create `SelectableTextView.swift` with `UIViewRepresentable`
- [ ] Wrap `UITextView` with text selection enabled
- [ ] Match current font, color, and spacing exactly
- [ ] **Verification**: Text displays identically to current implementation

#### Task 1.2: Create Text Selection State Manager
- [ ] Create `TextSelectionManager.swift` for managing selections
- [ ] Track selected text ranges and content
- [ ] Handle selection events and callbacks
- [ ] **Verification**: Can detect and store text selections

### 🔄 Phase 2: Replace Text Components

#### Task 2.1: Replace paragraphView()
- [ ] Update `paragraphView()` to use `SelectableTextView`
- [ ] Preserve font customization (size, family, line spacing)
- [ ] Maintain bionic reading functionality
- [ ] **Verification**: Paragraphs look identical but are selectable

#### Task 2.2: Replace headingView()
- [ ] Update `headingView()` to use `SelectableTextView`
- [ ] Preserve heading hierarchy styling (H1-H6)
- [ ] Maintain serif font and sizing
- [ ] **Verification**: Headings look identical but are selectable

#### Task 2.3: Replace quoteView()
- [ ] Update `quoteView()` to use `SelectableTextView`
- [ ] Preserve italic styling and left border
- [ ] Maintain author attribution
- [ ] **Verification**: Quotes look identical but are selectable

#### Task 2.4: Replace listView()
- [ ] Update `listView()` to use `SelectableTextView` for each item
- [ ] Preserve bullet/number formatting
- [ ] Maintain proper indentation
- [ ] **Verification**: Lists look identical but are selectable

### ⚡ Phase 3: Advanced Text Handling

#### Task 3.1: Handle richParagraphView()
- [ ] Create attributed string support for bold/italic/links
- [ ] Preserve link functionality and styling
- [ ] Maintain text segment formatting
- [ ] **Verification**: Rich text displays and behaves identically

#### Task 3.2: Integrate Reading Features
- [ ] Ensure Center Stage scaling works with `UITextView`
- [ ] Implement Tunnel Vision blur with selectable text
- [ ] Adapt Bionic Reading to work with `UITextView`
- [ ] **Verification**: All reading features work as before

### 🎯 Phase 4: Selection & Highlighting

#### Task 4.1: Implement Text Selection
- [ ] Enable text selection gestures
- [ ] Handle selection state across different text views
- [ ] Provide selection feedback (highlight color)
- [ ] **Verification**: Can select text across paragraphs

#### Task 4.2: Add Highlight Rendering
- [ ] Create highlight overlay system
- [ ] Persist selected text ranges
- [ ] Render highlights with custom colors
- [ ] **Verification**: Selected text stays highlighted

#### Task 4.3: Selection Context Menu
- [ ] Add context menu for selected text
- [ ] Prepare hooks for future actions (copy, share, etc.)
- [ ] **Verification**: Context menu appears on selection

### ✨ Phase 5: Polish & Integration

#### Task 5.1: Performance Optimization
- [ ] Optimize `UITextView` rendering for long articles
- [ ] Implement text view recycling if needed
- [ ] **Verification**: Smooth scrolling maintained

#### Task 5.2: Accessibility
- [ ] Ensure VoiceOver works with selectable text
- [ ] Maintain current accessibility features
- [ ] **Verification**: Screen reader functionality preserved

## Key Technical Considerations

1. **Styling Preservation**: Each `SelectableTextView` must exactly match current `Text` appearance
2. **State Management**: Selection state needs to persist across view updates
3. **Performance**: `UITextView` is heavier than `Text` - optimize accordingly
4. **Gesture Conflicts**: Ensure selection doesn't interfere with scrolling/navigation
5. **Reading Features**: All current reading enhancements must work with new components

## Verification Strategy

After each task:
1. **Visual Comparison**: Side-by-side before/after screenshots
2. **Feature Testing**: All reading features still work
3. **Performance Check**: No noticeable lag or memory issues
4. **Selection Testing**: Text selection works smoothly

## Files to Modify

### New Files to Create:
- `SelectableTextView.swift` - Core selectable text component
- `TextSelectionManager.swift` - Selection state management

### Existing Files to Modify:
- `ArticleDetailView.swift` - Replace text rendering functions
- Potentially `Article.swift` - If selection data needs to be stored

## Progress Tracking

**Phase 1**: ⏳ Not Started  
**Phase 2**: ⏳ Not Started  
**Phase 3**: ⏳ Not Started  
**Phase 4**: ⏳ Not Started  
**Phase 5**: ⏳ Not Started  

---

*Last Updated: 2025-10-21*  
*Branch: feature/text-selection*
