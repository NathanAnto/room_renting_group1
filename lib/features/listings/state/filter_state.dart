// lib/features/listings/state/filter_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/filter_options.dart';

// This Notifier holds and manages the state of the filters
class FilterOptionsNotifier extends StateNotifier<FilterOptions> {
  FilterOptionsNotifier() : super(FilterOptions());

  void updateFilters(FilterOptions newOptions) {
    state = newOptions;
  }
}

// This is the provider that our UI will interact with
final filterOptionsProvider =
    StateNotifierProvider<FilterOptionsNotifier, FilterOptions>(
      (ref) => FilterOptionsNotifier(),
    );