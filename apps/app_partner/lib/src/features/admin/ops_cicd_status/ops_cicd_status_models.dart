enum OpsCicdState {
  success,
  warning,
  failure,
  running,
  unknown
  ;

  static OpsCicdState fromJson(String? value) {
    return OpsCicdState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => OpsCicdState.unknown,
    );
  }
}

class OpsCicdStatusSnapshot {
  const OpsCicdStatusSnapshot({
    required this.generatedAt,
    required this.repository,
    required this.branches,
    required this.issues,
  });

  factory OpsCicdStatusSnapshot.fromJson(Map<String, dynamic> json) {
    return OpsCicdStatusSnapshot(
      generatedAt: DateTime.parse(json['generated_at'] as String),
      repository: json['repository'] as String? ?? '',
      branches: (json['branches'] as List? ?? const [])
          .map((item) => OpsCicdBranch.fromJson(item as Map<String, dynamic>))
          .toList(),
      issues: (json['issues'] as List? ?? const [])
          .map((item) => OpsCicdIssue.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final DateTime generatedAt;
  final String repository;
  final List<OpsCicdBranch> branches;
  final List<OpsCicdIssue> issues;
}

class OpsCicdBranch {
  const OpsCicdBranch({
    required this.key,
    required this.branchName,
    required this.headSha,
    required this.state,
    required this.workflows,
    required this.commitStatuses,
  });

  factory OpsCicdBranch.fromJson(Map<String, dynamic> json) {
    return OpsCicdBranch(
      key: json['key'] as String? ?? '',
      branchName: json['branch_name'] as String?,
      headSha: json['head_sha'] as String?,
      state: OpsCicdState.fromJson(json['state'] as String?),
      workflows: (json['workflows'] as List? ?? const [])
          .map((item) => OpsCicdWorkflow.fromJson(item as Map<String, dynamic>))
          .toList(),
      commitStatuses: (json['commit_statuses'] as List? ?? const [])
          .map(
            (item) =>
                OpsCicdCommitStatus.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String key;
  final String? branchName;
  final String? headSha;
  final OpsCicdState state;
  final List<OpsCicdWorkflow> workflows;
  final List<OpsCicdCommitStatus> commitStatuses;
}

class OpsCicdWorkflow {
  const OpsCicdWorkflow({
    required this.key,
    required this.file,
    required this.lane,
    required this.label,
    required this.state,
    required this.status,
    required this.conclusion,
    required this.runId,
    required this.runUrl,
    required this.updatedAt,
  });

  factory OpsCicdWorkflow.fromJson(Map<String, dynamic> json) {
    return OpsCicdWorkflow(
      key: json['key'] as String? ?? '',
      file: json['file'] as String? ?? '',
      lane: json['lane'] as String? ?? '',
      label: json['label'] as String? ?? '',
      state: OpsCicdState.fromJson(json['state'] as String?),
      status: json['status'] as String?,
      conclusion: json['conclusion'] as String?,
      runId: json['run_id'] as int?,
      runUrl: json['run_url'] as String?,
      updatedAt: _tryParseDateTime(json['updated_at'] as String?),
    );
  }

  final String key;
  final String file;
  final String lane;
  final String label;
  final OpsCicdState state;
  final String? status;
  final String? conclusion;
  final int? runId;
  final String? runUrl;
  final DateTime? updatedAt;
}

class OpsCicdCommitStatus {
  const OpsCicdCommitStatus({
    required this.context,
    required this.state,
    required this.description,
    required this.targetUrl,
    required this.updatedAt,
  });

  factory OpsCicdCommitStatus.fromJson(Map<String, dynamic> json) {
    return OpsCicdCommitStatus(
      context: json['context'] as String? ?? '',
      state: json['state'] as String? ?? 'unknown',
      description: json['description'] as String?,
      targetUrl: json['target_url'] as String?,
      updatedAt:
          _tryParseDateTime(json['updated_at'] as String?) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String context;
  final String state;
  final String? description;
  final String? targetUrl;
  final DateTime updatedAt;
}

class OpsCicdIssue {
  const OpsCicdIssue({
    required this.number,
    required this.title,
    required this.state,
    required this.url,
    required this.labels,
    required this.updatedAt,
  });

  factory OpsCicdIssue.fromJson(Map<String, dynamic> json) {
    return OpsCicdIssue(
      number: json['number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      state: json['state'] as String? ?? '',
      url: json['url'] as String? ?? '',
      labels: (json['labels'] as List? ?? const []).cast<String>(),
      updatedAt:
          _tryParseDateTime(json['updated_at'] as String?) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final int number;
  final String title;
  final String state;
  final String url;
  final List<String> labels;
  final DateTime updatedAt;
}

DateTime? _tryParseDateTime(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
