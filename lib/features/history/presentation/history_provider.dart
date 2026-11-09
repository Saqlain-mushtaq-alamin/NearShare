import 'dart:async';

import 'package:collection/collection.dart' show DeepCollectionEquality;
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/history_providers.dart';
import '../data/history_repository.dart';
import '../domain/transfer_record.dart';

/// Direction filter offered by the history chips.
enum HistoryFilter {
  all,
  sent,
  received;

  TransferDirection? get directionFilter {
    switch (this) {
      case HistoryFilter.all:
        return null;
      case HistoryFilter.sent:
        return TransferDirection.sending;
      case HistoryFilter.received:
        return TransferDirection.receiving;
    }
  }

  String get label {
    switch (this) {
      case HistoryFilter.all:
        return 'All';
      case HistoryFilter.sent:
        return 'Sent';
      case HistoryFilter.received:
        return 'Received';
    }
  }
}

/// Everything the history list is narrowed by.
@immutable
class HistoryQuery {
  final HistoryFilter direction;
  final String search;

  const HistoryQuery({this.direction = HistoryFilter.all, this.search = ''});

  bool get hasSearch => search.trim().isNotEmpty;

  HistoryQuery copyWith({HistoryFilter? direction, String? search}) {
    return HistoryQuery(
      direction: direction ?? this.direction,
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryQuery &&
          runtimeType == other.runtimeType &&
          direction == other.direction &&
          search == other.search;

  @override
  int get hashCode => Object.hash(direction, search);
}

@immutable
class HistoryState {
  final List<TransferRecord> records;
  final HistoryQuery query;
  final bool isLoading;
  final String? errorMessage;

  const HistoryState({
    this.records = const [],
    this.query = const HistoryQuery(),
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isEmpty => records.isEmpty && !isLoading;

  HistoryState copyWith({
    List<TransferRecord>? records,
    HistoryQuery? query,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HistoryState(
      records: records ?? this.records,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryState &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(records, other.records) &&
          query == other.query &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        const DeepCollectionEquality().hash(records),
        query,
        isLoading,
        errorMessage,
      );
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider));
});

/// Watches [HistoryRepository] and re-queries whenever the filter changes.
class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryRepository _repository;
  StreamSubscription<List<TransferRecord>>? _subscription;

  HistoryNotifier(this._repository, {HistoryQuery query = const HistoryQuery()})
      : super(HistoryState(query: query)) {
    _subscribe();
  }

  /// Rebuilds the repository stream from the current query.
  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository
        .getAllRecords(
          filter: state.query.direction.directionFilter,
          search: state.query.hasSearch ? state.query.search : null,
        )
        .listen(
          _onRecords,
          onError: (Object error) {
            if (!mounted) return;
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'Failed to load history: $error',
            );
          },
        );
  }

  void _onRecords(List<TransferRecord> records) {
    if (!mounted) return;
    state = state.copyWith(records: records, isLoading: false);
  }

  void setDirection(HistoryFilter filter) {
    if (state.query.direction == filter) return;
    state = state.copyWith(
      query: state.query.copyWith(direction: filter),
      isLoading: true,
    );
    _subscribe();
  }

  void setSearch(String value) {
    final next = value.trimRight();
    if (state.query.search == next) return;
    state = state.copyWith(
      query: state.query.copyWith(search: next),
      isLoading: true,
    );
    _subscribe();
  }

  void clearSearch() => setSearch('');

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    _subscribe();
  }

  Future<void> deleteRecord(String transferId) async {
    try {
      await _repository.deleteRecord(transferId);
      _subscribe();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(errorMessage: 'Failed to delete: $e');
      }
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await _repository.clearAllHistory();
      _subscribe();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(errorMessage: 'Failed to clear history: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Loads a single history entry for the detail screen.
final historyRecordProvider =
    FutureProvider.family<TransferRecord?, String>((ref, transferId) {
  return ref.watch(historyRepositoryProvider).getRecordById(transferId);
});
