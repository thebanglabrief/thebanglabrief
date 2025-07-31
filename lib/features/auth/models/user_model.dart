import 'package:cloud_firestore/cloud_firestore.dart';

/// User Role Enumeration
enum UserRole {
  user,
  moderator,
  admin,
}

/// User Model
/// 
/// Represents a user in The Bangla Brief app with role-based access control,
/// notification preferences, and activity tracking.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime? updatedAt;
  final NotificationSettings notificationSettings;
  final UserStats? stats;
  final Map<String, dynamic>? metadata;
  
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.lastLoginAt,
    this.updatedAt,
    required this.notificationSettings,
    this.stats,
    this.metadata,
  });
  
  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (role) => role.name == data['role'],
        orElse: () => UserRole.user,
      ),
      isActive: data['isActive'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      updatedAt: data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
      notificationSettings: NotificationSettings.fromMap(
        data['notificationSettings'] ?? {},
      ),
      stats: data['stats'] != null ? UserStats.fromMap(data['stats']) : null,
      metadata: data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata']) 
          : null,
    );
  }
  
  /// Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'notificationSettings': notificationSettings.toMap(),
      'stats': stats?.toMap(),
      'metadata': metadata,
    };
  }
  
  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
    NotificationSettings? notificationSettings,
    UserStats? stats,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notificationSettings: notificationSettings ?? this.notificationSettings,
      stats: stats ?? this.stats,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// Helper method to parse Firestore timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }
  
  /// Check if user has admin role
  bool get isAdmin => role == UserRole.admin;
  
  /// Check if user has moderator role
  bool get isModerator => role == UserRole.moderator;
  
  /// Check if user has moderator or admin access
  bool get hasModeratorAccess => isAdmin || isModerator;
  
  /// Get user role display name
  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.user:
        return 'User';
    }
  }
  
  /// Get user initials for avatar
  String get initials {
    final names = displayName.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    } else {
      return '${names[0].substring(0, 1)}${names[1].substring(0, 1)}'.toUpperCase();
    }
  }
  
  /// Check if user profile is complete
  bool get isProfileComplete {
    return displayName.isNotEmpty && 
           email.isNotEmpty;
  }
  
  /// Get user registration duration
  Duration get registrationDuration {
    return DateTime.now().difference(createdAt);
  }
  
  /// Get last login duration
  Duration get lastLoginDuration {
    return DateTime.now().difference(lastLoginAt);
  }
  
  @override
  String toString() {
    return 'UserModel{uid: $uid, email: $email, displayName: $displayName, role: $role}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }
  
  @override
  int get hashCode => uid.hashCode;
}

/// Notification Settings Model
class NotificationSettings {
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableVideoNotifications;
  final bool enableBlogNotifications;
  final bool enableChatNotifications;
  final bool enableForumNotifications;
  final String notificationTime; // Format: "HH:mm"
  final List<String> mutedTopics;
  
  const NotificationSettings({
    required this.enablePushNotifications,
    required this.enableEmailNotifications,
    required this.enableVideoNotifications,
    required this.enableBlogNotifications,
    required this.enableChatNotifications,
    this.enableForumNotifications = true,
    this.notificationTime = "09:00",
    this.mutedTopics = const [],
  });
  
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enablePushNotifications: map['enablePushNotifications'] ?? true,
      enableEmailNotifications: map['enableEmailNotifications'] ?? true,
      enableVideoNotifications: map['enableVideoNotifications'] ?? true,
      enableBlogNotifications: map['enableBlogNotifications'] ?? true,
      enableChatNotifications: map['enableChatNotifications'] ?? true,
      enableForumNotifications: map['enableForumNotifications'] ?? true,
      notificationTime: map['notificationTime'] ?? "09:00",
      mutedTopics: List<String>.from(map['mutedTopics'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableVideoNotifications': enableVideoNotifications,
      'enableBlogNotifications': enableBlogNotifications,
      'enableChatNotifications': enableChatNotifications,
      'enableForumNotifications': enableForumNotifications,
      'notificationTime': notificationTime,
      'mutedTopics': mutedTopics,
    };
  }
  
  NotificationSettings copyWith({
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableVideoNotifications,
    bool? enableBlogNotifications,
    bool? enableChatNotifications,
    bool? enableForumNotifications,
    String? notificationTime,
    List<String>? mutedTopics,
  }) {
    return NotificationSettings(
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableVideoNotifications: enableVideoNotifications ?? this.enableVideoNotifications,
      enableBlogNotifications: enableBlogNotifications ?? this.enableBlogNotifications,
      enableChatNotifications: enableChatNotifications ?? this.enableChatNotifications,
      enableForumNotifications: enableForumNotifications ?? this.enableForumNotifications,
      notificationTime: notificationTime ?? this.notificationTime,
      mutedTopics: mutedTopics ?? this.mutedTopics,
    );
  }
}

/// User Statistics Model
class UserStats {
  final int blogPostsCreated;
  final int blogPostsLiked;
  final int commentsPosted;
  final int forumPostsCreated;
  final int forumRepliesPosted;
  final int chatMessagesPosted;
  final int videosWatched;
  final int reputation;
  final DateTime lastActivityAt;
  
  const UserStats({
    this.blogPostsCreated = 0,
    this.blogPostsLiked = 0,
    this.commentsPosted = 0,
    this.forumPostsCreated = 0,
    this.forumRepliesPosted = 0,
    this.chatMessagesPosted = 0,
    this.videosWatched = 0,
    this.reputation = 0,
    required this.lastActivityAt,
  });
  
  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      blogPostsCreated: map['blogPostsCreated'] ?? 0,
      blogPostsLiked: map['blogPostsLiked'] ?? 0,
      commentsPosted: map['commentsPosted'] ?? 0,
      forumPostsCreated: map['forumPostsCreated'] ?? 0,
      forumRepliesPosted: map['forumRepliesPosted'] ?? 0,
      chatMessagesPosted: map['chatMessagesPosted'] ?? 0,
      videosWatched: map['videosWatched'] ?? 0,
      reputation: map['reputation'] ?? 0,
      lastActivityAt: map['lastActivityAt'] is Timestamp
          ? (map['lastActivityAt'] as Timestamp).toDate()
          : map['lastActivityAt'] is DateTime
              ? map['lastActivityAt']
              : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'blogPostsCreated': blogPostsCreated,
      'blogPostsLiked': blogPostsLiked,
      'commentsPosted': commentsPosted,
      'forumPostsCreated': forumPostsCreated,
      'forumRepliesPosted': forumRepliesPosted,
      'chatMessagesPosted': chatMessagesPosted,
      'videosWatched': videosWatched,
      'reputation': reputation,
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
    };
  }
  
  UserStats copyWith({
    int? blogPostsCreated,
    int? blogPostsLiked,
    int? commentsPosted,
    int? forumPostsCreated,
    int? forumRepliesPosted,
    int? chatMessagesPosted,
    int? videosWatched,
    int? reputation,
    DateTime? lastActivityAt,
  }) {
    return UserStats(
      blogPostsCreated: blogPostsCreated ?? this.blogPostsCreated,
      blogPostsLiked: blogPostsLiked ?? this.blogPostsLiked,
      commentsPosted: commentsPosted ?? this.commentsPosted,
      forumPostsCreated: forumPostsCreated ?? this.forumPostsCreated,
      forumRepliesPosted: forumRepliesPosted ?? this.forumRepliesPosted,
      chatMessagesPosted: chatMessagesPosted ?? this.chatMessagesPosted,
      videosWatched: videosWatched ?? this.videosWatched,
      reputation: reputation ?? this.reputation,
      lastActivityAt: lastActivityAt ?? DateTime.now(),
    );
  }
  
  /// Get total content created by user
  int get totalContentCreated {
    return blogPostsCreated + forumPostsCreated + commentsPosted + forumRepliesPosted;
  }
  
  /// Get user activity level based on stats
  UserActivityLevel get activityLevel {
    final totalActivity = totalContentCreated + chatMessagesPosted + videosWatched;
    
    if (totalActivity >= 100) return UserActivityLevel.veryActive;
    if (totalActivity >= 50) return UserActivityLevel.active;
    if (totalActivity >= 20) return UserActivityLevel.moderate;
    if (totalActivity >= 5) return UserActivityLevel.low;
    return UserActivityLevel.new_;
  }
  
  /// Get reputation level
  UserReputationLevel get reputationLevel {
    if (reputation >= 1000) return UserReputationLevel.expert;
    if (reputation >= 500) return UserReputationLevel.experienced;
    if (reputation >= 200) return UserReputationLevel.intermediate;
    if (reputation >= 50) return UserReputationLevel.beginner;
    return UserReputationLevel.new_;
  }
}

/// User Activity Level Enumeration
enum UserActivityLevel {
  new_,
  low,
  moderate,
  active,
  veryActive,
}

/// User Reputation Level Enumeration
enum UserReputationLevel {
  new_,
  beginner,
  intermediate,
  experienced,
  expert,
}

/// Extensions for better string representation
extension UserActivityLevelExtension on UserActivityLevel {
  String get displayName {
    switch (this) {
      case UserActivityLevel.new_:
        return 'New';
      case UserActivityLevel.low:
        return 'Low Activity';
      case UserActivityLevel.moderate:
        return 'Moderate Activity';
      case UserActivityLevel.active:
        return 'Active';
      case UserActivityLevel.veryActive:
        return 'Very Active';
    }
  }
}

extension UserReputationLevelExtension on UserReputationLevel {
  String get displayName {
    switch (this) {
      case UserReputationLevel.new_:
        return 'New Member';
      case UserReputationLevel.beginner:
        return 'Beginner';
      case UserReputationLevel.intermediate:
        return 'Intermediate';
      case UserReputationLevel.experienced:
        return 'Experienced';
      case UserReputationLevel.expert:
        return 'Expert';
    }
  }
}