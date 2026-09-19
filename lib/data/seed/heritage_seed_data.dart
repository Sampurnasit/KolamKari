import '../models/learn_module.dart';

/// Seed cultural content for KolamKari.
/// Preserves authentic Indian floor art traditions with high scholarly and cultural fidelity.
/// Note: Content structured for direct v1 usage and drop-in extension from primary sources.
class HeritageSeedData {
  static final List<LearnModule> initialModules = [
    const LearnModule(
      id: 'what_is_kolam',
      title: 'What is Kolam?',
      subtitle: 'The Sacred Threshold and Dawn Ritual of Auspiciousness',
      category: 'Origins & Philosophy',
      relatedRegion: 'Tamil Nadu & South India',
      xpReward: 20,
      culturalQuote: '"Every morning, the threshold of the home is washed clean and purified to welcome Lakshmi, bringing prosperity and tranquility."',
      keyTakeaways: [
        'Drawn before sunrise using edible rice flour (Arisi Maavu).',
        'Serves as an offering of Bhoothayagnam — feeding ants, birds, and insects.',
        'Acts as an auspicious protective boundary (Lakshmana Rekha) guarding the home.'
      ],
      bodyMarkdown: '''
# The Living Canvas of Dawn

**Kolam** (கோலம்) is a geometric drawing ritual practiced every morning by millions of women across South India. Drawn at the threshold of homes, courtyards, and temples, it represents far more than decorative folk art: it is an act of daily renewal, meditation, hospitality, and ecological harmony.

---

### The Sacred Material: Rice Flour

Traditionally, a Kolam is drawn strictly using **dry rice flour** (*Arisi Maavu*) or rice paste mixed with water (*Maa Kolam*). 
This practice embodies the ancient Vedic virtue of **Bhoothayagnam** — one of the five sacred daily duties:
- The rice flour feeds ants, small birds, insects, and microorganisms.
- By welcoming and feeding tiny creatures at the door, the household affirms harmlessness (*Ahimsa*) and coexistence with all living beings before human affairs begin.

---

### The Dot-Based Technique (*Pulli*)

A traditional Kolam begins with a disciplined grid of dots called **Pulli**:
1. **Sikku or Brahma Mudi**: Continuous labyrinthine closed loops that weave fluidly around the dots without touching them.
2. **Kambi Kolam**: Lines that directly join dot to dot into stars, squares, flowers, and sacred mandalas.
3. The discipline requires the artist to bend from the waist, hold rice flour between the thumb and forefinger, and regulate a gentle flow through micro-vibrations of the hand.

---

### Spiritual & Psychological Significance

In Tamil thought, the threshold (*Vaasal*) is the liminal space between the private sanctum of family life and the unpredictable outside world. 
- A freshly drawn Kolam invites **Lakshmi** (the deity of auspiciousness, health, and abundance) into the residence.
- The morning practice calms the mind, focuses spatial cognition, and instills a feeling of harmony before sunrise.
''',
    ),

    const LearnModule(
      id: 'history_heritage',
      title: 'History & Heritage',
      subtitle: 'From Ancient Indus Seals to Sangam Classical Literature',
      category: 'Historical Evolution',
      relatedRegion: 'Pan-Indian & Tamilakam',
      xpReward: 20,
      culturalQuote: '"In Sangam verse, the courtyard shining with freshly washed red kaavi and white rice powder is the signature of a radiant home."',
      keyTakeaways: [
        'Archaeological roots trace to Indus Valley seals and megalithic rock drawings.',
        'Documented in classical Tamil Sangam literature (Silappadikaram and Manimekalai).',
        'Passed down aurally and kinesthetically across generations from mother to daughter.'
      ],
      bodyMarkdown: '''
# Antiquity of Sacred Floor Geometry

The origins of Kolam are intertwined with the prehistoric and classical antiquity of the Indian subcontinent.

---

### Indus Valley and Megalithic Roots

Archaeological excavations across the Indus Valley (Harappa and Mohenjo-Daro) have revealed terracotta seals and pottery bearing interlocking loops, endless knots, and radial geometric stars that closely mirror contemporary **Sikku Kolam** motifs.

Megalithic burial and habitation sites in Tamil Nadu (such as Adichanallur and Kodumanal) preserve engraved spiral symbols, swastika variations, and sun-burst radial diagrams reflecting early ritual cosmograms.

---

### Sangam Literature Citations

Classical Tamil literature from the Sangam epoch (circa 300 BCE – 300 CE) explicitly describes the dawn threshold preparation:
- In the epic **Silappadikaram**, poet Ilango Adigal describes courtyards sprinkled with cow-dung water (*Sanakkaraisal*) and lined with vibrant rice powders.
- **Perumpanarruppadai** celebrates the housewife rising before dawn to invoke beauty at the doorstep.

---

### Transmission Through Generations

Unlike classical temple sculpture or mural painting, which were traditionally codified in written *Shilpa Shastras*, Kolam remained an oral and kinesthetic tradition nurtured primarily by women. 
Mothers taught daughters through daily practice, memory games, riddles, and communal festival gatherings, creating an unbroken living archive spanning millennia.
''',
    ),

    const LearnModule(
      id: 'regional_traditions',
      title: 'Regional Traditions Across India',
      subtitle: 'Distinguishing Kolam, Muggu, Rangavalli, Alpana & More',
      category: 'Geographic Diversity',
      relatedRegion: 'India: Tamil Nadu, Andhra, Karnataka, Bengal, Maharashtra',
      xpReward: 20,
      culturalQuote: '"Each region speaks its own dialect of line and powder, yet all revere the same sacred threshold."',
      keyTakeaways: [
        'Tamil Nadu: Kolam — disciplined pulli dot grids and endless loops.',
        'Andhra Pradesh & Telangana: Muggu — pearl-white limestone with vibrant color accents and floral central mandalas.',
        'Karnataka: Rangavalli / Hase Chittara — intricate tribal folk geometry and red earth pigments.',
        'West Bengal: Alpana — fluid liquid rice-paste motifs drawn with cloth wicks.',
        'Maharashtra: Sanskar Bharati — bold concentric circular lines and vibrant shaded pigments.'
      ],
      bodyMarkdown: '''
# Regional Floor Art: Distinct Traditions

Floor art across India shares deep cosmological intent, yet **each regional style possesses unique techniques, materials, grammar, and regional names**. They must never be conflated as identical.

---

### 1. Tamil Nadu: Kolam
- **Primary Medium**: Dry raw rice powder (*Arisi Maavu*), bordered with red kaavi (mineral-rich terracotta liquid).
- **Distinctive Trait**: Rigid **Pulli** (dot grid) foundations. High emphasis on **Sikku** (knot kolams) where a single continuous line returns to its origin without interruption, demonstrating Eulerian topological circuits.

---

### 2. Andhra Pradesh & Telangana: Muggu
- **Primary Medium**: White limestone/calcium carbonate powder (*Muggu Raayi*), chalk powder, and turmeric.
- **Distinctive Trait**: Features expansive floral centers (chrysanthemums, lotuses), depictions of auspicious chariots (*Ratham Muggu* during Sankranti), and tulsi pot altars. Uses both dot grids and expressive freehand borders.

---

### 3. Karnataka: Rangavalli & Chittara
- **Primary Medium**: Powdered white rock, kaolin clay, and kaavi red soil.
- **Distinctive Trait**: In Malnad Karnataka, the indigenous Deewaru community paints **Chittara** — intricate geometric murals and floor diagrams representing wedding rituals, farming cycles, and auspicious fertility baskets.

---

### 4. West Bengal: Alpana (Alpona)
- **Primary Medium**: Liquid rice paste (*Pitol*) diluted with water, applied using a small cotton cloth rolled around the finger or little bamboo wicks.
- **Distinctive Trait**: No dot grids! Alpana is drawn completely freehand with sweeping organic curves, featuring fish (*Maach*), conch shells (*Shankha*), lotus blooms, and footprints of Goddess Lakshmi.

---

### 5. Kerala: Pookkalam & Kalamezhuthu
- **Pookkalam**: Flower petal carpets arranged in concentric circles for ten days during Onam harvest.
- **Kalamezhuthu**: Ancient temple floor murals drawn with five natural powders (rice, turmeric, burnt paddy husk, dried leaves, and lime-turmeric blend) depicting deities with fierce emotional depth.
''',
    ),

    const LearnModule(
      id: 'festivals_occasions',
      title: 'Festivals & Sacred Occasions',
      subtitle: 'Pongal, Margazhi, Diwali & The Great Street Canvases',
      category: 'Living Celebrations',
      relatedRegion: 'Tamil Nadu & Pan-India',
      xpReward: 20,
      culturalQuote: '"During the month of Margazhi, entire avenues transform into an unbroken ocean of geometric tapestry before dawn breaks."',
      keyTakeaways: [
        'Margazhi Month (Dec–Jan): Peak season when women draw grand street-wide Kolams before 5 AM.',
        'Pongal / Sankranti: Chariot (Ratham) Kolams, sugarcane motifs, and boiling milk pots.',
        'Deepavali / Diwali: Welcoming lamps, lotus chakras, and bright color powder fills.'
      ],
      bodyMarkdown: '''
# Festive Grandeur: From Doorstep to Avenue

While a small Kolam is drawn daily, Indian festivals elevate the art form into spectacular community celebrations.

---

### The Splendor of Margazhi (December – January)

The Tamil month of **Margazhi** is dedicated entirely to devotion, classical music, and majestic Kolam creations:
- Cold winter mornings see women rising as early as 4:00 AM to wash the public roads.
- Entire neighborhood lanes in Chennai (such as Mylapore) and Madurai become contiguous carpets of geometric art.
- In the center of the Margazhi Kolam, a small lump of cow dung is placed topped with a golden yellow **Parangi** (pumpkin) flower — symbolizing fertility, dawn light, and humble devotion.

---

### Thai Pongal & Makara Sankranti

- **Ratham Kolam (The Sun Chariot)**: Drawn with intricate wheels, reins, and galloping horses facing east to salute the northward movement of the Sun (*Uttarayana*).
- **Pongal Paanai**: Depictions of earthen pots boiling over with sweet rice milk, flanked by twin stalks of sugarcane and turmeric leaves.

---

### Weddings and Padi Kolams

For weddings, housewarmings, and temple rituals, the **Padi Kolam** (stepped border kolam) is drawn:
- Drawn with wet rice paste mixed with water (*Maa Kolam*) so it remains durable throughout the festivities.
- Framed with double parallel red lines of **Kaavi** (red wet mud), symbolizing the union of Purusha and Prakriti (form and energy).
''',
    ),

    const LearnModule(
      id: 'types_of_kolam',
      title: 'Types of Kolam: The Pattern Families',
      subtitle: 'Pulli, Sikku, Kambi, Padi, and Maa Kolam Explained',
      category: 'Pattern Taxonomy',
      relatedRegion: 'South India',
      xpReward: 20,
      culturalQuote: '"A knot kolam is like life itself — endless twists, turns, and loops, yet returning peacefully to the source."',
      keyTakeaways: [
        'Pulli Kolam: Built around rectangular (Nerkodu) or isometric (Sandhu) dot arrangements.',
        'Sikku / Brahma Mudi: Knot patterns where lines weave around dots without touching.',
        'Kambi Kolam: Linear connection kolams connecting dot to dot.',
        'Padi Kolam: Tiered geometric templates with red Kaavi borders for rituals.'
      ],
      bodyMarkdown: '''
# The Five Traditional Families of Kolam

Traditional masters classify Kolams based on their mathematical matrix and artistic execution.

---

### 1. Nerkodu Pulli Kolam (Straight Dot Grid)
- Dots arranged in perfect Cartesian squares and rectangles (N × N).
- Each dot has perpendicular neighbors along horizontal and vertical axes.
- Examples: 5x5, 7x7, 9x9 symmetrical mandalas.

---

### 2. Sandhu Pulli Kolam (Interlocking / Triangular Grid)
- Each subsequent row drops one dot or shifts into the interstitial hollow between dots of the previous row (hexagonal/isometric packing).
- Examples: 15 down to 1 dots, diamond matrices, and six-pointed stars.

---

### 3. Sikku Kolam (Brahma Mudi / Knot Kolam)
- The most intellectually challenging variety.
- The chalk line **never passes through the dots**; instead, it snakes around them in continuous loops.
- Often executed as a **single unbroken line** (Eulerian circuit) that navigates complex obstacles and wraps into 4-fold or 8-fold symmetry.

---

### 4. Padi Kolam (Tiered Stepped Kolam)
- Geometric, architectural forms composed of interlocking squares, nested rhombuses, and lotus petals.
- Strictly delineated with red kaavi edges; customary in temple sanctums and wedding mantapas.

---

### 5. Maa Kolam (Wet Rice Flour Kolam)
- Raw rice soaked for hours, ground fine into a milky paste with water.
- Applied using a soft cloth held in the palm, gently squeezed with the thumb to release consistent, brilliant white lines that dry opaque.
''',
    ),

    const LearnModule(
      id: 'mathematics_of_kolam',
      title: 'The Mathematics of Kolam',
      subtitle: 'Eulerian Paths, Knot Theory, Fractals & Symmetry Groups',
      category: 'Mathematical Heritage',
      relatedRegion: 'Global Science & Ethnomathematics',
      xpReward: 20,
      culturalQuote: '"Computer scientists and mathematicians around the world study Kolam as an ancient system of visual algorithms."',
      keyTakeaways: [
        'Eulerian Circuit: Many Sikku Kolams are drawn in one single stroke without lifting the hand or retracing lines.',
        'Symmetry Groups: Exhibits dihedral group D4, cyclic group C4, and glide reflections.',
        'Array Grammars & Formal Languages: Used by computer scientists to study syntactic pattern generation.',
        'Fractal Recursion: Iterative self-similarity across nested sub-units.'
      ],
      bodyMarkdown: '''
# Ethnomathematics: Algorithms in Rice Flour

Kolam is recognized internationally by mathematicians, computer scientists, and topologists as an extraordinary indigenous system of **spatial computation**.

---

### 1. Eulerian Graphs & Endless Loops
In graph theory, an **Eulerian circuit** is a closed trail that visits every edge in a graph exactly once. 
Centuries before Leonhard Euler solved the Seven Bridges of Königsberg problem in 1736, South Indian women developed intuitive rules for generating closed Eulerian paths:
- A line curves smoothly around every dot, alternating convex and concave turns.
- The path self-intersects symmetrically and terminates precisely at its starting point without any open ends.

---

### 2. Dihedral Symmetry Groups (D4)
A classic Kolam exhibits **dihedral group D4 symmetry**:
- 4 axes of reflection (vertical, horizontal, and both 45° diagonals).
- 4-fold rotational symmetry (invariance under rotations of 90°, 180°, 270°, and 360°).
- Every stroke in one quadrant has 7 mirror or rotated siblings, creating deep perceptual balance and visual tranquility.

---

### 3. Formal Picture Languages & Array Grammars
In theoretical computer science, Indian computer scientists (such as Gift Siromoney and Rani Siromoney at Madras Christian College) pioneered the use of **Kolam Array Grammars**:
- Proved that Kolam construction can be described by formal grammars in the Chomsky hierarchy.
- Used to model growth patterns, crystal lattices, and parallel programming architectures.

---

### 4. Fractals & Self-Similarity
Traditional Kolams often feature recursive self-similarity:
- A central motif (such as a 4-petal lotus) is repeated at larger scales at the four cardinals.
- This creates fractal dimension properties, echoing the natural morphology of snowflakes, coastlines, and galaxies.
''',
    ),
  ];
}
