import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_suggestion_model.dart';
import '../services/app_api.dart';

// AI state
class AIState {
  final List<AISuggestionModel> suggestions;
  final bool isLoading;
  final String? error;
  final String? userId;
  final File? uploadedImage;

  const AIState({
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
    this.userId,
    this.uploadedImage,
  });

  AIState copyWith({
    List<AISuggestionModel>? suggestions,
    bool? isLoading,
    String? error,
    String? userId,
    File? uploadedImage,
  }) {
    return AIState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      userId: userId ?? this.userId,
      uploadedImage: uploadedImage ?? this.uploadedImage,
    );
  }
}

// AI notifier
class AINotifier extends StateNotifier<AIState> {
  AINotifier() : super(const AIState());

  Future<void> loadAllSuggestions() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final suggestions = await AppApi.getAISuggestions('default_user');
      state = state.copyWith(
        suggestions: suggestions,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadSuggestions(String userId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      userId: userId,
    );

    try {
      final suggestions = await AppApi.getAISuggestions(userId);
      state = state.copyWith(
        suggestions: suggestions,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> generateSuggestions(String userId, File imageFile) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      uploadedImage: imageFile,
    );

    try {
      final suggestions = await AppApi.generateAISuggestions(userId, imageFile);
      state = state.copyWith(
        suggestions: suggestions,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshSuggestions() async {
    if (state.userId != null) {
      await loadSuggestions(state.userId!);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearUploadedImage() {
    state = state.copyWith(uploadedImage: null);
  }

  // Get suggestions by type
  List<AISuggestionModel> getSuggestionsByType(SuggestionType type) {
    return state.suggestions.where((suggestion) => suggestion.type == type).toList();
  }

  // Get high confidence suggestions
  List<AISuggestionModel> get highConfidenceSuggestions {
    return state.suggestions.where((suggestion) => suggestion.isHighConfidence).toList();
  }

  // Get medium confidence suggestions
  List<AISuggestionModel> get mediumConfidenceSuggestions {
    return state.suggestions.where((suggestion) => suggestion.isMediumConfidence).toList();
  }

  // Get low confidence suggestions
  List<AISuggestionModel> get lowConfidenceSuggestions {
    return state.suggestions.where((suggestion) => suggestion.isLowConfidence).toList();
  }

  // Get booked suggestions
  List<AISuggestionModel> get bookedSuggestions {
    return state.suggestions.where((suggestion) => suggestion.isBooked).toList();
  }

  // Get unbooked suggestions
  List<AISuggestionModel> get unbookedSuggestions {
    return state.suggestions.where((suggestion) => !suggestion.isBooked).toList();
  }

  // Get recent suggestions (last 7 days)
  List<AISuggestionModel> get recentSuggestions {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return state.suggestions.where((suggestion) => 
      suggestion.createdAt.isAfter(weekAgo)
    ).toList();
  }

  // Get suggestions by confidence range
  List<AISuggestionModel> getSuggestionsByConfidenceRange(double minConfidence, double maxConfidence) {
    return state.suggestions.where((suggestion) => 
      suggestion.confidenceScore >= minConfidence && 
      suggestion.confidenceScore <= maxConfidence
    ).toList();
  }

  // Get most popular suggestion types
  Map<SuggestionType, int> get suggestionTypeCounts {
    final counts = <SuggestionType, int>{};
    for (final suggestion in state.suggestions) {
      counts[suggestion.type] = (counts[suggestion.type] ?? 0) + 1;
    }
    return counts;
  }

  // Get average confidence score
  double get averageConfidenceScore {
    if (state.suggestions.isEmpty) return 0.0;
    final total = state.suggestions.fold<double>(0.0, (sum, suggestion) => sum + suggestion.confidenceScore);
    return total / state.suggestions.length;
  }
}

// Providers
final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier();
});

final aiSuggestionsProvider = Provider<List<AISuggestionModel>>((ref) {
  return ref.watch(aiProvider).suggestions;
});

final highConfidenceSuggestionsProvider = Provider<List<AISuggestionModel>>((ref) {
  final notifier = ref.watch(aiProvider.notifier);
  return notifier.highConfidenceSuggestions;
});

final mediumConfidenceSuggestionsProvider = Provider<List<AISuggestionModel>>((ref) {
  final notifier = ref.watch(aiProvider.notifier);
  return notifier.mediumConfidenceSuggestions;
});

final lowConfidenceSuggestionsProvider = Provider<List<AISuggestionModel>>((ref) {
  final notifier = ref.watch(aiProvider.notifier);
  return notifier.lowConfidenceSuggestions;
});

final bookedSuggestionsProvider = Provider<List<AISuggestionModel>>((ref) {
  final notifier = ref.watch(aiProvider.notifier);
  return notifier.bookedSuggestions;
});

final unbookedSuggestionsProvider = Provider<List<AISuggestionModel>>((ref) {
  final notifier = ref.watch(aiProvider.notifier);
  return notifier.unbookedSuggestions;
});

final recentSuggestionsProvider = Provider<List<AISuggestionModel>>((ref) {
  final notifier = ref.watch(aiProvider.notifier);
  return notifier.recentSuggestions;
});

final suggestionsByTypeProvider = Provider.family<List<AISuggestionModel>, SuggestionType>((ref, type) {
  final notifier = ref.read(aiProvider.notifier);
  return notifier.getSuggestionsByType(type);
});

final suggestionsByConfidenceRangeProvider = Provider.family<List<AISuggestionModel>, (double, double)>((ref, range) {
  final notifier = ref.read(aiProvider.notifier);
  return notifier.getSuggestionsByConfidenceRange(range.$1, range.$2);
});

final suggestionTypeCountsProvider = Provider<Map<SuggestionType, int>>((ref) {
  final notifier = ref.read(aiProvider.notifier);
  return notifier.suggestionTypeCounts;
});

final averageConfidenceScoreProvider = Provider<double>((ref) {
  final notifier = ref.read(aiProvider.notifier);
  return notifier.averageConfidenceScore;
});
