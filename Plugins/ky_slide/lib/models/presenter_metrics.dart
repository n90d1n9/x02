import 'dart:math' as math;

/// Metrics and statistics for presenter view dashboard
class PresenterMetrics {
  final int totalSlides;
  final int currentSlideIndex;
  final Duration elapsedTime;
  final int wordCountNotes;
  final double averageTimePerSlide;
  final bool isOnSchedule;
  final String? scheduleStatus;

  const PresenterMetrics({
    required this.totalSlides,
    required this.currentSlideIndex,
    required this.elapsedTime,
    required this.wordCountNotes,
    required this.averageTimePerSlide,
    required this.isOnSchedule,
    this.scheduleStatus,
  });

  /// Calculate remaining slides
  int get remainingSlides => totalSlides - currentSlideIndex - 1;

  /// Calculate completion percentage
  double get completionPercentage {
    if (totalSlides == 0) return 0.0;
    return ((currentSlideIndex + 1) / totalSlides) * 100;
  }

  /// Format elapsed time as HH:MM:SS or MM:SS
  String get formattedElapsedTime {
    final hours = elapsedTime.inHours;
    final minutes = elapsedTime.inMinutes.remainder(60);
    final seconds = elapsedTime.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  /// Format current wall clock time
  static String get formattedClock {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
           '${now.minute.toString().padLeft(2, '0')}';
  }

  /// Estimate remaining presentation time based on average
  Duration get estimatedRemainingTime {
    if (currentSlideIndex < 0 || elapsedTime.inSeconds == 0) {
      return Duration.zero;
    }
    final avgTimePerSlide = elapsedTime.inSeconds / (currentSlideIndex + 1);
    return Duration(seconds: (avgTimePerSlide * remainingSlides).round());
  }

  /// Get estimated end time
  DateTime get estimatedEndTime {
    return DateTime.now().add(estimatedRemainingTime);
  }

  /// Create metrics from presentation state
  factory PresenterMetrics.fromPresentation({
    required int totalSlides,
    required int currentSlideIndex,
    required Duration elapsedTime,
    required String? currentSlideNotes,
    required Duration? targetDuration,
  }) {
    final wordCount = currentSlideNotes?.trim().isNotEmpty == true
        ? currentSlideNotes!.split(' ').length
        : 0;

    final avgTime = currentSlideIndex >= 0 && elapsedTime.inSeconds > 0
        ? elapsedTime.inSeconds / (currentSlideIndex + 1)
        : 0.0;

    bool isOnSchedule = true;
    String? scheduleStatus;

    if (targetDuration != null && targetDuration.inSeconds > 0) {
      final estimatedTotal = avgTime * totalSlides;
      final ratio = estimatedTotal / targetDuration.inSeconds;

      if (ratio > 1.1) {
        isOnSchedule = false;
        scheduleStatus = 'Running ${((ratio - 1) * 100).toInt()}% over';
      } else if (ratio < 0.9) {
        scheduleStatus = 'Running ${(1 - ratio) * 100).toInt()}% under';
      } else {
        scheduleStatus = 'On track';
      }
    }

    return PresenterMetrics(
      totalSlides: totalSlides,
      currentSlideIndex: currentSlideIndex,
      elapsedTime: elapsedTime,
      wordCountNotes: wordCount,
      averageTimePerSlide: avgTime,
      isOnSchedule: isOnSchedule,
      scheduleStatus: scheduleStatus,
    );
  }

  @override
  String toString() {
    return 'PresenterMetrics(slides: $currentSlideIndex/$totalSlides, '
           'time: $formattedElapsedTime, '
           'progress: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}

/// Speaker notes analysis metrics
class SpeakerNotesMetrics {
  final int wordCount;
  final int characterCount;
  final int sentenceCount;
  final Duration estimatedSpeakingTime;

  const SpeakerNotesMetrics({
    required this.wordCount,
    required this.characterCount,
    required this.sentenceCount,
    required this.estimatedSpeakingTime,
  });

  /// Analyze text and calculate metrics
  factory SpeakerNotesMetrics.fromText(String text) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return const SpeakerNotesMetrics(
        wordCount: 0,
        characterCount: 0,
        sentenceCount: 0,
        estimatedSpeakingTime: Duration.zero,
      );
    }

    // Count words (split by whitespace, filter empty)
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final wordCount = words.length;

    // Count characters (excluding whitespace)
    final characterCount = trimmed.replaceAll(' ', '').length;

    // Count sentences (approximate by punctuation)
    final sentences = trimmed.split(RegExp(r'[.!?]+'));
    final sentenceCount = sentences.where((s) => s.trim().isNotEmpty).length;

    // Estimate speaking time (average 150 words per minute)
    final speakingSeconds = (wordCount / 150 * 60).round();
    final estimatedSpeakingTime = Duration(seconds: speakingSeconds);

    return SpeakerNotesMetrics(
      wordCount: wordCount,
      characterCount: characterCount,
      sentenceCount: math.max(1, sentenceCount),
      estimatedSpeakingTime: estimatedSpeakingTime,
    );
  }

  /// Get formatted word count label
  String get wordLabel => '$wordCount words';

  /// Get formatted character count label
  String get characterLabel => '$characterCount chars';

  /// Get formatted speaking time label
  String get speakingTimeLabel {
    final minutes = estimatedSpeakingTime.inMinutes;
    final seconds = estimatedSpeakingTime.inSeconds.remainder(60);

    if (minutes > 0) {
      if (seconds > 0) {
        return '$min ${seconds}s talk';
      }
      return '$min min talk';
    } else if (seconds > 0) {
      return '<1 min talk';
    }
    return 'No talk time';
  }

  /// Speaking pace assessment
  String get paceAssessment {
    if (wordCount == 0) return 'Add notes';
    if (estimatedSpeakingTime.inMinutes > 5) return 'Very long';
    if (estimatedSpeakingTime.inMinutes > 2) return 'Good length';
    if (estimatedSpeakingTime.inMinutes > 1) return 'Brief';
    return 'Very brief';
  }

  @override
  String toString() {
    return 'SpeakerNotesMetrics(words: $wordCount, '
           'time: $speakingTimeLabel)';
  }
}

/// Presentation progress tracking
class PresentationProgress {
  final int currentSlide;
  final int totalSlides;
  final Duration elapsed;
  final Duration? target;

  const PresentationProgress({
    required this.currentSlide,
    required this.totalSlides,
    required this.elapsed,
    this.target,
  });

  /// Progress as percentage (0-100)
  double get percentage {
    if (totalSlides == 0) return 0.0;
    return ((currentSlide + 1) / totalSlides) * 100;
  }

  /// Slides completed
  int get completed => currentSlide + 1;

  /// Slides remaining
  int get remaining => totalSlides - currentSlide - 1;

  /// Whether presentation is complete
  bool get isComplete => currentSlide >= totalSlides - 1;

  /// Estimated time to finish based on current pace
  Duration get estimatedTimeToFinish {
    if (currentSlide < 0 || elapsed.inSeconds == 0) {
      return Duration.zero;
    }
    final avgTimePerSlide = elapsed.inSeconds / (currentSlide + 1);
    return Duration(seconds: (avgTimePerSlide * remaining).round());
  }

  /// Whether we're ahead, behind, or on schedule
  ScheduleStatus get scheduleStatus {
    if (target == null) return ScheduleStatus.unknown;

    final progressRatio = percentage / 100;
    final timeRatio = elapsed.inSeconds / target!.inSeconds;

    if (timeRatio > progressRatio * 1.1) {
      return ScheduleStatus.ahead;
    } else if (timeRatio < progressRatio * 0.9) {
      return ScheduleStatus.behind;
    }
    return ScheduleStatus.onTrack;
  }

  /// Status message
  String get statusMessage {
    switch (scheduleStatus) {
      case ScheduleStatus.ahead:
        return 'Ahead of schedule';
      case ScheduleStatus.behind:
        return 'Behind schedule';
      case ScheduleStatus.onTrack:
        return 'On track';
      case ScheduleStatus.unknown:
        return '';
    }
  }
}

enum ScheduleStatus { ahead, onTrack, behind, unknown }
