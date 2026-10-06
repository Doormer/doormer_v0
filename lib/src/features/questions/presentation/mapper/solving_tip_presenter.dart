/// Study tips shown while a photo is being solved, one per solve.
const List<String> solvingTips = [
  'Read the question twice and underline what it asks you to find.',
  'Write down what the question gives you before you start working.',
  'Estimate the answer first, so you can tell if your result is way off.',
  'Draw a quick sketch for any question about shapes, angles or distances.',
  'Keep the units on every line. They catch mistakes early.',
  'Check your answer by putting it back into the original question.',
  'Stuck? Try the same question with simpler numbers to see the pattern.',
  'Look over your working one line at a time to find a slip.',
];

/// The tip for a solve, picked by the photo's size in bytes.
///
/// The same photo always gets the same tip, so the tip holds still for the
/// whole solve, and through a retry, without the page keeping any state.
/// Page-invoked only.
String solvingTipFor({required int photoSize}) =>
    solvingTips[photoSize % solvingTips.length];
