// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChecklistsTable get checklists => attachedDatabase.checklists;
  $TasksTable get tasks => attachedDatabase.tasks;
  $SubtasksTable get subtasks => attachedDatabase.subtasks;
  TaskDaoManager get managers => TaskDaoManager(this);
}

class TaskDaoManager {
  final _$TaskDaoMixin _db;
  TaskDaoManager(this._db);
  $$ChecklistsTableTableManager get checklists =>
      $$ChecklistsTableTableManager(_db.attachedDatabase, _db.checklists);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db.attachedDatabase, _db.subtasks);
}
