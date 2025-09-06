/// Domain entity representing file upload result
class FileUploadResult {
  const FileUploadResult({
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
    this.mimeType,
  });

  final String fileName;
  final String fileUrl;
  final int fileSize;
  final DateTime uploadedAt;
  final String? mimeType;

  /// Get formatted file size (e.g., "2.5 MB")
  String get formattedSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if upload is recent (within 5 minutes)
  bool get isRecentUpload =>
      DateTime.now().difference(uploadedAt).inMinutes < 5;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileUploadResult &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          fileUrl == other.fileUrl;

  @override
  int get hashCode => Object.hash(fileName, fileUrl);

  @override
  String toString() =>
      'FileUploadResult(fileName: $fileName, size: $formattedSize)';
}
