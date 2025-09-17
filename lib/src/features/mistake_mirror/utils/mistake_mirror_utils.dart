import 'package:flutter/material.dart';

class MistakeMirrorValidators {
  static String? validateImageFile(String? fileName, int? fileSize) {
    if (fileName == null || fileName.isEmpty) {
      return 'Please select an image file';
    }

    // Check file extension
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'];
    final fileExtension = fileName.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(fileExtension)) {
      return 'Invalid file format. Supported: ${allowedExtensions.join(', ')}';
    }

    // Check file size (max 10MB)
    if (fileSize != null && fileSize > 10 * 1024 * 1024) {
      return 'File size too large. Maximum size is 10MB';
    }

    return null;
  }

  static bool isValidImageFile(String fileName) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'];
    final fileExtension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(fileExtension);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

class MistakeMirrorConstants {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'svg',
    'webp'
  ];

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration loadingMessageInterval = Duration(seconds: 2);

  static const String defaultErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String fileUploadErrorMessage =
      'Failed to upload file. Please try again.';
}

class MistakeMirrorUtils {
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  static IconData getQuestionTypeIcon(String questionType) {
    switch (questionType.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return Icons.calculate;
      case 'physics':
        return Icons.science;
      case 'chemistry':
        return Icons.biotech;
      case 'text':
      case 'reading':
        return Icons.text_fields;
      default:
        return Icons.help_outline;
    }
  }

  static String getQuestionTypeDescription(String questionType) {
    switch (questionType.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return 'Mathematical problem solving';
      case 'physics':
        return 'Physics concepts and calculations';
      case 'chemistry':
        return 'Chemical equations and reactions';
      case 'text':
      case 'reading':
        return 'Text comprehension and analysis';
      default:
        return 'General question analysis';
    }
  }

  static List<Color> getGradientColors(String type) {
    switch (type.toLowerCase()) {
      case 'primary':
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      case 'success':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'warning':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'error':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      default:
        return [const Color(0xFF64748B), const Color(0xFF475569)];
    }
  }
}
