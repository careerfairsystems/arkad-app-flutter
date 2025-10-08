enum PermissionType { location, bluetoothScan }

enum PermissionStatus { notRequested, granted, denied, permanentlyDenied }

class PermissionRequest {
  const PermissionRequest({
    required this.type,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.status,
  });

  final PermissionType type;
  final String title;
  final String description;
  final String iconPath;
  final PermissionStatus status;

  PermissionRequest copyWith({
    PermissionType? type,
    String? title,
    String? description,
    String? iconPath,
    PermissionStatus? status,
  }) {
    return PermissionRequest(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      status: status ?? this.status,
    );
  }
}
