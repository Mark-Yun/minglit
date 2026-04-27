// ignore_for_file: must_be_immutable
import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mocks.dart';

/// Creates a [MockSupabaseClient] wired with auth and functions clients.
MockSupabaseClient createMockSupabase({User? currentUser}) {
  final client = MockSupabaseClient();
  final auth = MockGoTrueClient();
  final functions = MockFunctionsClient();

  when(() => client.auth).thenReturn(auth);
  when(() => client.functions).thenReturn(functions);
  when(() => auth.currentUser).thenReturn(currentUser);

  return client;
}

/// Configures `client.from(tableName)` to return a [FakeTableBuilder].
///
/// Usage:
/// ```dart
/// final client = createMockSupabase();
/// mockTable(client, 'tickets', selectData: [...]);
/// ```
FakeTableBuilder mockTable(
  MockSupabaseClient client,
  String tableName, {
  List<Map<String, dynamic>> selectData = const [],
  Map<String, dynamic>? singleData,
  Map<String, dynamic>? maybeSingleData,
  Map<String, dynamic>? insertReturnData,
  List<Map<String, dynamic>>? upsertReturnData,
  int countValue = 0,
  Exception? shouldThrow,
}) {
  final builder = FakeTableBuilder(
    selectData: selectData,
    singleData: singleData ?? (selectData.isNotEmpty ? selectData.first : {}),
    maybeSingleData:
        maybeSingleData ?? (selectData.isNotEmpty ? selectData.first : null),
    insertReturnData: insertReturnData,
    upsertReturnData: upsertReturnData,
    countValue: countValue,
    shouldThrow: shouldThrow,
  );
  // SupabaseQueryBuilder extends PostgrestBuilder which implements Future,
  // so mocktail requires thenAnswer instead of thenReturn.
  when(() => client.from(tableName)).thenAnswer((_) => builder);
  return builder;
}

class RecordedFilterOperation {
  const RecordedFilterOperation({
    required this.method,
    required this.column,
    required this.value,
  });

  final String method;
  final String column;
  final Object? value;
}

/// A fake [SupabaseQueryBuilder] that captures table operations and returns
/// preconfigured data. Supports the full builder chain without needing
/// individual method mocks.
class FakeTableBuilder extends Fake implements SupabaseQueryBuilder {
  FakeTableBuilder({
    this.selectData = const [],
    this.singleData = const {},
    this.maybeSingleData,
    this.insertReturnData,
    this.upsertReturnData,
    this.countValue = 0,
    this.shouldThrow,
  });

  final List<Map<String, dynamic>> selectData;
  final Map<String, dynamic> singleData;
  final Map<String, dynamic>? maybeSingleData;
  final Map<String, dynamic>? insertReturnData;
  final List<Map<String, dynamic>>? upsertReturnData;
  final int countValue;
  final Exception? shouldThrow;
  final List<RecordedFilterOperation> recordedFilters = [];
  // Tracks the columns string passed to .select() — used in regression tests
  // to assert that specific columns (e.g. 'event_at') are queried.
  String? lastSelectColumns;
  // Tracks column names passed to .order() — used in regression tests.
  final List<String> recordedOrderColumns = [];

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    if (shouldThrow != null) throw shouldThrow!;
    lastSelectColumns = columns;
    return _FakeFilterBuilder(
      selectData: selectData,
      singleData: singleData,
      maybeSingleData: maybeSingleData,
      countValue: countValue,
      recordedFilters: recordedFilters,
      recordedOrderColumns: recordedOrderColumns,
    );
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    if (shouldThrow != null) throw shouldThrow!;
    return _FakeFilterBuilder(
      selectData: insertReturnData != null ? [insertReturnData!] : selectData,
      singleData: insertReturnData ?? singleData,
      maybeSingleData: insertReturnData ?? maybeSingleData,
      countValue: countValue,
      recordedFilters: recordedFilters,
      recordedOrderColumns: recordedOrderColumns,
    );
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(
    Map<dynamic, dynamic> values, {
    bool defaultToNull = false,
  }) {
    if (shouldThrow != null) throw shouldThrow!;
    return _FakeFilterBuilder(
      selectData: selectData,
      singleData: singleData,
      maybeSingleData: maybeSingleData,
      countValue: countValue,
      recordedFilters: recordedFilters,
      recordedOrderColumns: recordedOrderColumns,
    );
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> delete() {
    if (shouldThrow != null) throw shouldThrow!;
    return _FakeFilterBuilder(
      selectData: selectData,
      singleData: singleData,
      maybeSingleData: maybeSingleData,
      countValue: countValue,
      recordedFilters: recordedFilters,
      recordedOrderColumns: recordedOrderColumns,
    );
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
    CountOption? count,
  }) {
    if (shouldThrow != null) throw shouldThrow!;
    final data = upsertReturnData ?? selectData;
    return _FakeFilterBuilder(
      selectData: data,
      singleData: data.isNotEmpty ? data.first : singleData,
      maybeSingleData: data.isNotEmpty ? data.first : null,
      countValue: countValue,
      recordedFilters: recordedFilters,
      recordedOrderColumns: recordedOrderColumns,
    );
  }
}

/// A fake filter builder that supports the full Supabase builder chain.
class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  _FakeFilterBuilder({
    required this.selectData,
    required this.singleData,
    required this.recordedFilters,
    required this.recordedOrderColumns,
    this.maybeSingleData,
    this.countValue = 0,
  });

  final List<Map<String, dynamic>> selectData;
  final Map<String, dynamic> singleData;
  final Map<String, dynamic>? maybeSingleData;
  final int countValue;
  final List<RecordedFilterOperation> recordedFilters;
  final List<String> recordedOrderColumns;

  // --- Chaining methods (all return this) ---

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    recordedFilters.add(
      RecordedFilterOperation(method: 'eq', column: column, value: value),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> neq(
    String column,
    Object value,
  ) {
    recordedFilters.add(
      RecordedFilterOperation(method: 'neq', column: column, value: value),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> not(
    String column,
    String operator,
    Object? value,
  ) {
    recordedFilters.add(
      RecordedFilterOperation(
        method: 'not',
        column: column,
        value: '$operator:$value',
      ),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> match(
    Map<String, Object> query,
  ) {
    recordedFilters.add(
      RecordedFilterOperation(method: 'match', column: '*', value: query),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> inFilter(
    String column,
    List<dynamic> values,
  ) {
    recordedFilters.add(
      RecordedFilterOperation(
        method: 'inFilter',
        column: column,
        value: List<dynamic>.from(values),
      ),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> gte(
    String column,
    Object value,
  ) {
    recordedFilters.add(
      RecordedFilterOperation(method: 'gte', column: column, value: value),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> lte(
    String column,
    Object value,
  ) {
    recordedFilters.add(
      RecordedFilterOperation(method: 'lte', column: column, value: value),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> gt(
    String column,
    Object value,
  ) {
    recordedFilters.add(
      RecordedFilterOperation(method: 'gt', column: column, value: value),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> lt(
    String column,
    Object value,
  ) {
    recordedFilters.add(
      RecordedFilterOperation(method: 'lt', column: column, value: value),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> or(
    String filters, {
    String? referencedTable,
  }) {
    recordedFilters.add(
      RecordedFilterOperation(method: 'or', column: '*', value: filters),
    );
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> ilike(
    String column,
    String pattern,
  ) => this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> filter(
    String column,
    String operator,
    Object? value,
  ) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    recordedOrderColumns.add(column);
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> limit(
    int count, {
    String? referencedTable,
  }) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> range(
    int from,
    int to, {
    String? referencedTable,
  }) => this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return this;
  }

  // --- Terminal operations ---

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      _FakeTerminalBuilder<Map<String, dynamic>>(singleData);

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      _FakeTerminalBuilder<Map<String, dynamic>?>(maybeSingleData);

  @override
  ResponsePostgrestBuilder<
    PostgrestResponse<List<Map<String, dynamic>>>,
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>
  >
  count([CountOption option = CountOption.exact]) =>
      _FakeCountBuilder(selectData, countValue);

  // Awaiting a filter builder resolves to the list data
  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    return Future<List<Map<String, dynamic>>>.value(
      selectData,
    ).then(onValue, onError: onError);
  }
}

/// Generic terminal builder for `.single()` and `.maybeSingle()`.
class _FakeTerminalBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  _FakeTerminalBuilder(this._data);
  final T _data;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(_data).then(onValue, onError: onError);
  }
}

/// Fake count response builder.
class _FakeCountBuilder extends Fake
    implements
        ResponsePostgrestBuilder<
          PostgrestResponse<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          List<Map<String, dynamic>>
        > {
  _FakeCountBuilder(this._data, this._count);
  final List<Map<String, dynamic>> _data;
  final int _count;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestResponse<List<Map<String, dynamic>>>)
    onValue, {
    Function? onError,
  }) {
    return Future.value(
      PostgrestResponse(data: _data, count: _count),
    ).then(onValue, onError: onError);
  }
}

/// A fake [PostgrestFilterBuilder] for RPC responses.
///
/// Does NOT extend [Fake] (mocktail) to avoid corrupting mocktail state
/// when returned from `thenAnswer`.
///
/// Usage:
/// ```dart
/// when(() => client.rpc<String>('fn', params: any(named: 'params')))
///     .thenAnswer((_) => FakeRpcBuilder('result'));
/// ```
class FakeRpcBuilder<T> implements PostgrestFilterBuilder<T> {
  /// Creates a [FakeRpcBuilder] that resolves to [_data].
  FakeRpcBuilder(this._data);
  final T _data;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(_data).then(onValue, onError: onError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}
