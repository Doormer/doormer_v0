import 'package:doormer/src/shared/friends/entity/report_reason.dart';
import 'package:doormer/src/shared/friends/model/report_reason_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (reason, name) in [
    (ReportReason.rudeNickname, 'rude_nickname'),
    (ReportReason.bullying, 'bullying'),
    (ReportReason.pretending, 'pretending'),
    (ReportReason.other, 'other'),
  ]) {
    test('sends $reason as $name', () {
      expect(ReportReasonModel.toJson(reason), name);
    });
  }
}
