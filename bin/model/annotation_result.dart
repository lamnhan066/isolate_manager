class AnnotationResult {
  final String workerName;
  final bool isCustomWorker;

  AnnotationResult({
    required this.workerName,
    required this.isCustomWorker,
  });

  AnnotationResult copyWith({
    String? workerName,
    bool? isCustomWorker,
  }) {
    return AnnotationResult(
      workerName: workerName ?? this.workerName,
      isCustomWorker: isCustomWorker ?? this.isCustomWorker,
    );
  }
}
