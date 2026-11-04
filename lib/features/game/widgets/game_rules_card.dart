import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Compact game rules banner with 3 illustrated mini cards matching Reference Image 2.
///
/// Clearly explains:
/// 1. "1 Dog per color"
/// 2. "1 Dog per row & col"
/// 3. "Dogs cannot touch"
class GameRulesCard extends StatelessWidget {
  const GameRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowWarm,
            offset: Offset(0, 1.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: _RuleCardItem(
              type: _RuleType.onePerColor,
              label: '1 Dog per\ncolor',
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: _RuleCardItem(
              type: _RuleType.onePerRowCol,
              label: '1 Dog per\nrow & col',
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: _RuleCardItem(
              type: _RuleType.noTouch,
              label: 'Dogs cannot\ntouch',
            ),
          ),
        ],
      ),
    );
  }
}

enum _RuleType {
  onePerColor,
  onePerRowCol,
  noTouch,
}

class _RuleCardItem extends StatelessWidget {
  final _RuleType type;
  final String label;

  const _RuleCardItem({
    required this.type,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.8), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(22, 22),
            painter: _RuleGridPainter(type: type),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleGridPainter extends CustomPainter {
  final _RuleType type;

  const _RuleGridPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cellW = w / 3.0;
    final cellH = h / 3.0;

    final bgPaint = Paint()..color = const Color(0xFFF3E7DC);
    final borderPaint = Paint()
      ..color = const Color(0xFFD6C5B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw 3x3 mini grid
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);
        canvas.drawRect(rect, bgPaint);
        canvas.drawRect(rect, borderPaint);
      }
    }

    final crossPaint = Paint()
      ..color = AppColors.textLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    void drawX(int r, int c) {
      final inset = cellW * 0.22;
      final x1 = c * cellW + inset;
      final y1 = r * cellH + inset;
      final x2 = (c + 1) * cellW - inset;
      final y2 = (r + 1) * cellH - inset;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), crossPaint);
      canvas.drawLine(Offset(x2, y1), Offset(x1, y2), crossPaint);
    }

    final dogPawPaint = Paint()..color = AppColors.primaryDark;
    void drawDogPaw(int r, int c) {
      final cx = (c + 0.5) * cellW;
      final cy = (r + 0.5) * cellH;
      canvas.drawCircle(Offset(cx, cy), cellW * 0.28, dogPawPaint);
      // White center highlight
      canvas.drawCircle(Offset(cx, cy), cellW * 0.12, Paint()..color = Colors.white);
    }

    switch (type) {
      case _RuleType.onePerColor:
        // Region highlight in pastel green, dog in center, Xs around
        final regionPaint = Paint()..color = const Color(0xFFCBEBC4);
        canvas.drawRect(Rect.fromLTWH(0, 0, cellW * 3, cellH * 3), regionPaint);
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            canvas.drawRect(Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH), borderPaint);
            if (r == 1 && c == 1) {
              drawDogPaw(r, c);
            } else {
              drawX(r, c);
            }
          }
        }
        break;

      case _RuleType.onePerRowCol:
        // Center row and center col highlighted with cross lines
        drawDogPaw(1, 1);
        drawX(0, 1);
        drawX(2, 1);
        drawX(1, 0);
        drawX(1, 2);
        break;

      case _RuleType.noTouch:
        // Dog in center, all 8 surrounding cells crossed
        drawDogPaw(1, 1);
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            if (r != 1 || c != 1) {
              drawX(r, c);
            }
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _RuleGridPainter oldDelegate) => oldDelegate.type != type;
}
