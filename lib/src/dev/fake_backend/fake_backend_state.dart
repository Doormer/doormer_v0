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

/// A card shown as a picture: which deck, and which card in it.
typedef FakePicture = ({String deckId, String cardId});

/// Another student, as the fake backend's student can meet them through
/// friends.
class FakeStudent {
  final String id;
  final String nickname;

  /// 8 characters with no dash.
  final String friendCode;

  /// Null for the nickname's first letter.
  final FakePicture? picture;

  /// Their copies, by deck id and then card id: what friends see.
  final Map<String, Map<String, FakeHolding>> holdings;

  /// Their active days. Friends see the level they reach, from level 1.
  final int activeDays;

  const FakeStudent({
    required this.id,
    required this.nickname,
    required this.friendCode,
    this.picture,
    this.holdings = const {},
    this.activeDays = 0,
  });
}

/// A request to the student, waiting for an answer.
class FakeFriendRequest {
  final String id;
  final String fromId;
  final DateTime sentAt;

  const FakeFriendRequest({
    required this.id,
    required this.fromId,
    required this.sentAt,
  });
}

/// The student's own friend profile.
class FakeFriendProfile {
  String nickname;
  FakePicture? picture;
  String friendCode;

  FakeFriendProfile({
    required this.nickname,
    this.picture,
    required this.friendCode,
  });
}

/// The student's friends, their requests, and the students around them.
class FakeFriends {
  /// Null until the student sets up friends.
  FakeFriendProfile? profile;

  /// Every other student the fake knows.
  final List<FakeStudent> students;

  final Set<String> friendIds;

  /// Newest first.
  final List<FakeFriendRequest> waitingRequests;

  /// The requests the student accepted, with Accept or by sending a request
  /// back. Accepting one again answers with its friend again.
  final List<FakeFriendRequest> acceptedRequests;

  /// The students the student has a request waiting with.
  final Set<String> requestedIds;

  /// Newest block first.
  final List<String> blockedIds;

  /// Every report sent: who, why, and the note.
  final List<({String studentId, String reason, String note})> reports;

  FakeFriends({
    required this.profile,
    required this.students,
    required this.friendIds,
    required this.waitingRequests,
  })  : acceptedRequests = [],
        requestedIds = {},
        blockedIds = [],
        reports = [];

  /// Kai, set up, with two friends who have cards (Sam, at level 6, and
  /// Alex, at level 0), a request from Rua, at level 2, and Nia, whose code
  /// `NEWS2345` can be found.
  factory FakeFriends.starting({required DateTime now}) => FakeFriends(
        profile: FakeFriendProfile(
          nickname: 'Kai',
          picture: (deckId: 'meridian-01', cardId: 'gnomon'),
          friendCode: 'K7QM2XPA',
        ),
        students: [
          FakeStudent(
            id: '201',
            nickname: 'Sam',
            friendCode: 'SAMQ2345',
            picture: (deckId: 'cinder-01', cardId: 'flint'),
            activeDays: 60,
            holdings: {
              'cinder-01': {
                'flint': FakeHolding(standardCopies: 2),
                'wick': FakeHolding(standardCopies: 1),
                'kiln': FakeHolding(specialCopies: 1),
              },
            },
          ),
          FakeStudent(
            id: '202',
            nickname: 'Alex',
            friendCode: 'ALEX7777',
            activeDays: 2,
            holdings: {
              'meridian-01': {
                'gnomon': FakeHolding(standardCopies: 1),
                'vernier': FakeHolding(standardCopies: 3),
                'orrery': FakeHolding(standardCopies: 1, specialCopies: 1),
              },
              'cinder-01': {
                'crucible': FakeHolding(standardCopies: 1),
              },
            },
          ),
          const FakeStudent(
            id: '203',
            nickname: 'Rua',
            friendCode: 'RUAR5555',
            picture: (deckId: 'meridian-01', cardId: 'vernier'),
            activeDays: 12,
          ),
          const FakeStudent(id: '204', nickname: 'Nia', friendCode: 'NEWS2345'),
        ],
        friendIds: {'201', '202'},
        waitingRequests: [
          FakeFriendRequest(
            id: '501',
            fromId: '203',
            sentAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
      );

  FakeStudent? studentById(String? id) =>
      students.where((student) => student.id == id).firstOrNull;

  FakeStudent? studentByCode(String? code) =>
      students.where((student) => student.friendCode == code).firstOrNull;
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

  /// The student's active days.
  int activeDays;

  /// Photos started and questions solved today, whether today has counted
  /// as an active day, and when today ends. [startNewDayIfDue] starts a new
  /// day once [dayEndsAt] has passed.
  int photosSentToday = 0;
  int questionsSolvedToday = 0;
  bool countedToday = false;
  DateTime? dayEndsAt;

  /// The `Idempotency-Key` of the photo being solved, if one is.
  String? solvingKey;

  final FakeFriends friends;

  int _lastQuestionNumber = 1000;
  int _lastTokenNumber = 0;

  FakeBackendState({
    required this.registrationStatus,
    required this.quarkBalance,
    required this.activeDays,
    required this.holdings,
    required this.solvedQuestions,
    required this.friends,
  });

  /// A registered student with quarks for five draws, three Meridian cards
  /// (one with a spare copy to shatter, one with a special copy), nothing
  /// from Cinder, three saved questions, friends as [FakeFriends.starting]
  /// has them, and 31 active days: the first count after a reload makes the
  /// 32nd, a new moon at level 4.
  factory FakeBackendState.starting({required DateTime now}) =>
      FakeBackendState(
        registrationStatus: 1,
        quarkBalance: 200,
        activeDays: 31,
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
        friends: FakeFriends.starting(now: now),
      );

  /// The copies of [cardId] held in [deckId]; none for a card never drawn.
  FakeHolding holdingOf(String deckId, String cardId) => holdings
      .putIfAbsent(deckId, () => {})
      .putIfAbsent(cardId, FakeHolding.new);

  /// Starts a new day once the last one has ended, at the device's midnight:
  /// the photos, the questions and the active day start over. The API's day
  /// is Auckland's; the fake's is the device's own.
  void startNewDayIfDue(DateTime now) {
    final dayEndsAt = this.dayEndsAt;
    if (dayEndsAt != null && now.isBefore(dayEndsAt)) return;
    final local = now.toLocal();
    this.dayEndsAt = DateTime(local.year, local.month, local.day + 1);
    photosSentToday = 0;
    questionsSolvedToday = 0;
    countedToday = false;
  }

  FakeSolvedQuestion? solvedQuestion(String? id) =>
      solvedQuestions.where((question) => question.id == id).firstOrNull;

  String newQuestionId() => '${++_lastQuestionNumber}';

  /// A [kind] of token unlike any given before, such as `access`.
  String newToken(String kind) => 'fake-$kind-token-${++_lastTokenNumber}';
}
