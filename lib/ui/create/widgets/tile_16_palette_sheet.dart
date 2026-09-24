import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/kolam_16_tile.dart';

class Tile16PaletteWidget extends StatelessWidget {
  final Kolam16Tile selectedTile;
  final Function(Kolam16Tile) onTileSelected;
  final bool isDark;

  const Tile16PaletteWidget({
    super.key,
    required this.selectedTile,
    required this.onTileSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
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
              Row(
                children: [
                  const Icon(Icons.grid_view_rounded, size: 15, color: AppColors.turmericGold),
                  const SizedBox(width: 6),
                  Text(
                    '16 Sikku Tile Shapes (Binary Grammar):',
                    style: AppTypography.cardTitle.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
              Text(
                'Selected: ${selectedTile.binaryCode}',
                style: AppTypography.tagText.copyWith(
                  color: AppColors.turmericGold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: Kolam16TileLibrary.all.length,
              itemBuilder: (context, index) {
                final tile = Kolam16TileLibrary.all[index];
                final isSelected = tile.mask == selectedTile.mask;

                return GestureDetector(
                  onTap: () => onTileSelected(tile),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 54,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.turmericGold.withValues(alpha: 0.18)
                          : (isDark ? AppColors.slateLight : AppColors.riceFlourBg),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.turmericGold : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CustomPaint(
                            painter: _TileThumbnailPainter(
                              tile: tile,
                              isDark: isDark,
                              isSelected: isSelected,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tile.binaryCode,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontFamily: 'monospace',
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? AppColors.turmericGold
                                : (isDark ? AppColors.textLight : AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TileThumbnailPainter extends CustomPainter {
  final Kolam16Tile tile;
  final bool isDark;
  final bool isSelected;

  _TileThumbnailPainter({
    required this.tile,
    required this.isDark,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringR = size.width * 0.28;
    final pointD = size.width * 0.46;

    final path = tile.generatePath(
      center: center,
      ringRadius: ringR,
      pointDistance: pointD,
    );

    final strokePaint = Paint()
      ..color = isSelected
          ? AppColors.turmericGold
          : (isDark ? Colors.white : const Color(0xFF8E2824))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = isSelected ? AppColors.turmericGold : (isDark ? Colors.white : const Color(0xFF8E2824))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, strokePaint);
    canvas.drawCircle(center, 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TileThumbnailPainter oldDelegate) =>
      oldDelegate.tile.mask != tile.mask || oldDelegate.isSelected != isSelected;
}
