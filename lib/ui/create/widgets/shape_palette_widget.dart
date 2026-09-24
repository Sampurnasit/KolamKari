import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/kolam_shape_primitive.dart';

class ShapePaletteWidget extends StatelessWidget {
  final Function(KolamShapePrimitive) onShapeSelected;
  final bool isDark;

  const ShapePaletteWidget({
    super.key,
    required this.onShapeSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primitives = KolamShapeCatalog.primitives;

    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : AppColors.riceFlourCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_mosaic_rounded, size: 14, color: AppColors.turmericAmber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kolam Primitives Palette (Drag or Tap to Place)',
                        style: AppTypography.tagText.copyWith(
                          color: AppColors.turmericAmber,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '9 Primitives',
                style: AppTypography.caption.copyWith(fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: primitives.length,
              itemBuilder: (context, index) {
                final primitive = primitives[index];
                return _buildPaletteItem(context, primitive);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteItem(BuildContext context, KolamShapePrimitive primitive) {
    return Container(
      width: 68,
      margin: const EdgeInsets.only(right: 8),
      child: Draggable<KolamShapePrimitive>(
        data: primitive,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF261E21).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.turmericGold, width: 2),
            ),
            child: CustomPaint(
              painter: _PrimitiveTilePainter(primitive),
            ),
          ),
        ),
        child: InkWell(
          onTap: () => onShapeSelected(primitive),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261E21) : AppColors.riceFlourBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(40, 40),
                    painter: _PrimitiveTilePainter(primitive, isDark: isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  primitive.name,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textDark,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimitiveTilePainter extends CustomPainter {
  final KolamShapePrimitive primitive;
  final bool isDark;

  _PrimitiveTilePainter(this.primitive, {this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw reference pulli anchor points
    final dotPaint = Paint()
      ..color = const Color(0xFFE59500)
      ..style = PaintingStyle.fill;

    final startOffset = Offset(
      primitive.localStartAnchor.dx * w,
      primitive.localStartAnchor.dy * h,
    );
    final endOffset = Offset(
      primitive.localEndAnchor.dx * w,
      primitive.localEndAnchor.dy * h,
    );

    // Draw path
    final paint = Paint()
      ..color = isDark ? const Color(0xFFFFFDF8) : AppColors.terracottaRed
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = primitive.generatePath(size);
    canvas.drawPath(path, paint);

    // Draw golden anchor nodes
    canvas.drawCircle(startOffset, 2.2, dotPaint);
    canvas.drawCircle(endOffset, 2.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PrimitiveTilePainter oldDelegate) =>
      oldDelegate.primitive.id != primitive.id;
}
