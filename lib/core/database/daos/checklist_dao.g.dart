// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_dao.dart';

// ignore_for_file: type=lint
mixin _$ChecklistDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChecklistsTable get checklists => attachedDatabase.checklists;
  $TasksTable get tasks => attachedDatabase.tasks;
  ChecklistDaoManager get managers => ChecklistDaoManager(this);
}

class ChecklistDaoManager {
  final _$ChecklistDaoMixin _db;
  ChecklistDaoManager(this._db);
  $$ChecklistsTableTableManager get checklists =>
      $$ChecklistsTableTableManager(_db.attachedDatabase, _db.checklists);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
}
