import '../../features/profile/domain/entities/file_upload_result.dart';
import '../../features/profile/domain/entities/profile.dart';

/// Event fired when user profile is updated
class ProfileUpdatedEvent {
  const ProfileUpdatedEvent(this.profile);

  final Profile profile;

  @override
  String toString() => 'ProfileUpdatedEvent(profile: ${profile.email})';
}

/// Event fired when profile picture is uploaded
class ProfilePictureUploadedEvent {
  const ProfilePictureUploadedEvent(this.uploadResult);

  final FileUploadResult uploadResult;

  @override
  String toString() =>
      'ProfilePictureUploadedEvent(fileName: ${uploadResult.fileName})';
}

/// Event fired when CV is uploaded
class CVUploadedEvent {
  const CVUploadedEvent(this.uploadResult);

  final FileUploadResult uploadResult;

  @override
  String toString() => 'CVUploadedEvent(fileName: ${uploadResult.fileName})';
}

/// Event fired when profile picture is deleted
class ProfilePictureDeletedEvent {
  const ProfilePictureDeletedEvent(this.userId);

  final int userId;

  @override
  String toString() => 'ProfilePictureDeletedEvent(userId: $userId)';
}

/// Event fired when CV is deleted
class CVDeletedEvent {
  const CVDeletedEvent(this.userId);

  final int userId;

  @override
  String toString() => 'CVDeletedEvent(userId: $userId)';
}
