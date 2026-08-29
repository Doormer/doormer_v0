import 'dart:math' as math;

/// One piece of a LaTeX expression that is allowed to start its own line.
///
/// Long working is broken where a textbook breaks it: at the relation, with the
/// relation leading the continuation line, so
///
///     A = 5 x 32
///       = 160 m^2
///
/// reads as one argument carried on rather than as two separate claims.
/// Everything between two relations travels together — cutting inside a term
/// would leave the student reading half a fraction.
class MathClause {
  final String latex;

  /// Space belonging in front of this clause, in ems, so that clauses landing
  /// on the same line sit exactly where TeX would have set them.
  final double gapEm;

  const MathClause({required this.latex, required this.gapEm});

  @override
  bool operator ==(Object other) =>
      other is MathClause && other.latex == latex && other.gapEm == gapEm;

  @override
  int get hashCode => Object.hash(latex, gapEm);

  @override
  String toString() => 'MathClause($latex, gapEm: $gapEm)';
}

/// TeX sets a thickmuskip (5mu, or 5/18 of an em) either side of a relation.
/// A clause led by a relation loses the space in front of it, because a
/// relation opening a list has nothing to be spaced from — so the flow puts it
/// back.
const mathRelationGapEm = 5 / 18;

const _relationWords = <String>{
  'ne',
  'neq',
  'le',
  'leq',
  'leqslant',
  'ge',
  'geq',
  'geqslant',
  'approx',
  'equiv',
  'sim',
  'simeq',
  'cong',
  'propto',
  'doteq',
  'to',
  'gets',
  'mapsto',
  'rightarrow',
  'Rightarrow',
  'longrightarrow',
  'Longrightarrow',
  'leftarrow',
  'Leftarrow',
  'longleftarrow',
  'Longleftarrow',
  'leftrightarrow',
  'Leftrightarrow',
  'longleftrightarrow',
  'Longleftrightarrow',
  'implies',
  'impliedby',
  'iff',
  'therefore',
  'because',
};

/// Explicit spacing the author wrote between two statements. It is dropped
/// from the text and handed to the flow as a gap, so that when the statements
/// do land on separate lines the space does not become a stray indent.
const _spacingWords = <String, double>{'quad': 1, 'qquad': 2};

/// Breaks [latex] into the clauses it may be wrapped at.
///
/// Returns a single clause when there is nothing safe to break — the caller
/// then has one unbreakable expression and must fall back to scrolling it.
List<MathClause> mathClauses(String latex) {
  final whole = [MathClause(latex: latex, gapEm: 0)];

  // An environment or an alignment column carries its own line structure.
  // Cutting one up would hand the renderer half a table.
  if (latex.contains(r'\begin') || latex.contains('&')) return whole;

  final clauses = <MathClause>[];
  final buffer = <String>[];
  var gap = 0.0;
  var braces = 0;
  var fences = 0;

  void breakHere(double gapAfter) {
    // Only ever plain spaces: `\ ` is a two-character token, so an explicit
    // thin space can never be shaved off and leave a dangling backslash.
    while (buffer.isNotEmpty && buffer.last == ' ') {
      buffer.removeLast();
    }
    while (buffer.isNotEmpty && buffer.first == ' ') {
      buffer.removeAt(0);
    }
    if (buffer.isEmpty) {
      gap = math.max(gap, gapAfter);
      return;
    }
    clauses.add(MathClause(
      latex: buffer.join(),
      gapEm: clauses.isEmpty ? 0 : gap,
    ));
    buffer.clear();
    gap = gapAfter;
  }

  var index = 0;
  while (index < latex.length) {
    final token = _tokenAt(latex, index);
    index += token.length;
    final topLevel = braces == 0 && fences == 0;

    if (token.length > 1 && token.startsWith(r'\')) {
      final word = token.substring(1);
      if (word == 'left') {
        fences++;
      } else if (word == 'right') {
        fences = math.max(0, fences - 1);
      } else if (topLevel && _spacingWords.containsKey(word)) {
        breakHere(_spacingWords[word]!);
        continue;
      } else if (topLevel && _relationWords.contains(word)) {
        breakHere(mathRelationGapEm);
      }
      buffer.add(token);
      continue;
    }

    if (token == '{') {
      braces++;
    } else if (token == '}') {
      braces = math.max(0, braces - 1);
    } else if (topLevel && (token == '=' || token == '<' || token == '>')) {
      breakHere(mathRelationGapEm);
    }
    buffer.add(token);
  }
  breakHere(0);

  return clauses.length < 2 ? whole : clauses;
}

/// Reads one LaTeX token at [start]: a whole control word, a control symbol,
/// or a single character.
///
/// Control words must be read whole. Scanning for `\le` character by character
/// would find one at the front of `\left(` and cut a fence in half.
String _tokenAt(String source, int start) {
  final char = source[start];
  if (char != r'\' || start + 1 >= source.length) return char;
  if (!_isLetter(source[start + 1])) {
    return source.substring(start, start + 2);
  }
  var end = start + 1;
  while (end < source.length && _isLetter(source[end])) {
    end++;
  }
  return source.substring(start, end);
}

bool _isLetter(String character) {
  final code = character.codeUnitAt(0);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}
