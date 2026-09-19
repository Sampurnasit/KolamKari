import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class RegionalTraditionItem {
  final String region;
  final String traditionalName;
  final String scriptName;
  final String medium;
  final String distinctiveTrait;
  final String culturalRole;
  final IconData icon;
  final Color badgeColor;

  const RegionalTraditionItem({
    required this.region,
    required this.traditionalName,
    required this.scriptName,
    required this.medium,
    required this.distinctiveTrait,
    required this.culturalRole,
    required this.icon,
    required this.badgeColor,
  });
}

class RegionalTraditionsScreen extends StatelessWidget {
  const RegionalTraditionsScreen({super.key});

  static const List<RegionalTraditionItem> traditions = [
    RegionalTraditionItem(
      region: 'Tamil Nadu',
      traditionalName: 'Kolam',
      scriptName: 'கோலம்',
      medium: 'Dry rice flour (Arisi Maavu) & wet red Kaavi mud border',
      distinctiveTrait: 'Strict Pulli (dot grids) and endless Eulerian knot loops (Sikku) that snake around dots without touching them.',
      culturalRole: 'Drawn daily at sunrise to invoke Goddess Lakshmi and feed insects (Bhoothayagnam). Reaches its zenith during Margazhi street festivals.',
      icon: Icons.grain_rounded,
      badgeColor: AppColors.terracottaRed,
    ),
    RegionalTraditionItem(
      region: 'Andhra Pradesh & Telangana',
      traditionalName: 'Muggu',
      scriptName: 'ముగ్గు',
      medium: 'Muggu Raayi (white calcium carbonate rock powder) & natural turmeric/kumkum',
      distinctiveTrait: 'Expansive central floral blossoms, Sankranti Ratham (sun chariot) paths, and bold dual border lines framing tulsi pots.',
      culturalRole: 'Revered during Dhanurmasam and Sankranti. Drawn with two parallel chalk lines symbolizing dharma and auspiciousness.',
      icon: Icons.brightness_high_rounded,
      badgeColor: Color(0xFFC44520),
    ),
    RegionalTraditionItem(
      region: 'Karnataka',
      traditionalName: 'Rangavalli & Chittara',
      scriptName: 'ರಂಗವಲ್ಲಿ / ಚಿತ್ತಾರ',
      medium: 'White rock powder, kaolin white clay, and natural Kaavi red earth',
      distinctiveTrait: 'Tribal Deewaru geometric murals and floor diagrams composed of fine parallel lines, auspicious zigzags, and fertility baskets.',
      culturalRole: 'Created for auspicious life-cycle events, harvest celebrations, and domestic sanctification.',
      icon: Icons.auto_awesome_mosaic_rounded,
      badgeColor: Color(0xFF285E42),
    ),
    RegionalTraditionItem(
      region: 'West Bengal',
      traditionalName: 'Alpana (Alpona)',
      scriptName: 'আলপনা',
      medium: 'Pitol (water-diluted rice paste) applied with cotton wicks or finger cloth',
      distinctiveTrait: 'Completely freehand with zero dot grids. Features graceful organic curves, fish (Maach), conch shells, and Lakshmi footprints.',
      culturalRole: 'Drawn for Kojagari Lakshmi Puja and weddings. The damp milky rice paste dries to an opaque porcelain-like white sheen.',
      icon: Icons.water_drop_rounded,
      badgeColor: Color(0xFF1F527E),
    ),
    RegionalTraditionItem(
      region: 'Kerala',
      traditionalName: 'Pookkalam & Kalamezhuthu',
      scriptName: 'പൂക്കളം',
      medium: 'Fresh flower petals (Onam) and five sacred natural powders (temple shrines)',
      distinctiveTrait: 'Concentric circular rings expanding daily over the 10 days of Onam festival, bursting with natural color gradation.',
      culturalRole: 'Welcomes King Mahabali during Onam. In temples, Kalamezhuthu floor paintings depict divine archetypes with three-dimensional depth.',
      icon: Icons.local_florist_rounded,
      badgeColor: AppColors.turmericGold,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regional Traditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slateCard : const Color(0xFFF9F1E6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.turmericGold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.turmericAmber, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Preserving Regional Identity: While unified by auspicious intent, Indian floor art forms represent distinct regional grammars, materials, and naming traditions.',
                      style: AppTypography.caption.copyWith(
                        fontSize: 13,
                        color: isDark ? AppColors.textLight : AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tradition Cards
            ...traditions.map((item) => _buildTraditionCard(context, item, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildTraditionCard(BuildContext context, RegionalTraditionItem item, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.badgeColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: item.badgeColor.withValues(alpha: 0.15),
                  child: Icon(item.icon, color: item.badgeColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.traditionalName,
                            style: AppTypography.cardTitle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${item.scriptName})',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: item.badgeColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.region,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.turmericAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            _buildDetailRow(
              label: 'Sacred Medium',
              value: item.medium,
              icon: Icons.palette_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _buildDetailRow(
              label: 'Distinctive Grammar',
              value: item.distinctiveTrait,
              icon: Icons.gesture_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _buildDetailRow(
              label: 'Cultural Practice',
              value: item.culturalRole,
              icon: Icons.temple_hindu_rounded,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodyText.copyWith(
                fontSize: 13.5,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
