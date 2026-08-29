import 'package:doormer/src/features/questions/presentation/atoms/vault_chains_atom.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the vault chain geometry', () {
    test('reaches past the node so the chain reads as wrapping around behind',
        () {
      for (var i = 0; i < 3; i++) {
        final pieces = vaultChainSegments(index: i, phase: 0);
        expect(pieces.first.start.dx, lessThanOrEqualTo(-19.5),
            reason: 'a chain that stops at the silhouette is painted on, not '
                'wrapped around');
        expect(pieces.last.end.dx, greaterThanOrEqualTo(19.5));
      }
    });

    test('reaches furthest across the widest part of the vault', () {
      final outer = vaultChainSegments(index: 0, phase: 0).single.end.dx;
      final middle = vaultChainSegments(index: 2, phase: 0).last.end.dx;

      expect(middle, greaterThan(outer),
          reason: 'the outer chains cross the corner curve, where the box has '
              'already begun to pull in. Reaching the same distance leaves the '
              'middle chain -- the one across the waist -- short of the edge');
    });

    test('draws every chain as one unbroken length', () {
      for (var i = 0; i < 3; i++) {
        final pieces = vaultChainSegments(index: i, phase: 0);

        expect(pieces, hasLength(1),
            reason: 'a chain with a hole already cut in it is a chain somebody '
                'has already been through, which is the one thing the student '
                'has not done yet');
        expect(pieces.single.start.dx, lessThan(0));
        expect(pieces.single.end.dx, greaterThan(0));
        expect(pieces.single.start.dy, pieces.single.end.dy,
            reason: 'a chain lying across a box lies level');
      }
    });

    test('strains before it breaks', () {
      final intact = vaultChainSegments(index: 0, phase: 0).single;
      final strained = vaultChainSegments(index: 0, phase: 0.2).single;

      expect(strained.end.dx, greaterThan(intact.end.dx),
          reason: 'the chain should pull taut before it lets go');
    });

    test('breaks into two halves whose free ends fall', () {
      final halves = vaultChainSegments(index: 0, phase: 0.7);

      expect(halves, hasLength(2),
          reason: 'a chain that is flung away in one piece was unhooked, not '
              'broken');
      for (final half in halves) {
        expect(half.end.dy, greaterThan(half.start.dy + 2),
            reason: 'each half pivots on its outer end, so the inner end is '
                'the one that drops');
      }
      expect(halves.first.start.dx, lessThan(halves.last.start.dx));
    });

    test('is gone by the end of the snap', () {
      expect(vaultChainSegments(index: 0, phase: 1), isEmpty);
    });
  });
}
