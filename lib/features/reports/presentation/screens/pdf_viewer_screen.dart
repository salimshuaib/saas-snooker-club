import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:snooker_club/core/theme/app_colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final Uint8List pdfBytes;
  final String fileName;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final TransformationController _transformationController;
  double _currentScale = 1.0;

  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;
  static const double _scaleStep = 0.25;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _zoomIn() {
    _zoomBy(1.0 + _scaleStep);
  }

  void _zoomOut() {
    _zoomBy(1.0 / (1.0 + _scaleStep));
  }

  void _zoomBy(double factor) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(_minScale, _maxScale);
    final actualFactor = targetScale / currentScale;

    if ((actualFactor - 1.0).abs() < 0.001) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(400, 600);
    final center = Offset(size.width / 2, size.height / 2);

    final newMatrix = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0.0, 1.0)
      ..scaleByDouble(actualFactor, actualFactor, 1.0, 1.0)
      ..translateByDouble(-center.dx, -center.dy, 0.0, 1.0)
      ..multiply(currentMatrix);

    setState(() {
      _transformationController.value = newMatrix;
    });
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _saveToDevice(BuildContext context) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final safeName = widget.fileName.endsWith('.pdf')
          ? widget.fileName
          : '${widget.fileName}.pdf';
      final file = File('${directory.path}/$safeName');
      await file.writeAsBytes(widget.pdfBytes, flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Saved to Downloads: $safeName'),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                OpenFilex.open(file.path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to save file: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanFileName = widget.fileName.endsWith('.pdf')
        ? widget.fileName
        : '${widget.fileName}.pdf';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Save to Downloads',
            onPressed: () => _saveToDevice(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          PdfPreview.builder(
            build: (format) => widget.pdfBytes,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: cleanFileName,
            actions: [
              PdfPreviewAction(
                icon: const Icon(Icons.zoom_out_rounded),
                onPressed: (ctx, build, pageFormat) => _zoomOut(),
              ),
              PdfPreviewAction(
                icon: const Icon(Icons.zoom_in_rounded),
                onPressed: (ctx, build, pageFormat) => _zoomIn(),
              ),
              PdfPreviewAction(
                icon: const Icon(Icons.save_alt_rounded),
                onPressed: (ctx, build, pageFormat) async {
                  await _saveToDevice(context);
                },
              ),
            ],
            pagesBuilder: (context, pages) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final pageWidth =
                      (constraints.maxWidth - 32).clamp(280.0, 900.0);
                  return InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: _minScale,
                    maxScale: _maxScale,
                    boundaryMargin: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 240,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < pages.length; i++)
                              Container(
                                width: pageWidth,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: AspectRatio(
                                  aspectRatio: pages[i].aspectRatio,
                                  child: Image(
                                    image: pages[i].image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Floating Zoom Toolbar Pill
          Positioned(
            bottom: 68,
            right: 16,
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E212A).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Zoom Out',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      splashRadius: 18,
                      onPressed: _zoomOut,
                    ),
                    InkWell(
                      onTap: _resetZoom,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          '${(_currentScale * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Zoom In',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      splashRadius: 18,
                      onPressed: _zoomIn,
                    ),
                    Container(
                      height: 18,
                      width: 1,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.fit_screen_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      tooltip: 'Fit to Page',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      splashRadius: 18,
                      onPressed: _resetZoom,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
