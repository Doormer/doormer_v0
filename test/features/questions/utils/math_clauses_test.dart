import 'package:doormer/src/features/questions/utils/math_clauses.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _texts(String latex) =>
    mathClauses(latex).map((clause) => clause.latex).toList();

void main() {
  group('breaking an expression up', () {
    test('leaves a short expression whole', () {
      expect(_texts('x'), [r'x']);
      expect(
          _texts(r'\boxed{160\ \mathrm{m^2}}'), [r'\boxed{160\ \mathrm{m^2}}']);
    });

    test('breaks a chain of equalities at each relation', () {
      expect(
        _texts(r'A=5\times32=160\ \mathrm{m^2}'),
        [r'A', r'=5\times32', r'=160\ \mathrm{m^2}'],
      );
    });

    test('carries the relation onto the line it opens', () {
      // A continuation line that starts with the relation reads as the same
      // argument carried on. One that ends with it reads as a sentence cut in
      // half.
      for (final clause in mathClauses(r'a=b=c').skip(1)) {
        expect(clause.latex, startsWith('='));
      }
    });

    test('never breaks inside a term', () {
      // The `=` here belongs to nothing the student can see -- it is inside the
      // fraction's braces, and breaking there would split the fraction.
      expect(_texts(r'\frac{a=b}{c}'), [r'\frac{a=b}{c}']);
      expect(_texts(r'x^{a=b}'), [r'x^{a=b}']);
      expect(_texts(r'\text{is 2=2 true}'), [r'\text{is 2=2 true}']);
    });

    test('never breaks inside a fenced group', () {
      expect(_texts(r'\left(a=b\right)'), [r'\left(a=b\right)']);
    });

    test('reads control words whole', () {
      // Scanning character by character finds `\le` at the front of `\left`,
      // and cutting there hands the renderer a fence with no opening.
      expect(_texts(r'\left(1+2\right)\cdot3'), [r'\left(1+2\right)\cdot3']);
      expect(_texts(r'\leftarrow x'), [r'\leftarrow x']);
      // `\top` opens with `\to` and `\neg` with `\ne`, but neither is a
      // relation, so neither is a place to break.
      expect(_texts(r'A\top B'), [r'A\top B']);
      expect(_texts(r'p\neg q'), [r'p\neg q']);
    });

    test('breaks at a worded relation', () {
      expect(
        _texts(r'\frac{24}{W}=\frac{3}{4}\quad\Longrightarrow\quad W=32'),
        [r'\frac{24}{W}', r'=\frac{3}{4}', r'\Longrightarrow', r'W', r'=32'],
      );
    });

    test('turns explicit spacing into a gap rather than leaving it in the text',
        () {
      // A `\quad` left at the head of a wrapped line would print as a stray
      // indent on top of the indent the flow already applies.
      final clauses = mathClauses(r'a=1\qquad b=2');
      expect(clauses.map((clause) => clause.latex), isNot(contains(r'\qquad')));
      expect(clauses.firstWhere((clause) => clause.latex.startsWith('b')).gapEm,
          2);
    });

    test('spaces a relation the way TeX would have', () {
      final clauses = mathClauses(r'A=160');
      expect(clauses.last.gapEm, mathRelationGapEm);
      expect(clauses.first.gapEm, 0,
          reason: 'nothing sits in front of the opening clause');
    });

    test('never shaves a backslash off the end of a clause', () {
      // `\ ` is a token, not a space: trimming it as whitespace would leave a
      // dangling backslash and the whole expression would fail to render.
      expect(_texts(r'A=160\ \qquad B=2'), [r'A', r'=160\ ', r'B', r'=2']);
    });

    test('leaves an environment alone', () {
      const matrix = r'\begin{matrix}a=1\\b=2\end{matrix}';
      expect(_texts(matrix), [matrix]);
    });

    test('leaves an alignment alone', () {
      const aligned = r'a&=1';
      expect(_texts(aligned), [aligned]);
    });

    test('handles a relation with nothing in front of it', () {
      expect(_texts(r'=160'), [r'=160']);
    });
  });
}
