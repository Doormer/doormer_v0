import '../entity/report_reason.dart';

/// How the API names each [ReportReason] in `/friends/report`'s `reason`.
abstract final class ReportReasonModel {
  static String toJson(ReportReason reason) => switch (reason) {
        ReportReason.rudeNickname => 'rude_nickname',
        ReportReason.bullying => 'bullying',
        ReportReason.pretending => 'pretending',
        ReportReason.other => 'other',
      };
}
