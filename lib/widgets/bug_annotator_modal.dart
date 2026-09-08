import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum AnnotationTool {
  arrow,
  rectangle,
  pen,
}

class AnnotationPath {
  final AnnotationTool tool;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  AnnotationPath({
    required this.tool,
    required this.points,
    required this.color,
    this.strokeWidth = 3.5,
  });
}

class BugAnnotatorModal extends StatefulWidget {
  final Uint8List screenshotBytes;
  final void Function(String base64Image, String? notes) onSend;

  const BugAnnotatorModal({
    super.key,
    required this.screenshotBytes,
    required this.onSend,
  });

  @override
  State<BugAnnotatorModal> createState() => _BugAnnotatorModalState();
}

class _BugAnnotatorModalState extends State<BugAnnotatorModal> {
  final GlobalKey _repaintKey = GlobalKey();
  final TextEditingController _noteController = TextEditingController();

  AnnotationTool _currentTool = AnnotationTool.arrow;
  Color _currentColor = const Color(0xFFEF4444); // Neon Red default
  final List<AnnotationPath> _paths = [];
  List<Offset> _currentPoints = [];
  bool _isSending = false;

  final List<Color> _palette = const [
    Color(0xFFEF4444), // Neon Red
    Color(0xFFFACC15), // Vibrant Yellow
    Color(0xFF00E5FF), // Electric Cyan
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _undo() {
    if (_paths.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _paths.removeLast());
    }
  }

  Future<void> _beamToWorkstation() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null && boundary.hasSize) {
        try {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();
            final base64String = base64Encode(pngBytes);
            widget.onSend(base64String, _noteController.text.trim());
            if (mounted) Navigator.of(context).maybePop();
            return;
          }
        } catch (_) {
          // Boundary might not be painted yet in headless/test environment, fall through to raw screenshot
        }
      }
      // Fallback to raw screenshot bytes if repaint boundary is unavailable or throws
      final base64String = base64Encode(widget.screenshotBytes);
      widget.onSend(base64String, _noteController.text.trim());
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Annotate Bug',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, color: Colors.white70),
                    onPressed: _paths.isNotEmpty ? _undo : null,
                    tooltip: 'Undo last stroke',
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSending ? null : _beamToWorkstation,
                    icon: _isSending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.send_rounded, size: 15),
                    label: Text(
                      _isSending ? 'Sending...' : 'Send to PC',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Canvas & Screenshot Display
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.memory(
                            widget.screenshotBytes,
                            fit: BoxFit.contain,
                          ),
                          Positioned.fill(
                            child: GestureDetector(
                              onPanStart: (details) {
                                setState(() {
                                  _currentPoints = [details.localPosition];
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  _currentPoints.add(details.localPosition);
                                });
                              },
                              onPanEnd: (_) {
                                if (_currentPoints.isNotEmpty) {
                                  setState(() {
                                    _paths.add(AnnotationPath(
                                      tool: _currentTool,
                                      points: List.of(_currentPoints),
                                      color: _currentColor,
                                    ));
                                    _currentPoints = [];
                                  });
                                }
                              },
                              child: CustomPaint(
                                painter: _AnnotationPainter(
                                  paths: _paths,
                                  currentPoints: _currentPoints,
                                  currentTool: _currentTool,
                                  currentColor: _currentColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Note Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _noteController,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add an optional bug note for your workstation...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: const Color(0xFF141414),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.cyan),
                  ),
                ),
              ),
            ),

            // Bottom Tools & Colors Toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  // Tool Selectors
                  _buildToolButton(AnnotationTool.arrow, Icons.arrow_outward_rounded, 'Arrow'),
                  const SizedBox(width: 8),
                  _buildToolButton(AnnotationTool.rectangle, Icons.crop_square_rounded, 'Box'),
                  const SizedBox(width: 8),
                  _buildToolButton(AnnotationTool.pen, Icons.draw_rounded, 'Pen'),

                  const Spacer(),

                  // Color Swatches
                  Row(
                    children: _palette.map((c) {
                      final isSelected = _currentColor == c;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentColor = c);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 8)]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(AnnotationTool tool, IconData icon, String label) {
    final isSelected = _currentTool == tool;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentTool = tool);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.cyan : AppTheme.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: isSelected ? AppTheme.cyan : Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.cyan : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<AnnotationPath> paths;
  final List<Offset> currentPoints;
  final AnnotationTool currentTool;
  final Color currentColor;

  _AnnotationPainter({
    required this.paths,
    required this.currentPoints,
    required this.currentTool,
    required this.currentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in paths) {
      _drawPath(canvas, p.tool, p.points, p.color, p.strokeWidth);
    }
    if (currentPoints.isNotEmpty) {
      _drawPath(canvas, currentTool, currentPoints, currentColor, 3.5);
    }
  }

  void _drawPath(Canvas canvas, AnnotationTool tool, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (tool == AnnotationTool.pen) {
      if (points.length == 1) {
        canvas.drawCircle(points.first, width / 2, paint);
      } else {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (var i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    } else if (tool == AnnotationTool.rectangle) {
      final rect = Rect.fromPoints(points.first, points.last);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
    } else if (tool == AnnotationTool.arrow) {
      final start = points.first;
      final end = points.last;
      canvas.drawLine(start, end, paint);

      // Draw arrowhead
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final angle = math.atan2(dy, dx);
      const arrowSize = 16.0;
      const arrowAngle = 0.45;

      final p1 = Offset(
        end.dx - arrowSize * math.cos(angle - arrowAngle),
        end.dy - arrowSize * math.sin(angle - arrowAngle),
      );
      final p2 = Offset(
        end.dx - arrowSize * math.cos(angle + arrowAngle),
        end.dy - arrowSize * math.sin(angle + arrowAngle),
      );

      final headPath = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(headPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}
