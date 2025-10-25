import 'dart:io';
import 'dart:ui' as ui;
import 'package:flet/flet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../flutter_painter/flutter_painter.dart';
import 'dart:convert';

class FletPainterControl extends StatefulWidget {
  final Control? parent;
  final Control control;
  final List<Control> children;
  final bool parentDisabled;
  final bool? parentAdaptive;
  final FletControlBackend backend;

  const FletPainterControl({
    super.key,
    required this.parent,
    required this.control,
    required this.children,
    required this.parentDisabled,
    required this.parentAdaptive,
    required this.backend,
  });

  @override
  State<FletPainterControl> createState() => _FletPainterControlState();
}

class _FletPainterControlState extends State<FletPainterControl> {
  // Constants
  static const String _defaultText = "Text";
  static const double _defaultFontSize = 24.0;
  static const String _defaultFontFamily = 'Roboto';

  // Controllers and state
  late PainterController controller;
  final FocusNode _focusNode = FocusNode();
  Size? canvasSize;
  String defaultText = _defaultText;

  // Layer tracking
  final LayerManager _layerManager = LayerManager();

  @override
  void initState() {
    super.initState();
    _initController();
    _setupWidgets();

    widget.backend.subscribeMethods(widget.control.id, _handleInvokeMethod);
  }

  void _initController() {
    controller = PainterController();
    controller.addListener(_handleControllerUpdate);

    // Initialize text settings
    controller.textSettings = TextSettings(
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blue,
        fontSize: _defaultFontSize,
      ),
    );
  }

  void _handleControllerUpdate() {
    final sel = controller.selectedObjectDrawable;
    if (sel is TextDrawable) {
      _sendSelectedTextInfo();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    controller.dispose();

    // Отписка от методов
    widget.backend.unsubscribeMethods(widget.control.id);
    super.dispose();
  }

  // ===== Event Methods =====

  void _sendEvent(String name, [dynamic data]) {
    widget.backend
        .triggerControlEvent(widget.control.id, name, data?.toString() ?? "");
  }

  void _sendTextDoubleTapped() {
    final selectedDrawable = controller.selectedObjectDrawable;

    if (selectedDrawable is TextDrawable) {
      final data = {"value": selectedDrawable.text};
      _sendEvent("on_text_double_tap", jsonEncode(data));
    }
  }

  void _sendSelectedTextInfo() {
    final selectedDrawable = controller.selectedObjectDrawable;

    if (selectedDrawable is TextDrawable) {
      _sendEvent("on_selected_text", {
        "value": selectedDrawable.text,
        "style": selectedDrawable.style,
      });
    } else {
      _sendEvent("on_selected_text", {
        "value": null,
        "style": null,
      });
    }
  }

  // ===== Canvas Helper Methods =====

  Offset get _canvasCenter {
    if (canvasSize == null) return const Offset(100, 100);
    return Offset(canvasSize!.width / 2, canvasSize!.height / 2);
  }

  // ===== Text Style Helper Methods =====

  TextStyle _createTextStyle({
    String? fontFamily,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    // Try to get the style from Flet's text system first
    TextStyle? style;
    if (fontFamily != null) {
      try {
        style = getTextStyle(context, fontFamily);
      } catch (e) {
        debugPrint(
            "Font family '$fontFamily' not found in theme, using default");
        style = null;
      }
    }

    // If no style found or no font family specified, create basic style
    if (style == null) {
      style = TextStyle(
        fontFamily: fontFamily ?? _defaultFontFamily,
        fontSize: fontSize ?? _defaultFontSize,
        color: color ?? Colors.black,
        fontWeight: fontWeight ?? FontWeight.normal,
      );
    } else {
      // Merge with existing style
      style = style.copyWith(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );
    }

    return style;
  }

  // ===== Text Handling Methods =====

  void addText({
    String? fontFamily,
    String? text,
    double? x,
    double? y,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    final position = Offset(
      x ?? _canvasCenter.dx,
      y ?? _canvasCenter.dy,
    );

    final textDrawable = TextDrawable(
      position: position,
      text: text ?? defaultText,
      style: _createTextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
    );

    controller.addDrawables([textDrawable]);
  }

  void updateTextDrawable({
    String? newText,
    String? newFontFamily,
    double? newFontSize,
    Color? newColor,
    FontWeight? newFontWeight,
    double? newRotation,
    double? newScale,
  }) {
    final selectedDrawable = controller.selectedObjectDrawable;

    if (selectedDrawable is TextDrawable) {
      final baseStyle = selectedDrawable.style;

      // Always preserve existing values when not explicitly set
      final updatedText = newText ?? selectedDrawable.text;
      final updatedRotation = newRotation ?? selectedDrawable.rotationAngle;
      final updatedScale = newScale ?? selectedDrawable.scale;

      TextStyle updatedStyle;
      if (newFontFamily != null) {
        // Create new style with new font family
        updatedStyle = _createTextStyle(
          fontFamily: newFontFamily,
          fontSize: newFontSize ?? baseStyle.fontSize,
          color: newColor ?? baseStyle.color,
          fontWeight: newFontWeight ?? baseStyle.fontWeight,
        );
      } else {
        // Preserve existing font family, apply other changes
        updatedStyle = baseStyle.copyWith(
          color: newColor,
          fontSize: newFontSize,
          fontWeight: newFontWeight,
        );
      }

      // Create updated drawable with all preserved properties
      final updatedDrawable = selectedDrawable.copyWith(
        text: updatedText,
        style: updatedStyle,
        rotation: updatedRotation,
        scale: updatedScale,
      );

      // Update immediately with setState to ensure UI refresh
      setState(() {
        controller.replaceDrawable(selectedDrawable, updatedDrawable);
      });
    } else {
      debugPrint("No TextDrawable selected or invalid drawable type.");
    }
  }

  // ===== Image Handling Methods =====

  Future<void> addImage({
    required String path,
    double? x,
    double? y,
    double? scale,
  }) async {
    try {
      final file = File(path);

      if (!file.existsSync()) {
        debugPrint('Image file not found: $path');
        return;
      }

      final bytes = await file.readAsBytes();
      final codecData = await ui.instantiateImageCodec(bytes);
      final frame = await codecData.getNextFrame();
      final uiImage = frame.image;

      final position = Offset(
        x ?? _canvasCenter.dx,
        y ?? _canvasCenter.dy,
      );

      final imageDrawable = ImageDrawable(
        position: position,
        image: uiImage,
        scale: scale ?? 1.0,
      );

      controller.addDrawables([imageDrawable]);
    } catch (e) {
      debugPrint('Error adding image: $e');
    }
  }

  // ===== Save image =====

  Future<Uint8List?> exportImage(String? path, double scale) async {
    try {
      if (canvasSize == null) {
        debugPrint('Cannot export: canvas size is null');
        return null;
      }

      // If canvas size is too small, create a larger canvas for higher quality output
      final Size renderSize = Size(
        canvasSize!.width * scale,
        canvasSize!.height * scale,
      );

      final ui.Image renderedImage = await controller.renderImage(renderSize);
      final Uint8List? bytes = await renderedImage.pngBytes;

      if (path != null && bytes != null) {
        final file = File(path);
        try {
          await file.writeAsBytes(bytes);
          debugPrint('Image saved to: $path');
        } catch (e) {
          debugPrint('Error saving image to file: $e');
        }
      }

      return bytes;
    } catch (e) {
      debugPrint('Error exporting image: $e');
      return null;
    }
  }

  // ===== Layer Management =====

  void _setupWidgets() {
    var layersData = widget.control.attrList("layers");
    if (layersData == null) return;

    _processLayers(layersData);
  }

  void _processLayers(dynamic layersData) {
    if (layersData is List) {
      _processLayersList(layersData);
    } else if (layersData is Map<String, dynamic>) {
      _processSingleLayer(layersData);
    }

    // Update tracking
    _layerManager.previousLayers = layersData;
  }

  void _processLayersList(List layers) {
    for (var layer in layers) {
      String id = layer["id"] ?? "${layer.hashCode}";
      if (_layerManager.isProcessed(id)) continue;

      _processSingleLayer(layer);
      _layerManager.markProcessed(id);
    }
  }

  void _processSingleLayer(Map<String, dynamic> layer) {
    String id = layer["id"] ?? "${layer.hashCode}";
    if (_layerManager.isProcessed(id)) return;

    String type = layer["type"] ?? "";

    if (type == "text") {
      defaultText = layer["text"] ?? defaultText;
      addText(
        text: defaultText,
        fontFamily: layer["fontFamily"],
        color: parseColor(Theme.of(context), layer["color"]),
        fontSize: parseDouble(layer["fontSize"]),
        fontWeight: getFontWeight(layer["fontWeight"]),
      );
    } else if (type == "image") {
      addImage(
        path: layer["path"] ?? "",
        x: parseDouble(layer["x"]),
        y: parseDouble(layer["y"]),
        scale: parseDouble(layer["scale"]),
      );
    }

    _layerManager.markProcessed(id);
  }

  // ===== Deletion Methods =====

  void deleteSelected() {
    debugPrint('deleteSelected() called');
    final selectedDrawable = controller.selectedObjectDrawable;
    debugPrint('Selected drawable: $selectedDrawable');

    if (selectedDrawable != null) {
      debugPrint('Removing drawable...');
      setState(() {
        controller.removeDrawable(selectedDrawable);
      });
      // Restore focus after deletion
      _focusNode.requestFocus();
      debugPrint('Drawable removed successfully');
    } else {
      debugPrint('No drawable selected to delete');
    }
  }

  // ===== Method Invocation Handling =====

  Future<String?> _handleInvokeMethod(
      String methodName, Map<String, String> args) async {
    debugPrint("FletPainter.onMethod(${widget.control.id}): $methodName");

    var theme = Theme.of(context);

    switch (methodName) {
      case "addText":
        addText(
          text: args["text"],
          fontFamily: args["fontFamily"],
          x: parseDouble(args["x"]),
          y: parseDouble(args["y"]),
          fontSize: parseDouble(args["fontSize"]),
          color: parseColor(theme, args["color"]),
          fontWeight: getFontWeight(args["fontWeight"]),
        );
        break;

      case "addImage":
        addImage(
          path: args["path"] ?? "",
          x: parseDouble(args["x"]),
          y: parseDouble(args["y"]),
          scale: parseDouble(args["scale"]),
        );
        break;

      case "changeText":
        updateTextDrawable(
          newText: args["text"],
          newFontFamily: args["fontFamily"],
          newFontSize: parseDouble(args["fontSize"]),
          newColor: parseColor(theme, args["color"]),
          newFontWeight: getFontWeight(args["fontWeight"]),
          newRotation: parseDouble(args["rotation"]),
          newScale: parseDouble(args["scale"]),
        );
        break;

      case "saveImage":
        var path = args["path"];
        var scale = parseDouble(args["scale"]) ?? 1.0;
        var bytes = await exportImage(path, scale);
        return bytes != null ? "success" : "failed";

      case "saveImageBytes":
        var scale = parseDouble(args["scale"]) ?? 1.0;
        var bytes = await exportImage(null, scale);
        if (bytes != null) {
          _sendEvent("on_save", base64Encode(bytes));
          return "success";
        } else {
          return "failed";
        }

      case "deleteSelected":
        deleteSelected();
        break;

      case "focus":
        _focusNode.requestFocus();
        break;
    }

    return null;
  }

  // ===== Widget Building =====

  @override
  Widget build(BuildContext context) {
    return constrainedControl(
      context,
      LayoutBuilder(
        builder: (context, constraints) {
          canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          return _buildKeyboardHandler();
        },
      ),
      widget.parent,
      widget.control,
    );
  }

  Widget _buildKeyboardHandler() {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      canRequestFocus: true,
      descendantsAreFocusable: true,
      onKeyEvent: _handleKeyEvent,
      child: _buildShortcutsWrapper(),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      debugPrint(
          'Key pressed: ${event.logicalKey}, Control: ${HardwareKeyboard.instance.isControlPressed}, Meta: ${HardwareKeyboard.instance.isMetaPressed}');
    }

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyX &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      debugPrint('Ctrl+X detected, calling deleteSelected()');
      deleteSelected();
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.delete) {
      debugPrint('Delete key detected, calling deleteSelected()');
      deleteSelected();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildShortcutsWrapper() {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX):
            const DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyX):
            const DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): const DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.backspace): const DeleteIntent(),
      },
      child: _buildActionsWrapper(),
    );
  }

  Widget _buildActionsWrapper() {
    return Actions(
      actions: <Type, Action<Intent>>{
        DeleteIntent: CallbackAction<DeleteIntent>(
          onInvoke: (intent) {
            debugPrint('DeleteIntent triggered');
            deleteSelected();
            return null;
          },
        ),
      },
      child: _buildPainter(),
    );
  }

  Widget _buildPainter() {
    return GestureDetector(
      onTap: () {
        debugPrint('Canvas tapped, requesting focus');
        _focusNode.requestFocus();
      },
      child: FlutterPainter(
        controller: controller,
        onSelectedObjectDrawableChanged: (drawable) {
          debugPrint('Selected object changed: $drawable');
          _sendSelectedTextInfo();
          // Убедимся что фокус у нас
          Future.microtask(() => _focusNode.requestFocus());
        },
      ),
    );
  }
}

// ===== Helper Classes =====

class LayerManager {
  dynamic previousLayers;
  final List<String> processedLayerIds = [];

  bool isProcessed(String id) => processedLayerIds.contains(id);

  void markProcessed(String id) {
    processedLayerIds.add(id);
  }
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}