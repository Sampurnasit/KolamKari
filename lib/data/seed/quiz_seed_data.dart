class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String culturalTag;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.culturalTag,
  });
}

class QuizSeedData {
  static final List<QuizQuestion> questions = [
    const QuizQuestion(
      id: 'q1',
      question: 'What is the primary traditional ingredient used to draw authentic dawn Kolams in Tamil Nadu?',
      options: [
        'Dry rice flour (Arisi Maavu)',
        'Synthetic chemical paint',
        'Crushed marble dust',
        'Ground turmeric powder only'
      ],
      correctIndex: 0,
      explanation: 'Authentic Kolams use edible dry rice flour to fulfill Bhoothayagnam — feeding ants, birds, and small insects at the threshold.',
      culturalTag: 'Bhoothayagnam & Ecology',
    ),
    const QuizQuestion(
      id: 'q2',
      question: 'How does the floor art tradition of West Bengal (Alpana) fundamentally differ from Tamil Nadu Kolam?',
      options: [
        'Alpana is drawn strictly on square dot grids',
        'Alpana is drawn freehand with liquid rice paste without any dot grid',
        'Alpana only uses dry colored sands',
        'Alpana is only drawn inside temple sanctums'
      ],
      correctIndex: 1,
      explanation: 'Unlike Tamil Kolam which is grounded in dot matrices (pulli), Bengal Alpana is painted freehand using liquid rice paste (Pitol) with cotton wicks.',
      culturalTag: 'Regional Traditions',
    ),
    const QuizQuestion(
      id: 'q3',
      question: 'Which mathematical graph theory concept is prominently illustrated by Sikku (Brahma Mudi) Kolams?',
      options: [
        'Dijkstra Shortest Path',
        'Eulerian Circuit (closed loop without lifting hand or retracing)',
        'Binary Search Trees',
        'Floating Point Approximation'
      ],
      correctIndex: 1,
      explanation: 'Sikku Kolams are classic real-world manifestations of Eulerian trails and knot theory, where a single unbroken continuous line weaves around dots and returns to its origin.',
      culturalTag: 'Mathematics of Kolam',
    ),
    const QuizQuestion(
      id: 'q4',
      question: 'During which auspicious Tamil winter month do women wake up before 4 AM to draw grand avenue-wide Kolams?',
      options: [
        'Chithirai (April–May)',
        'Aadi (July–August)',
        'Margazhi (December–January)',
        'Purattasi (September–October)'
      ],
      correctIndex: 2,
      explanation: 'Margazhi is celebrated with early morning devotional singing and magnificent street-spanning geometric Kolams adorned with pumpkin flowers.',
      culturalTag: 'Festivals & Living Heritage',
    ),
    const QuizQuestion(
      id: 'q5',
      question: 'What is the traditional name for the red mineral-rich liquid mud border used in sacred Padi Kolams?',
      options: [
        'Kaavi',
        'Kumkum',
        'Manjal',
        'Neelam'
      ],
      correctIndex: 0,
      explanation: 'Kaavi (red terracotta earth paste) is applied in parallel lines framing the white rice kolam, symbolizing the balance of form and energy.',
      culturalTag: 'Ritual Materials',
    ),
    const QuizQuestion(
      id: 'q6',
      question: 'Which regional name corresponds correctly to the floor art tradition of Andhra Pradesh & Telangana?',
      options: [
        'Rangavalli',
        'Muggu',
        'Alpana',
        'Mandana'
      ],
      correctIndex: 1,
      explanation: 'In Andhra Pradesh and Telangana, sacred doorstep floor art is celebrated as Muggu, known for its limestone powder clarity and Sankranti Ratham designs.',
      culturalTag: 'Regional Dialects',
    ),
  ];
}
