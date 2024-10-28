class AnnotationResult {
  AnnotationResult({
    required this.workerName,
    required this.isCustomWorker,
  });
  final String workerName;
  final bool isCustomWorker;

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
