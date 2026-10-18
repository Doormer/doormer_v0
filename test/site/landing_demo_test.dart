import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;

void main() {
  final home = html_parser.parse(
    File('web/site/pages/home.html').readAsStringSync(),
  );

  test('the photo comparison needs no button to reveal what is read', () {
    final photo = home.querySelector('.demo__photo')!;
    expect(photo.querySelectorAll('button'), isEmpty);
    expect(photo.querySelector('[data-demo-photo-label]'), isNotNull);
    expect(
        photo.text, contains('Printed question kept. Your working set aside.'));
  });

  test('the illustration is labelled and has no pretend actions', () {
    final preview = home.querySelector('.hero__preview');
    expect(preview, isNotNull);
    expect(preview!.querySelector('figcaption')!.text, contains('App preview'));
    expect(preview.querySelectorAll('button, a, summary, [tabindex]'), isEmpty);
    expect(preview.text, isNot(contains('Next step')));
    expect(preview.text, isNot(contains('Why this works')));
  });

  test('the working demo explains where to begin', () {
    final demo = home.querySelector('#demo')!;
    expect(demo.querySelector('.eyebrow')!.text, contains('Interactive demo'));
    final hint = demo.querySelector('#demo-controls-hint')!;
    expect(hint.text, contains('Start solving'));
    final controls = demo.querySelector('[data-demo-controls]')!;
    expect(controls.attributes['aria-describedby'], hint.id);
    expect(controls.querySelector('button[data-demo-next]'), isNotNull);
  });

  test('the static explanation example has no pretend disclosure control', () {
    final example = home.querySelector('.why-card')!;
    expect(example.querySelector('.why-card__heading')?.text, 'Why this works');
    expect(example.querySelectorAll('.why-card__toggle, summary, button'),
        isEmpty);
    expect(example.text, isNot(contains('⌃')));
  });
}
