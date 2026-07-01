// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Accessor for the [TaskDao], backed by the shared database.

@ProviderFor(taskDao)
final taskDaoProvider = TaskDaoProvider._();

/// Accessor for the [TaskDao], backed by the shared database.

final class TaskDaoProvider
    extends $FunctionalProvider<TaskDao, TaskDao, TaskDao>
    with $Provider<TaskDao> {
  /// Accessor for the [TaskDao], backed by the shared database.
  TaskDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskDaoHash();

  @$internal
  @override
  $ProviderElement<TaskDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaskDao create(Ref ref) {
    return taskDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskDao>(value),
    );
  }
}

String _$taskDaoHash() => r'8c9ea9c5de1a6c826d40e72a4355655a2a112e8e';

/// Reactive list of a checklist's tasks, each with its subtask progress.
///
/// Keyed by checklist id and `autoDispose` so a closed detail screen's stream
/// is torn down. Re-emits whenever the checklist's tasks or their subtasks
/// change.

@ProviderFor(tasksForChecklist)
final tasksForChecklistProvider = TasksForChecklistFamily._();

/// Reactive list of a checklist's tasks, each with its subtask progress.
///
/// Keyed by checklist id and `autoDispose` so a closed detail screen's stream
/// is torn down. Re-emits whenever the checklist's tasks or their subtasks
/// change.

final class TasksForChecklistProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TaskView>>,
          List<TaskView>,
          Stream<List<TaskView>>
        >
    with $FutureModifier<List<TaskView>>, $StreamProvider<List<TaskView>> {
  /// Reactive list of a checklist's tasks, each with its subtask progress.
  ///
  /// Keyed by checklist id and `autoDispose` so a closed detail screen's stream
  /// is torn down. Re-emits whenever the checklist's tasks or their subtasks
  /// change.
  TasksForChecklistProvider._({
    required TasksForChecklistFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'tasksForChecklistProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tasksForChecklistHash();

  @override
  String toString() {
    return r'tasksForChecklistProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TaskView>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TaskView>> create(Ref ref) {
    final argument = this.argument as int;
    return tasksForChecklist(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TasksForChecklistProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tasksForChecklistHash() => r'e21aa01a270bbef695c3ac30e5fb67a4b5ad0db3';

/// Reactive list of a checklist's tasks, each with its subtask progress.
///
/// Keyed by checklist id and `autoDispose` so a closed detail screen's stream
/// is torn down. Re-emits whenever the checklist's tasks or their subtasks
/// change.

final class TasksForChecklistFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TaskView>>, int> {
  TasksForChecklistFamily._()
    : super(
        retry: null,
        name: r'tasksForChecklistProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reactive list of a checklist's tasks, each with its subtask progress.
  ///
  /// Keyed by checklist id and `autoDispose` so a closed detail screen's stream
  /// is torn down. Re-emits whenever the checklist's tasks or their subtasks
  /// change.

  TasksForChecklistProvider call(int checklistId) =>
      TasksForChecklistProvider._(argument: checklistId, from: this);

  @override
  String toString() => r'tasksForChecklistProvider';
}

/// Write commands for tasks.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: rejected input and caught exceptions become [Err]; programming
/// bugs (`Error`) propagate.

@ProviderFor(TaskController)
final taskControllerProvider = TaskControllerProvider._();

/// Write commands for tasks.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: rejected input and caught exceptions become [Err]; programming
/// bugs (`Error`) propagate.
final class TaskControllerProvider
    extends $NotifierProvider<TaskController, void> {
  /// Write commands for tasks.
  ///
  /// Holds no state of its own — the database is the state. Each command returns
  /// a [Result]: rejected input and caught exceptions become [Err]; programming
  /// bugs (`Error`) propagate.
  TaskControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskControllerHash();

  @$internal
  @override
  TaskController create() => TaskController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$taskControllerHash() => r'df3773bd036a461d622bdfaea04ee057c815d76d';

/// Write commands for tasks.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: rejected input and caught exceptions become [Err]; programming
/// bugs (`Error`) propagate.

abstract class _$TaskController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
