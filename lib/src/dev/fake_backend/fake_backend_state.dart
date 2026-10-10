/// Copies of one card that the student holds, by variant.
class FakeHolding {
  int standardCopies;
  int specialCopies;

  FakeHolding({this.standardCopies = 0, this.specialCopies = 0});

  int get totalCopies => standardCopies + specialCopies;
}

/// A question the student has solved from a photo.
class FakeSolvedQuestion {
  final String id;
  final String topic;
  final String method;
  final String questionText;
  final DateTime askedAt;

  /// Whether the student has opened the answer. Only the first time pays.
  bool answerRevealed;

  FakeSolvedQuestion({
    required this.id,
    required this.topic,
    required this.method,
    required this.questionText,
    required this.askedAt,
    this.answerRevealed = false,
  });
}

/// Everything the fake backend remembers about its one student.
class FakeBackendState {
  /// `0` until the student finishes registration, then `1`.
  int registrationStatus;

  int quarkBalance;

  /// Copies held, by deck id and then card id.
  final Map<String, Map<String, FakeHolding>> holdings;

  /// Newest first.
  final List<FakeSolvedQuestion> solvedQuestions;

  int _lastQuestionNumber = 1000;
  int _lastTokenNumber = 0;

  FakeBackendState({
    required this.registrationStatus,
    required this.quarkBalance,
    required this.holdings,
    required this.solvedQuestions,
  });

  /// A registered student with quarks for five draws, three Meridian cards
  /// (one with a spare copy to shatter, one with a special copy), nothing
  /// from Cinder, and three saved questions.
  factory FakeBackendState.starting({required DateTime now}) =>
      FakeBackendState(
        registrationStatus: 1,
        quarkBalance: 200,
        holdings: {
          'meridian-01': {
            'gnomon': FakeHolding(standardCopies: 2),
            'vernier': FakeHolding(standardCopies: 1, specialCopies: 1),
            'astrolabe': FakeHolding(standardCopies: 1),
          },
        },
        solvedQuestions: [
          FakeSolvedQuestion(
            id: '101',
            topic: 'Geometry - Area',
            method: 'Trigonometry and parallelogram area',
            questionText: 'Find the area of the printed rectangle.',
            askedAt: now.subtract(const Duration(days: 1)),
          ),
          FakeSolvedQuestion(
            id: '102',
            topic: 'Algebra - Linear equations',
            method: 'Balancing both sides',
            questionText: 'Solve 3x + 7 = 22.',
            askedAt: now.subtract(const Duration(days: 3)),
          ),
          FakeSolvedQuestion(
            id: '103',
            topic: 'Probability - Combined events',
            method: 'Tree diagram',
            questionText: 'A bag holds 3 red and 5 blue marbles. Two are '
                'drawn without replacement. What is the chance both are red?',
            askedAt: now.subtract(const Duration(days: 10)),
          ),
        ],
      );

  /// The copies of [cardId] held in [deckId]; none for a card never drawn.
  FakeHolding holdingOf(String deckId, String cardId) => holdings
      .putIfAbsent(deckId, () => {})
      .putIfAbsent(cardId, FakeHolding.new);

  FakeSolvedQuestion? solvedQuestion(String? id) =>
      solvedQuestions.where((question) => question.id == id).firstOrNull;

  String newQuestionId() => '${++_lastQuestionNumber}';

  /// A [kind] of token unlike any given before, such as `access`.
  String newToken(String kind) => 'fake-$kind-token-${++_lastTokenNumber}';
}
