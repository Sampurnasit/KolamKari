import '../models/kolam_tile.dart';

/// 16 Reusable Kolam Tile Primitives for Game 2 (Pattern Construction)
/// and for tile-based pattern recognition.
class TilePrimitivesSeed {
  static final List<KolamTile> allTiles = [
    const KolamTile(
      id: 'tile_corner_loop_1',
      name: 'Outer Loop Turn',
      primitiveType: TilePrimitiveType.cornerLoop,
      culturalMeaning: 'Smooth turning loop enclosing border dots without touching them.',
    ),
    const KolamTile(
      id: 'tile_corner_loop_2',
      name: 'Deep Corner Knot',
      primitiveType: TilePrimitiveType.cornerLoop,
      culturalMeaning: 'Sharp apex turnaround often seen in Padi kolam corners.',
    ),
    const KolamTile(
      id: 'tile_straight_segment_1',
      name: 'Central Spine Line',
      primitiveType: TilePrimitiveType.straightSegment,
      culturalMeaning: 'Linear connection along coordinate axes.',
    ),
    const KolamTile(
      id: 'tile_straight_segment_2',
      name: 'Diagonal Bridge',
      primitiveType: TilePrimitiveType.straightSegment,
      culturalMeaning: 'Connecting opposite interstitial dots across grid diagonals.',
    ),
    const KolamTile(
      id: 'tile_cross_intersect_1',
      name: 'Orthogonal Cross',
      primitiveType: TilePrimitiveType.crossIntersection,
      culturalMeaning: 'Symmetric intersection at cardinal midpoints.',
    ),
    const KolamTile(
      id: 'tile_cross_intersect_2',
      name: 'X-Weave Intersection',
      primitiveType: TilePrimitiveType.crossIntersection,
      culturalMeaning: 'Over-and-under ribbon crossover in Sikku patterns.',
    ),
    const KolamTile(
      id: 'tile_curved_bridge_1',
      name: 'S-Curve Weave',
      primitiveType: TilePrimitiveType.curvedBridge,
      culturalMeaning: 'Serpentine line undulating between two adjacent dots.',
    ),
    const KolamTile(
      id: 'tile_curved_bridge_2',
      name: 'Convex Arch',
      primitiveType: TilePrimitiveType.curvedBridge,
      culturalMeaning: 'Protective canopy arch forming lotus and petal perimeters.',
    ),
    const KolamTile(
      id: 'tile_petal_arc_1',
      name: 'Lotus Petal Base',
      primitiveType: TilePrimitiveType.petalArc,
      culturalMeaning: 'Traditional 8-petal mandala quadrant segment.',
    ),
    const KolamTile(
      id: 'tile_petal_arc_2',
      name: 'Mango/Paisley Curve',
      primitiveType: TilePrimitiveType.petalArc,
      culturalMeaning: 'Traditional Maangai (mango/paisley) auspicious contour.',
    ),
    const KolamTile(
      id: 'tile_dot_surround_1',
      name: 'Circular Dot Orbit',
      primitiveType: TilePrimitiveType.dotSurround,
      culturalMeaning: 'Closed circumscription safeguarding central bindu.',
    ),
    const KolamTile(
      id: 'tile_dot_surround_2',
      name: 'Rhombus Eye Orbit',
      primitiveType: TilePrimitiveType.dotSurround,
      culturalMeaning: 'Diamond perimeter framing interstitial pulli.',
    ),
    const KolamTile(
      id: 'tile_swirl_knot_1',
      name: 'Brahma Mudi Spiral',
      primitiveType: TilePrimitiveType.swirlKnot,
      culturalMeaning: 'Sacred center knot symbolizing the unmanifest infinite.',
    ),
    const KolamTile(
      id: 'tile_swirl_knot_2',
      name: 'Chakra Spiral',
      primitiveType: TilePrimitiveType.swirlKnot,
      culturalMeaning: 'Dynamic clockwise vortex representing time and cosmic motion.',
    ),
    const KolamTile(
      id: 'tile_wave_link_1',
      name: 'Dual Crest Wave',
      primitiveType: TilePrimitiveType.waveLink,
      culturalMeaning: 'Rippling water/river motif invoking fertility and rains.',
    ),
    const KolamTile(
      id: 'tile_wave_link_2',
      name: 'Interlocking Chain Link',
      primitiveType: TilePrimitiveType.waveLink,
      culturalMeaning: 'Continuous chain binding community and household welfare.',
    ),
  ];
}
