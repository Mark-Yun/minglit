// Fix #1934: widget moved to common/widgets/match_results_content.dart to
// break the cross-feature import from event/admission. This file stays here
// so the home feature's internal import path doesn't change.
import 'package:app_user/src/common/widgets/match_results_content.dart';

export 'package:app_user/src/common/widgets/match_results_content.dart';

typedef ResultsContent = MatchResultsContent;
