// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KeyValuesTable extends KeyValues with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(Insertable<KeyValue> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const KeyValue({required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value), updatedAt: Value(updatedAt));
  }

  factory KeyValue.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  KeyValue copyWith({String? key, String? value, DateTime? updatedAt}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value, updatedAt: updatedAt ?? this.updatedAt);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value && other.updatedAt == this.updatedAt);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SrsCardStatesTable extends SrsCardStates with TableInfo<$SrsCardStatesTable, SrsCardState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsCardStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _flashcardIdMeta = const VerificationMeta('flashcardId');
  @override
  late final GeneratedColumn<String> flashcardId = GeneratedColumn<String>(
    'flashcard_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easeMeta = const VerificationMeta('ease');
  @override
  late final GeneratedColumn<double> ease = GeneratedColumn<double>(
    'ease',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta('lastReviewedAt');
  @override
  late final GeneratedColumn<int> lastReviewedAt = GeneratedColumn<int>(
    'last_reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    flashcardId,
    state,
    step,
    dueAt,
    intervalDays,
    ease,
    reps,
    lapses,
    lastReviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_card_states';
  @override
  VerificationContext validateIntegrity(Insertable<SrsCardState> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('flashcard_id')) {
      context.handle(_flashcardIdMeta, flashcardId.isAcceptableOrUnknown(data['flashcard_id']!, _flashcardIdMeta));
    } else if (isInserting) {
      context.missing(_flashcardIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(_stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('step')) {
      context.handle(_stepMeta, step.isAcceptableOrUnknown(data['step']!, _stepMeta));
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(_dueAtMeta, dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta));
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(_intervalDaysMeta, intervalDays.isAcceptableOrUnknown(data['interval_days']!, _intervalDaysMeta));
    } else if (isInserting) {
      context.missing(_intervalDaysMeta);
    }
    if (data.containsKey('ease')) {
      context.handle(_easeMeta, ease.isAcceptableOrUnknown(data['ease']!, _easeMeta));
    } else if (isInserting) {
      context.missing(_easeMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(_repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('lapses')) {
      context.handle(_lapsesMeta, lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta));
    } else if (isInserting) {
      context.missing(_lapsesMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(data['last_reviewed_at']!, _lastReviewedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {flashcardId};
  @override
  SrsCardState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsCardState(
      flashcardId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}flashcard_id'])!,
      state: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      step: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}step'])!,
      dueAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}due_at'])!,
      intervalDays: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}interval_days'])!,
      ease: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}ease'])!,
      reps: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      lapses: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}lapses'])!,
      lastReviewedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}last_reviewed_at']),
    );
  }

  @override
  $SrsCardStatesTable createAlias(String alias) {
    return $SrsCardStatesTable(attachedDatabase, alias);
  }
}

class SrsCardState extends DataClass implements Insertable<SrsCardState> {
  final String flashcardId;
  final String state;
  final int step;
  final int dueAt;
  final int intervalDays;
  final double ease;
  final int reps;
  final int lapses;
  final int? lastReviewedAt;
  const SrsCardState({
    required this.flashcardId,
    required this.state,
    required this.step,
    required this.dueAt,
    required this.intervalDays,
    required this.ease,
    required this.reps,
    required this.lapses,
    this.lastReviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['flashcard_id'] = Variable<String>(flashcardId);
    map['state'] = Variable<String>(state);
    map['step'] = Variable<int>(step);
    map['due_at'] = Variable<int>(dueAt);
    map['interval_days'] = Variable<int>(intervalDays);
    map['ease'] = Variable<double>(ease);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt);
    }
    return map;
  }

  SrsCardStatesCompanion toCompanion(bool nullToAbsent) {
    return SrsCardStatesCompanion(
      flashcardId: Value(flashcardId),
      state: Value(state),
      step: Value(step),
      dueAt: Value(dueAt),
      intervalDays: Value(intervalDays),
      ease: Value(ease),
      reps: Value(reps),
      lapses: Value(lapses),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent ? const Value.absent() : Value(lastReviewedAt),
    );
  }

  factory SrsCardState.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsCardState(
      flashcardId: serializer.fromJson<String>(json['flashcardId']),
      state: serializer.fromJson<String>(json['state']),
      step: serializer.fromJson<int>(json['step']),
      dueAt: serializer.fromJson<int>(json['dueAt']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      ease: serializer.fromJson<double>(json['ease']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      lastReviewedAt: serializer.fromJson<int?>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'flashcardId': serializer.toJson<String>(flashcardId),
      'state': serializer.toJson<String>(state),
      'step': serializer.toJson<int>(step),
      'dueAt': serializer.toJson<int>(dueAt),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'ease': serializer.toJson<double>(ease),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'lastReviewedAt': serializer.toJson<int?>(lastReviewedAt),
    };
  }

  SrsCardState copyWith({
    String? flashcardId,
    String? state,
    int? step,
    int? dueAt,
    int? intervalDays,
    double? ease,
    int? reps,
    int? lapses,
    Value<int?> lastReviewedAt = const Value.absent(),
  }) => SrsCardState(
    flashcardId: flashcardId ?? this.flashcardId,
    state: state ?? this.state,
    step: step ?? this.step,
    dueAt: dueAt ?? this.dueAt,
    intervalDays: intervalDays ?? this.intervalDays,
    ease: ease ?? this.ease,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    lastReviewedAt: lastReviewedAt.present ? lastReviewedAt.value : this.lastReviewedAt,
  );
  SrsCardState copyWithCompanion(SrsCardStatesCompanion data) {
    return SrsCardState(
      flashcardId: data.flashcardId.present ? data.flashcardId.value : this.flashcardId,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      intervalDays: data.intervalDays.present ? data.intervalDays.value : this.intervalDays,
      ease: data.ease.present ? data.ease.value : this.ease,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      lastReviewedAt: data.lastReviewedAt.present ? data.lastReviewedAt.value : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsCardState(')
          ..write('flashcardId: $flashcardId, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('ease: $ease, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(flashcardId, state, step, dueAt, intervalDays, ease, reps, lapses, lastReviewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsCardState &&
          other.flashcardId == this.flashcardId &&
          other.state == this.state &&
          other.step == this.step &&
          other.dueAt == this.dueAt &&
          other.intervalDays == this.intervalDays &&
          other.ease == this.ease &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class SrsCardStatesCompanion extends UpdateCompanion<SrsCardState> {
  final Value<String> flashcardId;
  final Value<String> state;
  final Value<int> step;
  final Value<int> dueAt;
  final Value<int> intervalDays;
  final Value<double> ease;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int?> lastReviewedAt;
  final Value<int> rowid;
  const SrsCardStatesCompanion({
    this.flashcardId = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.ease = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SrsCardStatesCompanion.insert({
    required String flashcardId,
    required String state,
    required int step,
    required int dueAt,
    required int intervalDays,
    required double ease,
    required int reps,
    required int lapses,
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : flashcardId = Value(flashcardId),
       state = Value(state),
       step = Value(step),
       dueAt = Value(dueAt),
       intervalDays = Value(intervalDays),
       ease = Value(ease),
       reps = Value(reps),
       lapses = Value(lapses);
  static Insertable<SrsCardState> custom({
    Expression<String>? flashcardId,
    Expression<String>? state,
    Expression<int>? step,
    Expression<int>? dueAt,
    Expression<int>? intervalDays,
    Expression<double>? ease,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? lastReviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (flashcardId != null) 'flashcard_id': flashcardId,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (dueAt != null) 'due_at': dueAt,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (ease != null) 'ease': ease,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SrsCardStatesCompanion copyWith({
    Value<String>? flashcardId,
    Value<String>? state,
    Value<int>? step,
    Value<int>? dueAt,
    Value<int>? intervalDays,
    Value<double>? ease,
    Value<int>? reps,
    Value<int>? lapses,
    Value<int?>? lastReviewedAt,
    Value<int>? rowid,
  }) {
    return SrsCardStatesCompanion(
      flashcardId: flashcardId ?? this.flashcardId,
      state: state ?? this.state,
      step: step ?? this.step,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      ease: ease ?? this.ease,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (flashcardId.present) {
      map['flashcard_id'] = Variable<String>(flashcardId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (ease.present) {
      map['ease'] = Variable<double>(ease.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsCardStatesCompanion(')
          ..write('flashcardId: $flashcardId, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('ease: $ease, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SrsReviewLogsTable extends SrsReviewLogs with TableInfo<$SrsReviewLogsTable, SrsReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flashcardIdMeta = const VerificationMeta('flashcardId');
  @override
  late final GeneratedColumn<String> flashcardId = GeneratedColumn<String>(
    'flashcard_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beforeMeta = const VerificationMeta('before');
  @override
  late final GeneratedColumn<String> before = GeneratedColumn<String>(
    'before',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _afterMeta = const VerificationMeta('after');
  @override
  late final GeneratedColumn<String> after = GeneratedColumn<String>(
    'after',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta('reviewedAt');
  @override
  late final GeneratedColumn<int> reviewedAt = GeneratedColumn<int>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _undoneMeta = const VerificationMeta('undone');
  @override
  late final GeneratedColumn<bool> undone = GeneratedColumn<bool>(
    'undone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("undone" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    flashcardId,
    rating,
    before,
    after,
    reviewedAt,
    durationMs,
    undone,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_review_logs';
  @override
  VerificationContext validateIntegrity(Insertable<SrsReviewLog> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('flashcard_id')) {
      context.handle(_flashcardIdMeta, flashcardId.isAcceptableOrUnknown(data['flashcard_id']!, _flashcardIdMeta));
    } else if (isInserting) {
      context.missing(_flashcardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta, rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('before')) {
      context.handle(_beforeMeta, before.isAcceptableOrUnknown(data['before']!, _beforeMeta));
    } else if (isInserting) {
      context.missing(_beforeMeta);
    }
    if (data.containsKey('after')) {
      context.handle(_afterMeta, after.isAcceptableOrUnknown(data['after']!, _afterMeta));
    } else if (isInserting) {
      context.missing(_afterMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(_reviewedAtMeta, reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta));
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(_durationMsMeta, durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('undone')) {
      context.handle(_undoneMeta, undone.isAcceptableOrUnknown(data['undone']!, _undoneMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta, synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SrsReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsReviewLog(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      flashcardId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}flashcard_id'])!,
      rating: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}rating'])!,
      before: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}before'])!,
      after: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}after'])!,
      reviewedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reviewed_at'])!,
      durationMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      undone: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}undone'])!,
      synced: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $SrsReviewLogsTable createAlias(String alias) {
    return $SrsReviewLogsTable(attachedDatabase, alias);
  }
}

class SrsReviewLog extends DataClass implements Insertable<SrsReviewLog> {
  final String id;
  final String flashcardId;
  final String rating;
  final String before;
  final String after;
  final int reviewedAt;
  final int? durationMs;
  final bool undone;
  final bool synced;
  const SrsReviewLog({
    required this.id,
    required this.flashcardId,
    required this.rating,
    required this.before,
    required this.after,
    required this.reviewedAt,
    this.durationMs,
    required this.undone,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['flashcard_id'] = Variable<String>(flashcardId);
    map['rating'] = Variable<String>(rating);
    map['before'] = Variable<String>(before);
    map['after'] = Variable<String>(after);
    map['reviewed_at'] = Variable<int>(reviewedAt);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['undone'] = Variable<bool>(undone);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  SrsReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return SrsReviewLogsCompanion(
      id: Value(id),
      flashcardId: Value(flashcardId),
      rating: Value(rating),
      before: Value(before),
      after: Value(after),
      reviewedAt: Value(reviewedAt),
      durationMs: durationMs == null && nullToAbsent ? const Value.absent() : Value(durationMs),
      undone: Value(undone),
      synced: Value(synced),
    );
  }

  factory SrsReviewLog.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsReviewLog(
      id: serializer.fromJson<String>(json['id']),
      flashcardId: serializer.fromJson<String>(json['flashcardId']),
      rating: serializer.fromJson<String>(json['rating']),
      before: serializer.fromJson<String>(json['before']),
      after: serializer.fromJson<String>(json['after']),
      reviewedAt: serializer.fromJson<int>(json['reviewedAt']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      undone: serializer.fromJson<bool>(json['undone']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'flashcardId': serializer.toJson<String>(flashcardId),
      'rating': serializer.toJson<String>(rating),
      'before': serializer.toJson<String>(before),
      'after': serializer.toJson<String>(after),
      'reviewedAt': serializer.toJson<int>(reviewedAt),
      'durationMs': serializer.toJson<int?>(durationMs),
      'undone': serializer.toJson<bool>(undone),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  SrsReviewLog copyWith({
    String? id,
    String? flashcardId,
    String? rating,
    String? before,
    String? after,
    int? reviewedAt,
    Value<int?> durationMs = const Value.absent(),
    bool? undone,
    bool? synced,
  }) => SrsReviewLog(
    id: id ?? this.id,
    flashcardId: flashcardId ?? this.flashcardId,
    rating: rating ?? this.rating,
    before: before ?? this.before,
    after: after ?? this.after,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    undone: undone ?? this.undone,
    synced: synced ?? this.synced,
  );
  SrsReviewLog copyWithCompanion(SrsReviewLogsCompanion data) {
    return SrsReviewLog(
      id: data.id.present ? data.id.value : this.id,
      flashcardId: data.flashcardId.present ? data.flashcardId.value : this.flashcardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      before: data.before.present ? data.before.value : this.before,
      after: data.after.present ? data.after.value : this.after,
      reviewedAt: data.reviewedAt.present ? data.reviewedAt.value : this.reviewedAt,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
      undone: data.undone.present ? data.undone.value : this.undone,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsReviewLog(')
          ..write('id: $id, ')
          ..write('flashcardId: $flashcardId, ')
          ..write('rating: $rating, ')
          ..write('before: $before, ')
          ..write('after: $after, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('undone: $undone, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, flashcardId, rating, before, after, reviewedAt, durationMs, undone, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsReviewLog &&
          other.id == this.id &&
          other.flashcardId == this.flashcardId &&
          other.rating == this.rating &&
          other.before == this.before &&
          other.after == this.after &&
          other.reviewedAt == this.reviewedAt &&
          other.durationMs == this.durationMs &&
          other.undone == this.undone &&
          other.synced == this.synced);
}

class SrsReviewLogsCompanion extends UpdateCompanion<SrsReviewLog> {
  final Value<String> id;
  final Value<String> flashcardId;
  final Value<String> rating;
  final Value<String> before;
  final Value<String> after;
  final Value<int> reviewedAt;
  final Value<int?> durationMs;
  final Value<bool> undone;
  final Value<bool> synced;
  final Value<int> rowid;
  const SrsReviewLogsCompanion({
    this.id = const Value.absent(),
    this.flashcardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.before = const Value.absent(),
    this.after = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.undone = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SrsReviewLogsCompanion.insert({
    required String id,
    required String flashcardId,
    required String rating,
    required String before,
    required String after,
    required int reviewedAt,
    this.durationMs = const Value.absent(),
    this.undone = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       flashcardId = Value(flashcardId),
       rating = Value(rating),
       before = Value(before),
       after = Value(after),
       reviewedAt = Value(reviewedAt);
  static Insertable<SrsReviewLog> custom({
    Expression<String>? id,
    Expression<String>? flashcardId,
    Expression<String>? rating,
    Expression<String>? before,
    Expression<String>? after,
    Expression<int>? reviewedAt,
    Expression<int>? durationMs,
    Expression<bool>? undone,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (flashcardId != null) 'flashcard_id': flashcardId,
      if (rating != null) 'rating': rating,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (undone != null) 'undone': undone,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SrsReviewLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? flashcardId,
    Value<String>? rating,
    Value<String>? before,
    Value<String>? after,
    Value<int>? reviewedAt,
    Value<int?>? durationMs,
    Value<bool>? undone,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return SrsReviewLogsCompanion(
      id: id ?? this.id,
      flashcardId: flashcardId ?? this.flashcardId,
      rating: rating ?? this.rating,
      before: before ?? this.before,
      after: after ?? this.after,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      durationMs: durationMs ?? this.durationMs,
      undone: undone ?? this.undone,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (flashcardId.present) {
      map['flashcard_id'] = Variable<String>(flashcardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (before.present) {
      map['before'] = Variable<String>(before.value);
    }
    if (after.present) {
      map['after'] = Variable<String>(after.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<int>(reviewedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (undone.present) {
      map['undone'] = Variable<bool>(undone.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('flashcardId: $flashcardId, ')
          ..write('rating: $rating, ')
          ..write('before: $before, ')
          ..write('after: $after, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('undone: $undone, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExamDraftsTable extends ExamDrafts with TableInfo<$ExamDraftsTable, ExamDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptIdMeta = const VerificationMeta('attemptId');
  @override
  late final GeneratedColumn<String> attemptId = GeneratedColumn<String>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta('attempt');
  @override
  late final GeneratedColumn<String> attempt = GeneratedColumn<String>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _submitPendingMeta = const VerificationMeta('submitPending');
  @override
  late final GeneratedColumn<bool> submitPending = GeneratedColumn<bool>(
    'submit_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("submit_pending" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timeSpentMsMeta = const VerificationMeta('timeSpentMs');
  @override
  late final GeneratedColumn<int> timeSpentMs = GeneratedColumn<int>(
    'time_spent_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [attemptId, attempt, submitPending, timeSpentMs, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exam_drafts';
  @override
  VerificationContext validateIntegrity(Insertable<ExamDraftRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_id')) {
      context.handle(_attemptIdMeta, attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta));
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(_attemptMeta, attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta));
    } else if (isInserting) {
      context.missing(_attemptMeta);
    }
    if (data.containsKey('submit_pending')) {
      context.handle(
        _submitPendingMeta,
        submitPending.isAcceptableOrUnknown(data['submit_pending']!, _submitPendingMeta),
      );
    }
    if (data.containsKey('time_spent_ms')) {
      context.handle(_timeSpentMsMeta, timeSpentMs.isAcceptableOrUnknown(data['time_spent_ms']!, _timeSpentMsMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attemptId};
  @override
  ExamDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamDraftRow(
      attemptId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}attempt_id'])!,
      attempt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}attempt'])!,
      submitPending: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}submit_pending'])!,
      timeSpentMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}time_spent_ms']),
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ExamDraftsTable createAlias(String alias) {
    return $ExamDraftsTable(attachedDatabase, alias);
  }
}

class ExamDraftRow extends DataClass implements Insertable<ExamDraftRow> {
  final String attemptId;
  final String attempt;
  final bool submitPending;
  final int? timeSpentMs;
  final int updatedAt;
  const ExamDraftRow({
    required this.attemptId,
    required this.attempt,
    required this.submitPending,
    this.timeSpentMs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attempt_id'] = Variable<String>(attemptId);
    map['attempt'] = Variable<String>(attempt);
    map['submit_pending'] = Variable<bool>(submitPending);
    if (!nullToAbsent || timeSpentMs != null) {
      map['time_spent_ms'] = Variable<int>(timeSpentMs);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ExamDraftsCompanion toCompanion(bool nullToAbsent) {
    return ExamDraftsCompanion(
      attemptId: Value(attemptId),
      attempt: Value(attempt),
      submitPending: Value(submitPending),
      timeSpentMs: timeSpentMs == null && nullToAbsent ? const Value.absent() : Value(timeSpentMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExamDraftRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamDraftRow(
      attemptId: serializer.fromJson<String>(json['attemptId']),
      attempt: serializer.fromJson<String>(json['attempt']),
      submitPending: serializer.fromJson<bool>(json['submitPending']),
      timeSpentMs: serializer.fromJson<int?>(json['timeSpentMs']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attemptId': serializer.toJson<String>(attemptId),
      'attempt': serializer.toJson<String>(attempt),
      'submitPending': serializer.toJson<bool>(submitPending),
      'timeSpentMs': serializer.toJson<int?>(timeSpentMs),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ExamDraftRow copyWith({
    String? attemptId,
    String? attempt,
    bool? submitPending,
    Value<int?> timeSpentMs = const Value.absent(),
    int? updatedAt,
  }) => ExamDraftRow(
    attemptId: attemptId ?? this.attemptId,
    attempt: attempt ?? this.attempt,
    submitPending: submitPending ?? this.submitPending,
    timeSpentMs: timeSpentMs.present ? timeSpentMs.value : this.timeSpentMs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExamDraftRow copyWithCompanion(ExamDraftsCompanion data) {
    return ExamDraftRow(
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      submitPending: data.submitPending.present ? data.submitPending.value : this.submitPending,
      timeSpentMs: data.timeSpentMs.present ? data.timeSpentMs.value : this.timeSpentMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamDraftRow(')
          ..write('attemptId: $attemptId, ')
          ..write('attempt: $attempt, ')
          ..write('submitPending: $submitPending, ')
          ..write('timeSpentMs: $timeSpentMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(attemptId, attempt, submitPending, timeSpentMs, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamDraftRow &&
          other.attemptId == this.attemptId &&
          other.attempt == this.attempt &&
          other.submitPending == this.submitPending &&
          other.timeSpentMs == this.timeSpentMs &&
          other.updatedAt == this.updatedAt);
}

class ExamDraftsCompanion extends UpdateCompanion<ExamDraftRow> {
  final Value<String> attemptId;
  final Value<String> attempt;
  final Value<bool> submitPending;
  final Value<int?> timeSpentMs;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ExamDraftsCompanion({
    this.attemptId = const Value.absent(),
    this.attempt = const Value.absent(),
    this.submitPending = const Value.absent(),
    this.timeSpentMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExamDraftsCompanion.insert({
    required String attemptId,
    required String attempt,
    this.submitPending = const Value.absent(),
    this.timeSpentMs = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : attemptId = Value(attemptId),
       attempt = Value(attempt),
       updatedAt = Value(updatedAt);
  static Insertable<ExamDraftRow> custom({
    Expression<String>? attemptId,
    Expression<String>? attempt,
    Expression<bool>? submitPending,
    Expression<int>? timeSpentMs,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attemptId != null) 'attempt_id': attemptId,
      if (attempt != null) 'attempt': attempt,
      if (submitPending != null) 'submit_pending': submitPending,
      if (timeSpentMs != null) 'time_spent_ms': timeSpentMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExamDraftsCompanion copyWith({
    Value<String>? attemptId,
    Value<String>? attempt,
    Value<bool>? submitPending,
    Value<int?>? timeSpentMs,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExamDraftsCompanion(
      attemptId: attemptId ?? this.attemptId,
      attempt: attempt ?? this.attempt,
      submitPending: submitPending ?? this.submitPending,
      timeSpentMs: timeSpentMs ?? this.timeSpentMs,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attemptId.present) {
      map['attempt_id'] = Variable<String>(attemptId.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<String>(attempt.value);
    }
    if (submitPending.present) {
      map['submit_pending'] = Variable<bool>(submitPending.value);
    }
    if (timeSpentMs.present) {
      map['time_spent_ms'] = Variable<int>(timeSpentMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamDraftsCompanion(')
          ..write('attemptId: $attemptId, ')
          ..write('attempt: $attempt, ')
          ..write('submitPending: $submitPending, ')
          ..write('timeSpentMs: $timeSpentMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExamAnswersTable extends ExamAnswers with TableInfo<$ExamAnswersTable, ExamAnswerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptIdMeta = const VerificationMeta('attemptId');
  @override
  late final GeneratedColumn<String> attemptId = GeneratedColumn<String>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedOptionIdMeta = const VerificationMeta('selectedOptionId');
  @override
  late final GeneratedColumn<String> selectedOptionId = GeneratedColumn<String>(
    'selected_option_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _writtenAnswerMeta = const VerificationMeta('writtenAnswer');
  @override
  late final GeneratedColumn<String> writtenAnswer = GeneratedColumn<String>(
    'written_answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flaggedMeta = const VerificationMeta('flagged');
  @override
  late final GeneratedColumn<bool> flagged = GeneratedColumn<bool>(
    'flagged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("flagged" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timeSpentMsMeta = const VerificationMeta('timeSpentMs');
  @override
  late final GeneratedColumn<int> timeSpentMs = GeneratedColumn<int>(
    'time_spent_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    attemptId,
    questionId,
    selectedOptionId,
    writtenAnswer,
    flagged,
    timeSpentMs,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exam_answers';
  @override
  VerificationContext validateIntegrity(Insertable<ExamAnswerRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_id')) {
      context.handle(_attemptIdMeta, attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta));
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(_questionIdMeta, questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('selected_option_id')) {
      context.handle(
        _selectedOptionIdMeta,
        selectedOptionId.isAcceptableOrUnknown(data['selected_option_id']!, _selectedOptionIdMeta),
      );
    }
    if (data.containsKey('written_answer')) {
      context.handle(
        _writtenAnswerMeta,
        writtenAnswer.isAcceptableOrUnknown(data['written_answer']!, _writtenAnswerMeta),
      );
    }
    if (data.containsKey('flagged')) {
      context.handle(_flaggedMeta, flagged.isAcceptableOrUnknown(data['flagged']!, _flaggedMeta));
    }
    if (data.containsKey('time_spent_ms')) {
      context.handle(_timeSpentMsMeta, timeSpentMs.isAcceptableOrUnknown(data['time_spent_ms']!, _timeSpentMsMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(_dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attemptId, questionId};
  @override
  ExamAnswerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamAnswerRow(
      attemptId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}attempt_id'])!,
      questionId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      selectedOptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_option_id'],
      ),
      writtenAnswer: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}written_answer']),
      flagged: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}flagged'])!,
      timeSpentMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}time_spent_ms']),
      dirty: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $ExamAnswersTable createAlias(String alias) {
    return $ExamAnswersTable(attachedDatabase, alias);
  }
}

class ExamAnswerRow extends DataClass implements Insertable<ExamAnswerRow> {
  final String attemptId;
  final String questionId;
  final String? selectedOptionId;
  final String? writtenAnswer;
  final bool flagged;
  final int? timeSpentMs;
  final bool dirty;
  const ExamAnswerRow({
    required this.attemptId,
    required this.questionId,
    this.selectedOptionId,
    this.writtenAnswer,
    required this.flagged,
    this.timeSpentMs,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attempt_id'] = Variable<String>(attemptId);
    map['question_id'] = Variable<String>(questionId);
    if (!nullToAbsent || selectedOptionId != null) {
      map['selected_option_id'] = Variable<String>(selectedOptionId);
    }
    if (!nullToAbsent || writtenAnswer != null) {
      map['written_answer'] = Variable<String>(writtenAnswer);
    }
    map['flagged'] = Variable<bool>(flagged);
    if (!nullToAbsent || timeSpentMs != null) {
      map['time_spent_ms'] = Variable<int>(timeSpentMs);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ExamAnswersCompanion toCompanion(bool nullToAbsent) {
    return ExamAnswersCompanion(
      attemptId: Value(attemptId),
      questionId: Value(questionId),
      selectedOptionId: selectedOptionId == null && nullToAbsent ? const Value.absent() : Value(selectedOptionId),
      writtenAnswer: writtenAnswer == null && nullToAbsent ? const Value.absent() : Value(writtenAnswer),
      flagged: Value(flagged),
      timeSpentMs: timeSpentMs == null && nullToAbsent ? const Value.absent() : Value(timeSpentMs),
      dirty: Value(dirty),
    );
  }

  factory ExamAnswerRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamAnswerRow(
      attemptId: serializer.fromJson<String>(json['attemptId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      selectedOptionId: serializer.fromJson<String?>(json['selectedOptionId']),
      writtenAnswer: serializer.fromJson<String?>(json['writtenAnswer']),
      flagged: serializer.fromJson<bool>(json['flagged']),
      timeSpentMs: serializer.fromJson<int?>(json['timeSpentMs']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attemptId': serializer.toJson<String>(attemptId),
      'questionId': serializer.toJson<String>(questionId),
      'selectedOptionId': serializer.toJson<String?>(selectedOptionId),
      'writtenAnswer': serializer.toJson<String?>(writtenAnswer),
      'flagged': serializer.toJson<bool>(flagged),
      'timeSpentMs': serializer.toJson<int?>(timeSpentMs),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  ExamAnswerRow copyWith({
    String? attemptId,
    String? questionId,
    Value<String?> selectedOptionId = const Value.absent(),
    Value<String?> writtenAnswer = const Value.absent(),
    bool? flagged,
    Value<int?> timeSpentMs = const Value.absent(),
    bool? dirty,
  }) => ExamAnswerRow(
    attemptId: attemptId ?? this.attemptId,
    questionId: questionId ?? this.questionId,
    selectedOptionId: selectedOptionId.present ? selectedOptionId.value : this.selectedOptionId,
    writtenAnswer: writtenAnswer.present ? writtenAnswer.value : this.writtenAnswer,
    flagged: flagged ?? this.flagged,
    timeSpentMs: timeSpentMs.present ? timeSpentMs.value : this.timeSpentMs,
    dirty: dirty ?? this.dirty,
  );
  ExamAnswerRow copyWithCompanion(ExamAnswersCompanion data) {
    return ExamAnswerRow(
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      questionId: data.questionId.present ? data.questionId.value : this.questionId,
      selectedOptionId: data.selectedOptionId.present ? data.selectedOptionId.value : this.selectedOptionId,
      writtenAnswer: data.writtenAnswer.present ? data.writtenAnswer.value : this.writtenAnswer,
      flagged: data.flagged.present ? data.flagged.value : this.flagged,
      timeSpentMs: data.timeSpentMs.present ? data.timeSpentMs.value : this.timeSpentMs,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamAnswerRow(')
          ..write('attemptId: $attemptId, ')
          ..write('questionId: $questionId, ')
          ..write('selectedOptionId: $selectedOptionId, ')
          ..write('writtenAnswer: $writtenAnswer, ')
          ..write('flagged: $flagged, ')
          ..write('timeSpentMs: $timeSpentMs, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(attemptId, questionId, selectedOptionId, writtenAnswer, flagged, timeSpentMs, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamAnswerRow &&
          other.attemptId == this.attemptId &&
          other.questionId == this.questionId &&
          other.selectedOptionId == this.selectedOptionId &&
          other.writtenAnswer == this.writtenAnswer &&
          other.flagged == this.flagged &&
          other.timeSpentMs == this.timeSpentMs &&
          other.dirty == this.dirty);
}

class ExamAnswersCompanion extends UpdateCompanion<ExamAnswerRow> {
  final Value<String> attemptId;
  final Value<String> questionId;
  final Value<String?> selectedOptionId;
  final Value<String?> writtenAnswer;
  final Value<bool> flagged;
  final Value<int?> timeSpentMs;
  final Value<bool> dirty;
  final Value<int> rowid;
  const ExamAnswersCompanion({
    this.attemptId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.selectedOptionId = const Value.absent(),
    this.writtenAnswer = const Value.absent(),
    this.flagged = const Value.absent(),
    this.timeSpentMs = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExamAnswersCompanion.insert({
    required String attemptId,
    required String questionId,
    this.selectedOptionId = const Value.absent(),
    this.writtenAnswer = const Value.absent(),
    this.flagged = const Value.absent(),
    this.timeSpentMs = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : attemptId = Value(attemptId),
       questionId = Value(questionId);
  static Insertable<ExamAnswerRow> custom({
    Expression<String>? attemptId,
    Expression<String>? questionId,
    Expression<String>? selectedOptionId,
    Expression<String>? writtenAnswer,
    Expression<bool>? flagged,
    Expression<int>? timeSpentMs,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attemptId != null) 'attempt_id': attemptId,
      if (questionId != null) 'question_id': questionId,
      if (selectedOptionId != null) 'selected_option_id': selectedOptionId,
      if (writtenAnswer != null) 'written_answer': writtenAnswer,
      if (flagged != null) 'flagged': flagged,
      if (timeSpentMs != null) 'time_spent_ms': timeSpentMs,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExamAnswersCompanion copyWith({
    Value<String>? attemptId,
    Value<String>? questionId,
    Value<String?>? selectedOptionId,
    Value<String?>? writtenAnswer,
    Value<bool>? flagged,
    Value<int?>? timeSpentMs,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return ExamAnswersCompanion(
      attemptId: attemptId ?? this.attemptId,
      questionId: questionId ?? this.questionId,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      writtenAnswer: writtenAnswer ?? this.writtenAnswer,
      flagged: flagged ?? this.flagged,
      timeSpentMs: timeSpentMs ?? this.timeSpentMs,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attemptId.present) {
      map['attempt_id'] = Variable<String>(attemptId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (selectedOptionId.present) {
      map['selected_option_id'] = Variable<String>(selectedOptionId.value);
    }
    if (writtenAnswer.present) {
      map['written_answer'] = Variable<String>(writtenAnswer.value);
    }
    if (flagged.present) {
      map['flagged'] = Variable<bool>(flagged.value);
    }
    if (timeSpentMs.present) {
      map['time_spent_ms'] = Variable<int>(timeSpentMs.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamAnswersCompanion(')
          ..write('attemptId: $attemptId, ')
          ..write('questionId: $questionId, ')
          ..write('selectedOptionId: $selectedOptionId, ')
          ..write('writtenAnswer: $writtenAnswer, ')
          ..write('flagged: $flagged, ')
          ..write('timeSpentMs: $timeSpentMs, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDecksTable extends LocalDecks with TableInfo<$LocalDecksTable, LocalDeckRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, subjectId, color, sortOrder, createdAt, updatedAt, deletedAt, dirty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_decks';
  @override
  VerificationContext validateIntegrity(Insertable<LocalDeckRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta, subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(_dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDeckRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDeckRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      subjectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}subject_id']),
      color: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}color']),
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $LocalDecksTable createAlias(String alias) {
    return $LocalDecksTable(attachedDatabase, alias);
  }
}

class LocalDeckRow extends DataClass implements Insertable<LocalDeckRow> {
  final String id;
  final String name;
  final String? subjectId;
  final String? color;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final bool dirty;
  const LocalDeckRow({
    required this.id,
    required this.name,
    this.subjectId,
    this.color,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  LocalDecksCompanion toCompanion(bool nullToAbsent) {
    return LocalDecksCompanion(
      id: Value(id),
      name: Value(name),
      subjectId: subjectId == null && nullToAbsent ? const Value.absent() : Value(subjectId),
      color: color == null && nullToAbsent ? const Value.absent() : Value(color),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory LocalDeckRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDeckRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      subjectId: serializer.fromJson<String?>(json['subjectId']),
      color: serializer.fromJson<String?>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'subjectId': serializer.toJson<String?>(subjectId),
      'color': serializer.toJson<String?>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  LocalDeckRow copyWith({
    String? id,
    String? name,
    Value<String?> subjectId = const Value.absent(),
    Value<String?> color = const Value.absent(),
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    bool? dirty,
  }) => LocalDeckRow(
    id: id ?? this.id,
    name: name ?? this.name,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    color: color.present ? color.value : this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    dirty: dirty ?? this.dirty,
  );
  LocalDeckRow copyWithCompanion(LocalDecksCompanion data) {
    return LocalDeckRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDeckRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subjectId: $subjectId, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, subjectId, color, sortOrder, createdAt, updatedAt, deletedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDeckRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.subjectId == this.subjectId &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class LocalDecksCompanion extends UpdateCompanion<LocalDeckRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> subjectId;
  final Value<String?> color;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const LocalDecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDecksCompanion.insert({
    required String id,
    required String name,
    this.subjectId = const Value.absent(),
    this.color = const Value.absent(),
    required int sortOrder,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalDeckRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? subjectId,
    Expression<String>? color,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (subjectId != null) 'subject_id': subjectId,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDecksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? subjectId,
    Value<String?>? color,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return LocalDecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectId: subjectId ?? this.subjectId,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subjectId: $subjectId, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCardsTable extends LocalCards with TableInfo<$LocalCardsTable, LocalCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _officialFlashcardIdMeta = const VerificationMeta('officialFlashcardId');
  @override
  late final GeneratedColumn<String> officialFlashcardId = GeneratedColumn<String>(
    'official_flashcard_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frontTextMeta = const VerificationMeta('frontText');
  @override
  late final GeneratedColumn<String> frontText = GeneratedColumn<String>(
    'front_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backTextMeta = const VerificationMeta('backText');
  @override
  late final GeneratedColumn<String> backText = GeneratedColumn<String>(
    'back_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frontMediaIdMeta = const VerificationMeta('frontMediaId');
  @override
  late final GeneratedColumn<String> frontMediaId = GeneratedColumn<String>(
    'front_media_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backMediaIdMeta = const VerificationMeta('backMediaId');
  @override
  late final GeneratedColumn<String> backMediaId = GeneratedColumn<String>(
    'back_media_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frontImageJsonMeta = const VerificationMeta('frontImageJson');
  @override
  late final GeneratedColumn<String> frontImageJson = GeneratedColumn<String>(
    'front_image_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backImageJsonMeta = const VerificationMeta('backImageJson');
  @override
  late final GeneratedColumn<String> backImageJson = GeneratedColumn<String>(
    'back_image_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frontLocalImageMeta = const VerificationMeta('frontLocalImage');
  @override
  late final GeneratedColumn<Uint8List> frontLocalImage = GeneratedColumn<Uint8List>(
    'front_local_image',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backLocalImageMeta = const VerificationMeta('backLocalImage');
  @override
  late final GeneratedColumn<Uint8List> backLocalImage = GeneratedColumn<Uint8List>(
    'back_local_image',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockedMeta = const VerificationMeta('locked');
  @override
  late final GeneratedColumn<bool> locked = GeneratedColumn<bool>(
    'locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("locked" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    kind,
    officialFlashcardId,
    frontText,
    backText,
    frontMediaId,
    backMediaId,
    frontImageJson,
    backImageJson,
    frontLocalImage,
    backLocalImage,
    locked,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cards';
  @override
  VerificationContext validateIntegrity(Insertable<LocalCardRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(_deckIdMeta, deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta));
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('official_flashcard_id')) {
      context.handle(
        _officialFlashcardIdMeta,
        officialFlashcardId.isAcceptableOrUnknown(data['official_flashcard_id']!, _officialFlashcardIdMeta),
      );
    }
    if (data.containsKey('front_text')) {
      context.handle(_frontTextMeta, frontText.isAcceptableOrUnknown(data['front_text']!, _frontTextMeta));
    }
    if (data.containsKey('back_text')) {
      context.handle(_backTextMeta, backText.isAcceptableOrUnknown(data['back_text']!, _backTextMeta));
    }
    if (data.containsKey('front_media_id')) {
      context.handle(_frontMediaIdMeta, frontMediaId.isAcceptableOrUnknown(data['front_media_id']!, _frontMediaIdMeta));
    }
    if (data.containsKey('back_media_id')) {
      context.handle(_backMediaIdMeta, backMediaId.isAcceptableOrUnknown(data['back_media_id']!, _backMediaIdMeta));
    }
    if (data.containsKey('front_image_json')) {
      context.handle(
        _frontImageJsonMeta,
        frontImageJson.isAcceptableOrUnknown(data['front_image_json']!, _frontImageJsonMeta),
      );
    }
    if (data.containsKey('back_image_json')) {
      context.handle(
        _backImageJsonMeta,
        backImageJson.isAcceptableOrUnknown(data['back_image_json']!, _backImageJsonMeta),
      );
    }
    if (data.containsKey('front_local_image')) {
      context.handle(
        _frontLocalImageMeta,
        frontLocalImage.isAcceptableOrUnknown(data['front_local_image']!, _frontLocalImageMeta),
      );
    }
    if (data.containsKey('back_local_image')) {
      context.handle(
        _backLocalImageMeta,
        backLocalImage.isAcceptableOrUnknown(data['back_local_image']!, _backLocalImageMeta),
      );
    }
    if (data.containsKey('locked')) {
      context.handle(_lockedMeta, locked.isAcceptableOrUnknown(data['locked']!, _lockedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(_dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCardRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      deckId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}deck_id'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      officialFlashcardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}official_flashcard_id'],
      ),
      frontText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}front_text']),
      backText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}back_text']),
      frontMediaId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}front_media_id']),
      backMediaId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}back_media_id']),
      frontImageJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front_image_json'],
      ),
      backImageJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}back_image_json']),
      frontLocalImage: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}front_local_image'],
      ),
      backLocalImage: attachedDatabase.typeMapping.read(DriftSqlType.blob, data['${effectivePrefix}back_local_image']),
      locked: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}locked'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $LocalCardsTable createAlias(String alias) {
    return $LocalCardsTable(attachedDatabase, alias);
  }
}

class LocalCardRow extends DataClass implements Insertable<LocalCardRow> {
  final String id;
  final String deckId;
  final String kind;
  final String? officialFlashcardId;
  final String? frontText;
  final String? backText;
  final String? frontMediaId;
  final String? backMediaId;
  final String? frontImageJson;
  final String? backImageJson;
  final Uint8List? frontLocalImage;
  final Uint8List? backLocalImage;
  final bool locked;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final bool dirty;
  const LocalCardRow({
    required this.id,
    required this.deckId,
    required this.kind,
    this.officialFlashcardId,
    this.frontText,
    this.backText,
    this.frontMediaId,
    this.backMediaId,
    this.frontImageJson,
    this.backImageJson,
    this.frontLocalImage,
    this.backLocalImage,
    required this.locked,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || officialFlashcardId != null) {
      map['official_flashcard_id'] = Variable<String>(officialFlashcardId);
    }
    if (!nullToAbsent || frontText != null) {
      map['front_text'] = Variable<String>(frontText);
    }
    if (!nullToAbsent || backText != null) {
      map['back_text'] = Variable<String>(backText);
    }
    if (!nullToAbsent || frontMediaId != null) {
      map['front_media_id'] = Variable<String>(frontMediaId);
    }
    if (!nullToAbsent || backMediaId != null) {
      map['back_media_id'] = Variable<String>(backMediaId);
    }
    if (!nullToAbsent || frontImageJson != null) {
      map['front_image_json'] = Variable<String>(frontImageJson);
    }
    if (!nullToAbsent || backImageJson != null) {
      map['back_image_json'] = Variable<String>(backImageJson);
    }
    if (!nullToAbsent || frontLocalImage != null) {
      map['front_local_image'] = Variable<Uint8List>(frontLocalImage);
    }
    if (!nullToAbsent || backLocalImage != null) {
      map['back_local_image'] = Variable<Uint8List>(backLocalImage);
    }
    map['locked'] = Variable<bool>(locked);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  LocalCardsCompanion toCompanion(bool nullToAbsent) {
    return LocalCardsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      kind: Value(kind),
      officialFlashcardId: officialFlashcardId == null && nullToAbsent
          ? const Value.absent()
          : Value(officialFlashcardId),
      frontText: frontText == null && nullToAbsent ? const Value.absent() : Value(frontText),
      backText: backText == null && nullToAbsent ? const Value.absent() : Value(backText),
      frontMediaId: frontMediaId == null && nullToAbsent ? const Value.absent() : Value(frontMediaId),
      backMediaId: backMediaId == null && nullToAbsent ? const Value.absent() : Value(backMediaId),
      frontImageJson: frontImageJson == null && nullToAbsent ? const Value.absent() : Value(frontImageJson),
      backImageJson: backImageJson == null && nullToAbsent ? const Value.absent() : Value(backImageJson),
      frontLocalImage: frontLocalImage == null && nullToAbsent ? const Value.absent() : Value(frontLocalImage),
      backLocalImage: backLocalImage == null && nullToAbsent ? const Value.absent() : Value(backLocalImage),
      locked: Value(locked),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory LocalCardRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCardRow(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      kind: serializer.fromJson<String>(json['kind']),
      officialFlashcardId: serializer.fromJson<String?>(json['officialFlashcardId']),
      frontText: serializer.fromJson<String?>(json['frontText']),
      backText: serializer.fromJson<String?>(json['backText']),
      frontMediaId: serializer.fromJson<String?>(json['frontMediaId']),
      backMediaId: serializer.fromJson<String?>(json['backMediaId']),
      frontImageJson: serializer.fromJson<String?>(json['frontImageJson']),
      backImageJson: serializer.fromJson<String?>(json['backImageJson']),
      frontLocalImage: serializer.fromJson<Uint8List?>(json['frontLocalImage']),
      backLocalImage: serializer.fromJson<Uint8List?>(json['backLocalImage']),
      locked: serializer.fromJson<bool>(json['locked']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'kind': serializer.toJson<String>(kind),
      'officialFlashcardId': serializer.toJson<String?>(officialFlashcardId),
      'frontText': serializer.toJson<String?>(frontText),
      'backText': serializer.toJson<String?>(backText),
      'frontMediaId': serializer.toJson<String?>(frontMediaId),
      'backMediaId': serializer.toJson<String?>(backMediaId),
      'frontImageJson': serializer.toJson<String?>(frontImageJson),
      'backImageJson': serializer.toJson<String?>(backImageJson),
      'frontLocalImage': serializer.toJson<Uint8List?>(frontLocalImage),
      'backLocalImage': serializer.toJson<Uint8List?>(backLocalImage),
      'locked': serializer.toJson<bool>(locked),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  LocalCardRow copyWith({
    String? id,
    String? deckId,
    String? kind,
    Value<String?> officialFlashcardId = const Value.absent(),
    Value<String?> frontText = const Value.absent(),
    Value<String?> backText = const Value.absent(),
    Value<String?> frontMediaId = const Value.absent(),
    Value<String?> backMediaId = const Value.absent(),
    Value<String?> frontImageJson = const Value.absent(),
    Value<String?> backImageJson = const Value.absent(),
    Value<Uint8List?> frontLocalImage = const Value.absent(),
    Value<Uint8List?> backLocalImage = const Value.absent(),
    bool? locked,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    bool? dirty,
  }) => LocalCardRow(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    kind: kind ?? this.kind,
    officialFlashcardId: officialFlashcardId.present ? officialFlashcardId.value : this.officialFlashcardId,
    frontText: frontText.present ? frontText.value : this.frontText,
    backText: backText.present ? backText.value : this.backText,
    frontMediaId: frontMediaId.present ? frontMediaId.value : this.frontMediaId,
    backMediaId: backMediaId.present ? backMediaId.value : this.backMediaId,
    frontImageJson: frontImageJson.present ? frontImageJson.value : this.frontImageJson,
    backImageJson: backImageJson.present ? backImageJson.value : this.backImageJson,
    frontLocalImage: frontLocalImage.present ? frontLocalImage.value : this.frontLocalImage,
    backLocalImage: backLocalImage.present ? backLocalImage.value : this.backLocalImage,
    locked: locked ?? this.locked,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    dirty: dirty ?? this.dirty,
  );
  LocalCardRow copyWithCompanion(LocalCardsCompanion data) {
    return LocalCardRow(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      kind: data.kind.present ? data.kind.value : this.kind,
      officialFlashcardId: data.officialFlashcardId.present ? data.officialFlashcardId.value : this.officialFlashcardId,
      frontText: data.frontText.present ? data.frontText.value : this.frontText,
      backText: data.backText.present ? data.backText.value : this.backText,
      frontMediaId: data.frontMediaId.present ? data.frontMediaId.value : this.frontMediaId,
      backMediaId: data.backMediaId.present ? data.backMediaId.value : this.backMediaId,
      frontImageJson: data.frontImageJson.present ? data.frontImageJson.value : this.frontImageJson,
      backImageJson: data.backImageJson.present ? data.backImageJson.value : this.backImageJson,
      frontLocalImage: data.frontLocalImage.present ? data.frontLocalImage.value : this.frontLocalImage,
      backLocalImage: data.backLocalImage.present ? data.backLocalImage.value : this.backLocalImage,
      locked: data.locked.present ? data.locked.value : this.locked,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCardRow(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('kind: $kind, ')
          ..write('officialFlashcardId: $officialFlashcardId, ')
          ..write('frontText: $frontText, ')
          ..write('backText: $backText, ')
          ..write('frontMediaId: $frontMediaId, ')
          ..write('backMediaId: $backMediaId, ')
          ..write('frontImageJson: $frontImageJson, ')
          ..write('backImageJson: $backImageJson, ')
          ..write('frontLocalImage: $frontLocalImage, ')
          ..write('backLocalImage: $backLocalImage, ')
          ..write('locked: $locked, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    kind,
    officialFlashcardId,
    frontText,
    backText,
    frontMediaId,
    backMediaId,
    frontImageJson,
    backImageJson,
    $driftBlobEquality.hash(frontLocalImage),
    $driftBlobEquality.hash(backLocalImage),
    locked,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
    dirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCardRow &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.kind == this.kind &&
          other.officialFlashcardId == this.officialFlashcardId &&
          other.frontText == this.frontText &&
          other.backText == this.backText &&
          other.frontMediaId == this.frontMediaId &&
          other.backMediaId == this.backMediaId &&
          other.frontImageJson == this.frontImageJson &&
          other.backImageJson == this.backImageJson &&
          $driftBlobEquality.equals(other.frontLocalImage, this.frontLocalImage) &&
          $driftBlobEquality.equals(other.backLocalImage, this.backLocalImage) &&
          other.locked == this.locked &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class LocalCardsCompanion extends UpdateCompanion<LocalCardRow> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> kind;
  final Value<String?> officialFlashcardId;
  final Value<String?> frontText;
  final Value<String?> backText;
  final Value<String?> frontMediaId;
  final Value<String?> backMediaId;
  final Value<String?> frontImageJson;
  final Value<String?> backImageJson;
  final Value<Uint8List?> frontLocalImage;
  final Value<Uint8List?> backLocalImage;
  final Value<bool> locked;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const LocalCardsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.kind = const Value.absent(),
    this.officialFlashcardId = const Value.absent(),
    this.frontText = const Value.absent(),
    this.backText = const Value.absent(),
    this.frontMediaId = const Value.absent(),
    this.backMediaId = const Value.absent(),
    this.frontImageJson = const Value.absent(),
    this.backImageJson = const Value.absent(),
    this.frontLocalImage = const Value.absent(),
    this.backLocalImage = const Value.absent(),
    this.locked = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCardsCompanion.insert({
    required String id,
    required String deckId,
    required String kind,
    this.officialFlashcardId = const Value.absent(),
    this.frontText = const Value.absent(),
    this.backText = const Value.absent(),
    this.frontMediaId = const Value.absent(),
    this.backMediaId = const Value.absent(),
    this.frontImageJson = const Value.absent(),
    this.backImageJson = const Value.absent(),
    this.frontLocalImage = const Value.absent(),
    this.backLocalImage = const Value.absent(),
    this.locked = const Value.absent(),
    required int sortOrder,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       kind = Value(kind),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalCardRow> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? kind,
    Expression<String>? officialFlashcardId,
    Expression<String>? frontText,
    Expression<String>? backText,
    Expression<String>? frontMediaId,
    Expression<String>? backMediaId,
    Expression<String>? frontImageJson,
    Expression<String>? backImageJson,
    Expression<Uint8List>? frontLocalImage,
    Expression<Uint8List>? backLocalImage,
    Expression<bool>? locked,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (kind != null) 'kind': kind,
      if (officialFlashcardId != null) 'official_flashcard_id': officialFlashcardId,
      if (frontText != null) 'front_text': frontText,
      if (backText != null) 'back_text': backText,
      if (frontMediaId != null) 'front_media_id': frontMediaId,
      if (backMediaId != null) 'back_media_id': backMediaId,
      if (frontImageJson != null) 'front_image_json': frontImageJson,
      if (backImageJson != null) 'back_image_json': backImageJson,
      if (frontLocalImage != null) 'front_local_image': frontLocalImage,
      if (backLocalImage != null) 'back_local_image': backLocalImage,
      if (locked != null) 'locked': locked,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? kind,
    Value<String?>? officialFlashcardId,
    Value<String?>? frontText,
    Value<String?>? backText,
    Value<String?>? frontMediaId,
    Value<String?>? backMediaId,
    Value<String?>? frontImageJson,
    Value<String?>? backImageJson,
    Value<Uint8List?>? frontLocalImage,
    Value<Uint8List?>? backLocalImage,
    Value<bool>? locked,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return LocalCardsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      kind: kind ?? this.kind,
      officialFlashcardId: officialFlashcardId ?? this.officialFlashcardId,
      frontText: frontText ?? this.frontText,
      backText: backText ?? this.backText,
      frontMediaId: frontMediaId ?? this.frontMediaId,
      backMediaId: backMediaId ?? this.backMediaId,
      frontImageJson: frontImageJson ?? this.frontImageJson,
      backImageJson: backImageJson ?? this.backImageJson,
      frontLocalImage: frontLocalImage ?? this.frontLocalImage,
      backLocalImage: backLocalImage ?? this.backLocalImage,
      locked: locked ?? this.locked,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (officialFlashcardId.present) {
      map['official_flashcard_id'] = Variable<String>(officialFlashcardId.value);
    }
    if (frontText.present) {
      map['front_text'] = Variable<String>(frontText.value);
    }
    if (backText.present) {
      map['back_text'] = Variable<String>(backText.value);
    }
    if (frontMediaId.present) {
      map['front_media_id'] = Variable<String>(frontMediaId.value);
    }
    if (backMediaId.present) {
      map['back_media_id'] = Variable<String>(backMediaId.value);
    }
    if (frontImageJson.present) {
      map['front_image_json'] = Variable<String>(frontImageJson.value);
    }
    if (backImageJson.present) {
      map['back_image_json'] = Variable<String>(backImageJson.value);
    }
    if (frontLocalImage.present) {
      map['front_local_image'] = Variable<Uint8List>(frontLocalImage.value);
    }
    if (backLocalImage.present) {
      map['back_local_image'] = Variable<Uint8List>(backLocalImage.value);
    }
    if (locked.present) {
      map['locked'] = Variable<bool>(locked.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCardsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('kind: $kind, ')
          ..write('officialFlashcardId: $officialFlashcardId, ')
          ..write('frontText: $frontText, ')
          ..write('backText: $backText, ')
          ..write('frontMediaId: $frontMediaId, ')
          ..write('backMediaId: $backMediaId, ')
          ..write('frontImageJson: $frontImageJson, ')
          ..write('backImageJson: $backImageJson, ')
          ..write('frontLocalImage: $frontLocalImage, ')
          ..write('backLocalImage: $backLocalImage, ')
          ..write('locked: $locked, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflinePacksTable extends OfflinePacks with TableInfo<$OfflinePacksTable, OfflinePackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflinePacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packKeyMeta = const VerificationMeta('packKey');
  @override
  late final GeneratedColumn<String> packKey = GeneratedColumn<String>(
    'pack_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeTypeMeta = const VerificationMeta('scopeType');
  @override
  late final GeneratedColumn<String> scopeType = GeneratedColumn<String>(
    'scope_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teacherTrackIdMeta = const VerificationMeta('teacherTrackId');
  @override
  late final GeneratedColumn<String> teacherTrackId = GeneratedColumn<String>(
    'teacher_track_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scopeTitleMeta = const VerificationMeta('scopeTitle');
  @override
  late final GeneratedColumn<String> scopeTitle = GeneratedColumn<String>(
    'scope_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleArMeta = const VerificationMeta('titleAr');
  @override
  late final GeneratedColumn<String> titleAr = GeneratedColumn<String>(
    'title_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta('version');
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteVersionMeta = const VerificationMeta('remoteVersion');
  @override
  late final GeneratedColumn<String> remoteVersion = GeneratedColumn<String>(
    'remote_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _premiumMeta = const VerificationMeta('premium');
  @override
  late final GeneratedColumn<bool> premium = GeneratedColumn<bool>(
    'premium',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("premium" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _normalizationVersionMeta = const VerificationMeta('normalizationVersion');
  @override
  late final GeneratedColumn<int> normalizationVersion = GeneratedColumn<int>(
    'normalization_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta('downloadedBytes');
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    packKey,
    scopeType,
    subjectId,
    teacherTrackId,
    scopeTitle,
    kind,
    unitId,
    deckId,
    titleAr,
    status,
    version,
    remoteVersion,
    premium,
    normalizationVersion,
    sizeBytes,
    downloadedBytes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_packs';
  @override
  VerificationContext validateIntegrity(Insertable<OfflinePackRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_key')) {
      context.handle(_packKeyMeta, packKey.isAcceptableOrUnknown(data['pack_key']!, _packKeyMeta));
    } else if (isInserting) {
      context.missing(_packKeyMeta);
    }
    if (data.containsKey('scope_type')) {
      context.handle(_scopeTypeMeta, scopeType.isAcceptableOrUnknown(data['scope_type']!, _scopeTypeMeta));
    } else if (isInserting) {
      context.missing(_scopeTypeMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta, subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    }
    if (data.containsKey('teacher_track_id')) {
      context.handle(
        _teacherTrackIdMeta,
        teacherTrackId.isAcceptableOrUnknown(data['teacher_track_id']!, _teacherTrackIdMeta),
      );
    }
    if (data.containsKey('scope_title')) {
      context.handle(_scopeTitleMeta, scopeTitle.isAcceptableOrUnknown(data['scope_title']!, _scopeTitleMeta));
    } else if (isInserting) {
      context.missing(_scopeTitleMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta, unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    if (data.containsKey('deck_id')) {
      context.handle(_deckIdMeta, deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta));
    }
    if (data.containsKey('title_ar')) {
      context.handle(_titleArMeta, titleAr.isAcceptableOrUnknown(data['title_ar']!, _titleArMeta));
    } else if (isInserting) {
      context.missing(_titleArMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta, version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('remote_version')) {
      context.handle(
        _remoteVersionMeta,
        remoteVersion.isAcceptableOrUnknown(data['remote_version']!, _remoteVersionMeta),
      );
    }
    if (data.containsKey('premium')) {
      context.handle(_premiumMeta, premium.isAcceptableOrUnknown(data['premium']!, _premiumMeta));
    }
    if (data.containsKey('normalization_version')) {
      context.handle(
        _normalizationVersionMeta,
        normalizationVersion.isAcceptableOrUnknown(data['normalization_version']!, _normalizationVersionMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta, sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(data['downloaded_bytes']!, _downloadedBytesMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packKey};
  @override
  OfflinePackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflinePackRow(
      packKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pack_key'])!,
      scopeType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}scope_type'])!,
      subjectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}subject_id']),
      teacherTrackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_track_id'],
      ),
      scopeTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}scope_title'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      unitId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unit_id']),
      deckId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}deck_id']),
      titleAr: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title_ar'])!,
      status: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      version: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}version']),
      remoteVersion: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}remote_version']),
      premium: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}premium'])!,
      normalizationVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}normalization_version'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      downloadedBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}downloaded_bytes'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OfflinePacksTable createAlias(String alias) {
    return $OfflinePacksTable(attachedDatabase, alias);
  }
}

class OfflinePackRow extends DataClass implements Insertable<OfflinePackRow> {
  final String packKey;
  final String scopeType;
  final String? subjectId;
  final String? teacherTrackId;
  final String scopeTitle;
  final String kind;
  final String? unitId;
  final String? deckId;
  final String titleAr;

  /// queued | downloading | paused | waiting_wifi | ready | failed
  final String status;
  final String? version;
  final String? remoteVersion;
  final bool premium;
  final int? normalizationVersion;
  final int sizeBytes;
  final int downloadedBytes;
  final int updatedAt;
  const OfflinePackRow({
    required this.packKey,
    required this.scopeType,
    this.subjectId,
    this.teacherTrackId,
    required this.scopeTitle,
    required this.kind,
    this.unitId,
    this.deckId,
    required this.titleAr,
    required this.status,
    this.version,
    this.remoteVersion,
    required this.premium,
    this.normalizationVersion,
    required this.sizeBytes,
    required this.downloadedBytes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_key'] = Variable<String>(packKey);
    map['scope_type'] = Variable<String>(scopeType);
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || teacherTrackId != null) {
      map['teacher_track_id'] = Variable<String>(teacherTrackId);
    }
    map['scope_title'] = Variable<String>(scopeTitle);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    if (!nullToAbsent || deckId != null) {
      map['deck_id'] = Variable<String>(deckId);
    }
    map['title_ar'] = Variable<String>(titleAr);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    if (!nullToAbsent || remoteVersion != null) {
      map['remote_version'] = Variable<String>(remoteVersion);
    }
    map['premium'] = Variable<bool>(premium);
    if (!nullToAbsent || normalizationVersion != null) {
      map['normalization_version'] = Variable<int>(normalizationVersion);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  OfflinePacksCompanion toCompanion(bool nullToAbsent) {
    return OfflinePacksCompanion(
      packKey: Value(packKey),
      scopeType: Value(scopeType),
      subjectId: subjectId == null && nullToAbsent ? const Value.absent() : Value(subjectId),
      teacherTrackId: teacherTrackId == null && nullToAbsent ? const Value.absent() : Value(teacherTrackId),
      scopeTitle: Value(scopeTitle),
      kind: Value(kind),
      unitId: unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
      deckId: deckId == null && nullToAbsent ? const Value.absent() : Value(deckId),
      titleAr: Value(titleAr),
      status: Value(status),
      version: version == null && nullToAbsent ? const Value.absent() : Value(version),
      remoteVersion: remoteVersion == null && nullToAbsent ? const Value.absent() : Value(remoteVersion),
      premium: Value(premium),
      normalizationVersion: normalizationVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(normalizationVersion),
      sizeBytes: Value(sizeBytes),
      downloadedBytes: Value(downloadedBytes),
      updatedAt: Value(updatedAt),
    );
  }

  factory OfflinePackRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflinePackRow(
      packKey: serializer.fromJson<String>(json['packKey']),
      scopeType: serializer.fromJson<String>(json['scopeType']),
      subjectId: serializer.fromJson<String?>(json['subjectId']),
      teacherTrackId: serializer.fromJson<String?>(json['teacherTrackId']),
      scopeTitle: serializer.fromJson<String>(json['scopeTitle']),
      kind: serializer.fromJson<String>(json['kind']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      deckId: serializer.fromJson<String?>(json['deckId']),
      titleAr: serializer.fromJson<String>(json['titleAr']),
      status: serializer.fromJson<String>(json['status']),
      version: serializer.fromJson<String?>(json['version']),
      remoteVersion: serializer.fromJson<String?>(json['remoteVersion']),
      premium: serializer.fromJson<bool>(json['premium']),
      normalizationVersion: serializer.fromJson<int?>(json['normalizationVersion']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packKey': serializer.toJson<String>(packKey),
      'scopeType': serializer.toJson<String>(scopeType),
      'subjectId': serializer.toJson<String?>(subjectId),
      'teacherTrackId': serializer.toJson<String?>(teacherTrackId),
      'scopeTitle': serializer.toJson<String>(scopeTitle),
      'kind': serializer.toJson<String>(kind),
      'unitId': serializer.toJson<String?>(unitId),
      'deckId': serializer.toJson<String?>(deckId),
      'titleAr': serializer.toJson<String>(titleAr),
      'status': serializer.toJson<String>(status),
      'version': serializer.toJson<String?>(version),
      'remoteVersion': serializer.toJson<String?>(remoteVersion),
      'premium': serializer.toJson<bool>(premium),
      'normalizationVersion': serializer.toJson<int?>(normalizationVersion),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  OfflinePackRow copyWith({
    String? packKey,
    String? scopeType,
    Value<String?> subjectId = const Value.absent(),
    Value<String?> teacherTrackId = const Value.absent(),
    String? scopeTitle,
    String? kind,
    Value<String?> unitId = const Value.absent(),
    Value<String?> deckId = const Value.absent(),
    String? titleAr,
    String? status,
    Value<String?> version = const Value.absent(),
    Value<String?> remoteVersion = const Value.absent(),
    bool? premium,
    Value<int?> normalizationVersion = const Value.absent(),
    int? sizeBytes,
    int? downloadedBytes,
    int? updatedAt,
  }) => OfflinePackRow(
    packKey: packKey ?? this.packKey,
    scopeType: scopeType ?? this.scopeType,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    teacherTrackId: teacherTrackId.present ? teacherTrackId.value : this.teacherTrackId,
    scopeTitle: scopeTitle ?? this.scopeTitle,
    kind: kind ?? this.kind,
    unitId: unitId.present ? unitId.value : this.unitId,
    deckId: deckId.present ? deckId.value : this.deckId,
    titleAr: titleAr ?? this.titleAr,
    status: status ?? this.status,
    version: version.present ? version.value : this.version,
    remoteVersion: remoteVersion.present ? remoteVersion.value : this.remoteVersion,
    premium: premium ?? this.premium,
    normalizationVersion: normalizationVersion.present ? normalizationVersion.value : this.normalizationVersion,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OfflinePackRow copyWithCompanion(OfflinePacksCompanion data) {
    return OfflinePackRow(
      packKey: data.packKey.present ? data.packKey.value : this.packKey,
      scopeType: data.scopeType.present ? data.scopeType.value : this.scopeType,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      teacherTrackId: data.teacherTrackId.present ? data.teacherTrackId.value : this.teacherTrackId,
      scopeTitle: data.scopeTitle.present ? data.scopeTitle.value : this.scopeTitle,
      kind: data.kind.present ? data.kind.value : this.kind,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      titleAr: data.titleAr.present ? data.titleAr.value : this.titleAr,
      status: data.status.present ? data.status.value : this.status,
      version: data.version.present ? data.version.value : this.version,
      remoteVersion: data.remoteVersion.present ? data.remoteVersion.value : this.remoteVersion,
      premium: data.premium.present ? data.premium.value : this.premium,
      normalizationVersion: data.normalizationVersion.present
          ? data.normalizationVersion.value
          : this.normalizationVersion,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      downloadedBytes: data.downloadedBytes.present ? data.downloadedBytes.value : this.downloadedBytes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflinePackRow(')
          ..write('packKey: $packKey, ')
          ..write('scopeType: $scopeType, ')
          ..write('subjectId: $subjectId, ')
          ..write('teacherTrackId: $teacherTrackId, ')
          ..write('scopeTitle: $scopeTitle, ')
          ..write('kind: $kind, ')
          ..write('unitId: $unitId, ')
          ..write('deckId: $deckId, ')
          ..write('titleAr: $titleAr, ')
          ..write('status: $status, ')
          ..write('version: $version, ')
          ..write('remoteVersion: $remoteVersion, ')
          ..write('premium: $premium, ')
          ..write('normalizationVersion: $normalizationVersion, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    packKey,
    scopeType,
    subjectId,
    teacherTrackId,
    scopeTitle,
    kind,
    unitId,
    deckId,
    titleAr,
    status,
    version,
    remoteVersion,
    premium,
    normalizationVersion,
    sizeBytes,
    downloadedBytes,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflinePackRow &&
          other.packKey == this.packKey &&
          other.scopeType == this.scopeType &&
          other.subjectId == this.subjectId &&
          other.teacherTrackId == this.teacherTrackId &&
          other.scopeTitle == this.scopeTitle &&
          other.kind == this.kind &&
          other.unitId == this.unitId &&
          other.deckId == this.deckId &&
          other.titleAr == this.titleAr &&
          other.status == this.status &&
          other.version == this.version &&
          other.remoteVersion == this.remoteVersion &&
          other.premium == this.premium &&
          other.normalizationVersion == this.normalizationVersion &&
          other.sizeBytes == this.sizeBytes &&
          other.downloadedBytes == this.downloadedBytes &&
          other.updatedAt == this.updatedAt);
}

class OfflinePacksCompanion extends UpdateCompanion<OfflinePackRow> {
  final Value<String> packKey;
  final Value<String> scopeType;
  final Value<String?> subjectId;
  final Value<String?> teacherTrackId;
  final Value<String> scopeTitle;
  final Value<String> kind;
  final Value<String?> unitId;
  final Value<String?> deckId;
  final Value<String> titleAr;
  final Value<String> status;
  final Value<String?> version;
  final Value<String?> remoteVersion;
  final Value<bool> premium;
  final Value<int?> normalizationVersion;
  final Value<int> sizeBytes;
  final Value<int> downloadedBytes;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const OfflinePacksCompanion({
    this.packKey = const Value.absent(),
    this.scopeType = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.teacherTrackId = const Value.absent(),
    this.scopeTitle = const Value.absent(),
    this.kind = const Value.absent(),
    this.unitId = const Value.absent(),
    this.deckId = const Value.absent(),
    this.titleAr = const Value.absent(),
    this.status = const Value.absent(),
    this.version = const Value.absent(),
    this.remoteVersion = const Value.absent(),
    this.premium = const Value.absent(),
    this.normalizationVersion = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflinePacksCompanion.insert({
    required String packKey,
    required String scopeType,
    this.subjectId = const Value.absent(),
    this.teacherTrackId = const Value.absent(),
    required String scopeTitle,
    required String kind,
    this.unitId = const Value.absent(),
    this.deckId = const Value.absent(),
    required String titleAr,
    required String status,
    this.version = const Value.absent(),
    this.remoteVersion = const Value.absent(),
    this.premium = const Value.absent(),
    this.normalizationVersion = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : packKey = Value(packKey),
       scopeType = Value(scopeType),
       scopeTitle = Value(scopeTitle),
       kind = Value(kind),
       titleAr = Value(titleAr),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<OfflinePackRow> custom({
    Expression<String>? packKey,
    Expression<String>? scopeType,
    Expression<String>? subjectId,
    Expression<String>? teacherTrackId,
    Expression<String>? scopeTitle,
    Expression<String>? kind,
    Expression<String>? unitId,
    Expression<String>? deckId,
    Expression<String>? titleAr,
    Expression<String>? status,
    Expression<String>? version,
    Expression<String>? remoteVersion,
    Expression<bool>? premium,
    Expression<int>? normalizationVersion,
    Expression<int>? sizeBytes,
    Expression<int>? downloadedBytes,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packKey != null) 'pack_key': packKey,
      if (scopeType != null) 'scope_type': scopeType,
      if (subjectId != null) 'subject_id': subjectId,
      if (teacherTrackId != null) 'teacher_track_id': teacherTrackId,
      if (scopeTitle != null) 'scope_title': scopeTitle,
      if (kind != null) 'kind': kind,
      if (unitId != null) 'unit_id': unitId,
      if (deckId != null) 'deck_id': deckId,
      if (titleAr != null) 'title_ar': titleAr,
      if (status != null) 'status': status,
      if (version != null) 'version': version,
      if (remoteVersion != null) 'remote_version': remoteVersion,
      if (premium != null) 'premium': premium,
      if (normalizationVersion != null) 'normalization_version': normalizationVersion,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflinePacksCompanion copyWith({
    Value<String>? packKey,
    Value<String>? scopeType,
    Value<String?>? subjectId,
    Value<String?>? teacherTrackId,
    Value<String>? scopeTitle,
    Value<String>? kind,
    Value<String?>? unitId,
    Value<String?>? deckId,
    Value<String>? titleAr,
    Value<String>? status,
    Value<String?>? version,
    Value<String?>? remoteVersion,
    Value<bool>? premium,
    Value<int?>? normalizationVersion,
    Value<int>? sizeBytes,
    Value<int>? downloadedBytes,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return OfflinePacksCompanion(
      packKey: packKey ?? this.packKey,
      scopeType: scopeType ?? this.scopeType,
      subjectId: subjectId ?? this.subjectId,
      teacherTrackId: teacherTrackId ?? this.teacherTrackId,
      scopeTitle: scopeTitle ?? this.scopeTitle,
      kind: kind ?? this.kind,
      unitId: unitId ?? this.unitId,
      deckId: deckId ?? this.deckId,
      titleAr: titleAr ?? this.titleAr,
      status: status ?? this.status,
      version: version ?? this.version,
      remoteVersion: remoteVersion ?? this.remoteVersion,
      premium: premium ?? this.premium,
      normalizationVersion: normalizationVersion ?? this.normalizationVersion,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packKey.present) {
      map['pack_key'] = Variable<String>(packKey.value);
    }
    if (scopeType.present) {
      map['scope_type'] = Variable<String>(scopeType.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (teacherTrackId.present) {
      map['teacher_track_id'] = Variable<String>(teacherTrackId.value);
    }
    if (scopeTitle.present) {
      map['scope_title'] = Variable<String>(scopeTitle.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (titleAr.present) {
      map['title_ar'] = Variable<String>(titleAr.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (remoteVersion.present) {
      map['remote_version'] = Variable<String>(remoteVersion.value);
    }
    if (premium.present) {
      map['premium'] = Variable<bool>(premium.value);
    }
    if (normalizationVersion.present) {
      map['normalization_version'] = Variable<int>(normalizationVersion.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflinePacksCompanion(')
          ..write('packKey: $packKey, ')
          ..write('scopeType: $scopeType, ')
          ..write('subjectId: $subjectId, ')
          ..write('teacherTrackId: $teacherTrackId, ')
          ..write('scopeTitle: $scopeTitle, ')
          ..write('kind: $kind, ')
          ..write('unitId: $unitId, ')
          ..write('deckId: $deckId, ')
          ..write('titleAr: $titleAr, ')
          ..write('status: $status, ')
          ..write('version: $version, ')
          ..write('remoteVersion: $remoteVersion, ')
          ..write('premium: $premium, ')
          ..write('normalizationVersion: $normalizationVersion, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineItemsTable extends OfflineItems with TableInfo<$OfflineItemsTable, OfflineItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packKeyMeta = const VerificationMeta('packKey');
  @override
  late final GeneratedColumn<String> packKey = GeneratedColumn<String>(
    'pack_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFreeMeta = const VerificationMeta('isFree');
  @override
  late final GeneratedColumn<bool> isFree = GeneratedColumn<bool>(
    'is_free',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_free" IN (0, 1))'),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [packKey, itemId, type, version, isFree, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_items';
  @override
  VerificationContext validateIntegrity(Insertable<OfflineItemRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_key')) {
      context.handle(_packKeyMeta, packKey.isAcceptableOrUnknown(data['pack_key']!, _packKeyMeta));
    } else if (isInserting) {
      context.missing(_packKeyMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta, itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta, version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('is_free')) {
      context.handle(_isFreeMeta, isFree.isAcceptableOrUnknown(data['is_free']!, _isFreeMeta));
    } else if (isInserting) {
      context.missing(_isFreeMeta);
    }
    if (data.containsKey('json')) {
      context.handle(_jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packKey, itemId};
  @override
  OfflineItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineItemRow(
      packKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pack_key'])!,
      itemId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      version: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      isFree: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_free'])!,
      json: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}json'])!,
    );
  }

  @override
  $OfflineItemsTable createAlias(String alias) {
    return $OfflineItemsTable(attachedDatabase, alias);
  }
}

class OfflineItemRow extends DataClass implements Insertable<OfflineItemRow> {
  final String packKey;
  final String itemId;
  final String type;
  final int version;
  final bool isFree;
  final String json;
  const OfflineItemRow({
    required this.packKey,
    required this.itemId,
    required this.type,
    required this.version,
    required this.isFree,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_key'] = Variable<String>(packKey);
    map['item_id'] = Variable<String>(itemId);
    map['type'] = Variable<String>(type);
    map['version'] = Variable<int>(version);
    map['is_free'] = Variable<bool>(isFree);
    map['json'] = Variable<String>(json);
    return map;
  }

  OfflineItemsCompanion toCompanion(bool nullToAbsent) {
    return OfflineItemsCompanion(
      packKey: Value(packKey),
      itemId: Value(itemId),
      type: Value(type),
      version: Value(version),
      isFree: Value(isFree),
      json: Value(json),
    );
  }

  factory OfflineItemRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineItemRow(
      packKey: serializer.fromJson<String>(json['packKey']),
      itemId: serializer.fromJson<String>(json['itemId']),
      type: serializer.fromJson<String>(json['type']),
      version: serializer.fromJson<int>(json['version']),
      isFree: serializer.fromJson<bool>(json['isFree']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packKey': serializer.toJson<String>(packKey),
      'itemId': serializer.toJson<String>(itemId),
      'type': serializer.toJson<String>(type),
      'version': serializer.toJson<int>(version),
      'isFree': serializer.toJson<bool>(isFree),
      'json': serializer.toJson<String>(json),
    };
  }

  OfflineItemRow copyWith({String? packKey, String? itemId, String? type, int? version, bool? isFree, String? json}) =>
      OfflineItemRow(
        packKey: packKey ?? this.packKey,
        itemId: itemId ?? this.itemId,
        type: type ?? this.type,
        version: version ?? this.version,
        isFree: isFree ?? this.isFree,
        json: json ?? this.json,
      );
  OfflineItemRow copyWithCompanion(OfflineItemsCompanion data) {
    return OfflineItemRow(
      packKey: data.packKey.present ? data.packKey.value : this.packKey,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      type: data.type.present ? data.type.value : this.type,
      version: data.version.present ? data.version.value : this.version,
      isFree: data.isFree.present ? data.isFree.value : this.isFree,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineItemRow(')
          ..write('packKey: $packKey, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('isFree: $isFree, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(packKey, itemId, type, version, isFree, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineItemRow &&
          other.packKey == this.packKey &&
          other.itemId == this.itemId &&
          other.type == this.type &&
          other.version == this.version &&
          other.isFree == this.isFree &&
          other.json == this.json);
}

class OfflineItemsCompanion extends UpdateCompanion<OfflineItemRow> {
  final Value<String> packKey;
  final Value<String> itemId;
  final Value<String> type;
  final Value<int> version;
  final Value<bool> isFree;
  final Value<String> json;
  final Value<int> rowid;
  const OfflineItemsCompanion({
    this.packKey = const Value.absent(),
    this.itemId = const Value.absent(),
    this.type = const Value.absent(),
    this.version = const Value.absent(),
    this.isFree = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineItemsCompanion.insert({
    required String packKey,
    required String itemId,
    required String type,
    required int version,
    required bool isFree,
    required String json,
    this.rowid = const Value.absent(),
  }) : packKey = Value(packKey),
       itemId = Value(itemId),
       type = Value(type),
       version = Value(version),
       isFree = Value(isFree),
       json = Value(json);
  static Insertable<OfflineItemRow> custom({
    Expression<String>? packKey,
    Expression<String>? itemId,
    Expression<String>? type,
    Expression<int>? version,
    Expression<bool>? isFree,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packKey != null) 'pack_key': packKey,
      if (itemId != null) 'item_id': itemId,
      if (type != null) 'type': type,
      if (version != null) 'version': version,
      if (isFree != null) 'is_free': isFree,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineItemsCompanion copyWith({
    Value<String>? packKey,
    Value<String>? itemId,
    Value<String>? type,
    Value<int>? version,
    Value<bool>? isFree,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return OfflineItemsCompanion(
      packKey: packKey ?? this.packKey,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      version: version ?? this.version,
      isFree: isFree ?? this.isFree,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packKey.present) {
      map['pack_key'] = Variable<String>(packKey.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isFree.present) {
      map['is_free'] = Variable<bool>(isFree.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineItemsCompanion(')
          ..write('packKey: $packKey, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('isFree: $isFree, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineFilesTable extends OfflineFiles with TableInfo<$OfflineFilesTable, OfflineFileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packKeyMeta = const VerificationMeta('packKey');
  @override
  late final GeneratedColumn<String> packKey = GeneratedColumn<String>(
    'pack_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [packKey, mediaId, version, path, sizeBytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_files';
  @override
  VerificationContext validateIntegrity(Insertable<OfflineFileRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_key')) {
      context.handle(_packKeyMeta, packKey.isAcceptableOrUnknown(data['pack_key']!, _packKeyMeta));
    } else if (isInserting) {
      context.missing(_packKeyMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta, mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta, version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta, sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packKey, mediaId};
  @override
  OfflineFileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineFileRow(
      packKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pack_key'])!,
      mediaId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      version: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      sizeBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
    );
  }

  @override
  $OfflineFilesTable createAlias(String alias) {
    return $OfflineFilesTable(attachedDatabase, alias);
  }
}

class OfflineFileRow extends DataClass implements Insertable<OfflineFileRow> {
  final String packKey;
  final String mediaId;
  final int version;
  final String path;
  final int sizeBytes;
  const OfflineFileRow({
    required this.packKey,
    required this.mediaId,
    required this.version,
    required this.path,
    required this.sizeBytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_key'] = Variable<String>(packKey);
    map['media_id'] = Variable<String>(mediaId);
    map['version'] = Variable<int>(version);
    map['path'] = Variable<String>(path);
    map['size_bytes'] = Variable<int>(sizeBytes);
    return map;
  }

  OfflineFilesCompanion toCompanion(bool nullToAbsent) {
    return OfflineFilesCompanion(
      packKey: Value(packKey),
      mediaId: Value(mediaId),
      version: Value(version),
      path: Value(path),
      sizeBytes: Value(sizeBytes),
    );
  }

  factory OfflineFileRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineFileRow(
      packKey: serializer.fromJson<String>(json['packKey']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      version: serializer.fromJson<int>(json['version']),
      path: serializer.fromJson<String>(json['path']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packKey': serializer.toJson<String>(packKey),
      'mediaId': serializer.toJson<String>(mediaId),
      'version': serializer.toJson<int>(version),
      'path': serializer.toJson<String>(path),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
    };
  }

  OfflineFileRow copyWith({String? packKey, String? mediaId, int? version, String? path, int? sizeBytes}) =>
      OfflineFileRow(
        packKey: packKey ?? this.packKey,
        mediaId: mediaId ?? this.mediaId,
        version: version ?? this.version,
        path: path ?? this.path,
        sizeBytes: sizeBytes ?? this.sizeBytes,
      );
  OfflineFileRow copyWithCompanion(OfflineFilesCompanion data) {
    return OfflineFileRow(
      packKey: data.packKey.present ? data.packKey.value : this.packKey,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      version: data.version.present ? data.version.value : this.version,
      path: data.path.present ? data.path.value : this.path,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineFileRow(')
          ..write('packKey: $packKey, ')
          ..write('mediaId: $mediaId, ')
          ..write('version: $version, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(packKey, mediaId, version, path, sizeBytes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineFileRow &&
          other.packKey == this.packKey &&
          other.mediaId == this.mediaId &&
          other.version == this.version &&
          other.path == this.path &&
          other.sizeBytes == this.sizeBytes);
}

class OfflineFilesCompanion extends UpdateCompanion<OfflineFileRow> {
  final Value<String> packKey;
  final Value<String> mediaId;
  final Value<int> version;
  final Value<String> path;
  final Value<int> sizeBytes;
  final Value<int> rowid;
  const OfflineFilesCompanion({
    this.packKey = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.version = const Value.absent(),
    this.path = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineFilesCompanion.insert({
    required String packKey,
    required String mediaId,
    required int version,
    required String path,
    required int sizeBytes,
    this.rowid = const Value.absent(),
  }) : packKey = Value(packKey),
       mediaId = Value(mediaId),
       version = Value(version),
       path = Value(path),
       sizeBytes = Value(sizeBytes);
  static Insertable<OfflineFileRow> custom({
    Expression<String>? packKey,
    Expression<String>? mediaId,
    Expression<int>? version,
    Expression<String>? path,
    Expression<int>? sizeBytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packKey != null) 'pack_key': packKey,
      if (mediaId != null) 'media_id': mediaId,
      if (version != null) 'version': version,
      if (path != null) 'path': path,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineFilesCompanion copyWith({
    Value<String>? packKey,
    Value<String>? mediaId,
    Value<int>? version,
    Value<String>? path,
    Value<int>? sizeBytes,
    Value<int>? rowid,
  }) {
    return OfflineFilesCompanion(
      packKey: packKey ?? this.packKey,
      mediaId: mediaId ?? this.mediaId,
      version: version ?? this.version,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packKey.present) {
      map['pack_key'] = Variable<String>(packKey.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineFilesCompanion(')
          ..write('packKey: $packKey, ')
          ..write('mediaId: $mediaId, ')
          ..write('version: $version, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineLeaseRowsTable extends OfflineLeaseRows with TableInfo<$OfflineLeaseRowsTable, OfflineLeaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineLeaseRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta('scopeKey');
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshedAtMeta = const VerificationMeta('refreshedAt');
  @override
  late final GeneratedColumn<int> refreshedAt = GeneratedColumn<int>(
    'refreshed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [scopeKey, expiresAt, refreshedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_lease_rows';
  @override
  VerificationContext validateIntegrity(Insertable<OfflineLeaseRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope_key')) {
      context.handle(_scopeKeyMeta, scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta));
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta, expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('refreshed_at')) {
      context.handle(_refreshedAtMeta, refreshedAt.isAcceptableOrUnknown(data['refreshed_at']!, _refreshedAtMeta));
    } else if (isInserting) {
      context.missing(_refreshedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scopeKey};
  @override
  OfflineLeaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineLeaseRow(
      scopeKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}scope_key'])!,
      expiresAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}expires_at'])!,
      refreshedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}refreshed_at'])!,
    );
  }

  @override
  $OfflineLeaseRowsTable createAlias(String alias) {
    return $OfflineLeaseRowsTable(attachedDatabase, alias);
  }
}

class OfflineLeaseRow extends DataClass implements Insertable<OfflineLeaseRow> {
  final String scopeKey;
  final int expiresAt;
  final int refreshedAt;
  const OfflineLeaseRow({required this.scopeKey, required this.expiresAt, required this.refreshedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope_key'] = Variable<String>(scopeKey);
    map['expires_at'] = Variable<int>(expiresAt);
    map['refreshed_at'] = Variable<int>(refreshedAt);
    return map;
  }

  OfflineLeaseRowsCompanion toCompanion(bool nullToAbsent) {
    return OfflineLeaseRowsCompanion(
      scopeKey: Value(scopeKey),
      expiresAt: Value(expiresAt),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory OfflineLeaseRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineLeaseRow(
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
      refreshedAt: serializer.fromJson<int>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scopeKey': serializer.toJson<String>(scopeKey),
      'expiresAt': serializer.toJson<int>(expiresAt),
      'refreshedAt': serializer.toJson<int>(refreshedAt),
    };
  }

  OfflineLeaseRow copyWith({String? scopeKey, int? expiresAt, int? refreshedAt}) => OfflineLeaseRow(
    scopeKey: scopeKey ?? this.scopeKey,
    expiresAt: expiresAt ?? this.expiresAt,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  OfflineLeaseRow copyWithCompanion(OfflineLeaseRowsCompanion data) {
    return OfflineLeaseRow(
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      refreshedAt: data.refreshedAt.present ? data.refreshedAt.value : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineLeaseRow(')
          ..write('scopeKey: $scopeKey, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scopeKey, expiresAt, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineLeaseRow &&
          other.scopeKey == this.scopeKey &&
          other.expiresAt == this.expiresAt &&
          other.refreshedAt == this.refreshedAt);
}

class OfflineLeaseRowsCompanion extends UpdateCompanion<OfflineLeaseRow> {
  final Value<String> scopeKey;
  final Value<int> expiresAt;
  final Value<int> refreshedAt;
  final Value<int> rowid;
  const OfflineLeaseRowsCompanion({
    this.scopeKey = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineLeaseRowsCompanion.insert({
    required String scopeKey,
    required int expiresAt,
    required int refreshedAt,
    this.rowid = const Value.absent(),
  }) : scopeKey = Value(scopeKey),
       expiresAt = Value(expiresAt),
       refreshedAt = Value(refreshedAt);
  static Insertable<OfflineLeaseRow> custom({
    Expression<String>? scopeKey,
    Expression<int>? expiresAt,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scopeKey != null) 'scope_key': scopeKey,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineLeaseRowsCompanion copyWith({
    Value<String>? scopeKey,
    Value<int>? expiresAt,
    Value<int>? refreshedAt,
    Value<int>? rowid,
  }) {
    return OfflineLeaseRowsCompanion(
      scopeKey: scopeKey ?? this.scopeKey,
      expiresAt: expiresAt ?? this.expiresAt,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(refreshedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineLeaseRowsCompanion(')
          ..write('scopeKey: $scopeKey, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAttemptsTable extends LocalAttempts with TableInfo<$LocalAttemptsTable, LocalAttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta('attempt');
  @override
  late final GeneratedColumn<String> attempt = GeneratedColumn<String>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submittedMeta = const VerificationMeta('submitted');
  @override
  late final GeneratedColumn<bool> submitted = GeneratedColumn<bool>(
    'submitted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("submitted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _serverAttemptIdMeta = const VerificationMeta('serverAttemptId');
  @override
  late final GeneratedColumn<String> serverAttemptId = GeneratedColumn<String>(
    'server_attempt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, attempt, payload, submitted, synced, serverAttemptId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_attempts';
  @override
  VerificationContext validateIntegrity(Insertable<LocalAttemptRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(_attemptMeta, attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta));
    } else if (isInserting) {
      context.missing(_attemptMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta, payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('submitted')) {
      context.handle(_submittedMeta, submitted.isAcceptableOrUnknown(data['submitted']!, _submittedMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta, synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('server_attempt_id')) {
      context.handle(
        _serverAttemptIdMeta,
        serverAttemptId.isAcceptableOrUnknown(data['server_attempt_id']!, _serverAttemptIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAttemptRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      attempt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}attempt'])!,
      payload: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload']),
      submitted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}submitted'])!,
      synced: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      serverAttemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_attempt_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalAttemptsTable createAlias(String alias) {
    return $LocalAttemptsTable(attachedDatabase, alias);
  }
}

class LocalAttemptRow extends DataClass implements Insertable<LocalAttemptRow> {
  final String id;
  final String attempt;
  final String? payload;
  final bool submitted;
  final bool synced;
  final String? serverAttemptId;
  final int createdAt;
  const LocalAttemptRow({
    required this.id,
    required this.attempt,
    this.payload,
    required this.submitted,
    required this.synced,
    this.serverAttemptId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['attempt'] = Variable<String>(attempt);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['submitted'] = Variable<bool>(submitted);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || serverAttemptId != null) {
      map['server_attempt_id'] = Variable<String>(serverAttemptId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  LocalAttemptsCompanion toCompanion(bool nullToAbsent) {
    return LocalAttemptsCompanion(
      id: Value(id),
      attempt: Value(attempt),
      payload: payload == null && nullToAbsent ? const Value.absent() : Value(payload),
      submitted: Value(submitted),
      synced: Value(synced),
      serverAttemptId: serverAttemptId == null && nullToAbsent ? const Value.absent() : Value(serverAttemptId),
      createdAt: Value(createdAt),
    );
  }

  factory LocalAttemptRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAttemptRow(
      id: serializer.fromJson<String>(json['id']),
      attempt: serializer.fromJson<String>(json['attempt']),
      payload: serializer.fromJson<String?>(json['payload']),
      submitted: serializer.fromJson<bool>(json['submitted']),
      synced: serializer.fromJson<bool>(json['synced']),
      serverAttemptId: serializer.fromJson<String?>(json['serverAttemptId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'attempt': serializer.toJson<String>(attempt),
      'payload': serializer.toJson<String?>(payload),
      'submitted': serializer.toJson<bool>(submitted),
      'synced': serializer.toJson<bool>(synced),
      'serverAttemptId': serializer.toJson<String?>(serverAttemptId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  LocalAttemptRow copyWith({
    String? id,
    String? attempt,
    Value<String?> payload = const Value.absent(),
    bool? submitted,
    bool? synced,
    Value<String?> serverAttemptId = const Value.absent(),
    int? createdAt,
  }) => LocalAttemptRow(
    id: id ?? this.id,
    attempt: attempt ?? this.attempt,
    payload: payload.present ? payload.value : this.payload,
    submitted: submitted ?? this.submitted,
    synced: synced ?? this.synced,
    serverAttemptId: serverAttemptId.present ? serverAttemptId.value : this.serverAttemptId,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalAttemptRow copyWithCompanion(LocalAttemptsCompanion data) {
    return LocalAttemptRow(
      id: data.id.present ? data.id.value : this.id,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      payload: data.payload.present ? data.payload.value : this.payload,
      submitted: data.submitted.present ? data.submitted.value : this.submitted,
      synced: data.synced.present ? data.synced.value : this.synced,
      serverAttemptId: data.serverAttemptId.present ? data.serverAttemptId.value : this.serverAttemptId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttemptRow(')
          ..write('id: $id, ')
          ..write('attempt: $attempt, ')
          ..write('payload: $payload, ')
          ..write('submitted: $submitted, ')
          ..write('synced: $synced, ')
          ..write('serverAttemptId: $serverAttemptId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, attempt, payload, submitted, synced, serverAttemptId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAttemptRow &&
          other.id == this.id &&
          other.attempt == this.attempt &&
          other.payload == this.payload &&
          other.submitted == this.submitted &&
          other.synced == this.synced &&
          other.serverAttemptId == this.serverAttemptId &&
          other.createdAt == this.createdAt);
}

class LocalAttemptsCompanion extends UpdateCompanion<LocalAttemptRow> {
  final Value<String> id;
  final Value<String> attempt;
  final Value<String?> payload;
  final Value<bool> submitted;
  final Value<bool> synced;
  final Value<String?> serverAttemptId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const LocalAttemptsCompanion({
    this.id = const Value.absent(),
    this.attempt = const Value.absent(),
    this.payload = const Value.absent(),
    this.submitted = const Value.absent(),
    this.synced = const Value.absent(),
    this.serverAttemptId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAttemptsCompanion.insert({
    required String id,
    required String attempt,
    this.payload = const Value.absent(),
    this.submitted = const Value.absent(),
    this.synced = const Value.absent(),
    this.serverAttemptId = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       attempt = Value(attempt),
       createdAt = Value(createdAt);
  static Insertable<LocalAttemptRow> custom({
    Expression<String>? id,
    Expression<String>? attempt,
    Expression<String>? payload,
    Expression<bool>? submitted,
    Expression<bool>? synced,
    Expression<String>? serverAttemptId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attempt != null) 'attempt': attempt,
      if (payload != null) 'payload': payload,
      if (submitted != null) 'submitted': submitted,
      if (synced != null) 'synced': synced,
      if (serverAttemptId != null) 'server_attempt_id': serverAttemptId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAttemptsCompanion copyWith({
    Value<String>? id,
    Value<String>? attempt,
    Value<String?>? payload,
    Value<bool>? submitted,
    Value<bool>? synced,
    Value<String?>? serverAttemptId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalAttemptsCompanion(
      id: id ?? this.id,
      attempt: attempt ?? this.attempt,
      payload: payload ?? this.payload,
      submitted: submitted ?? this.submitted,
      synced: synced ?? this.synced,
      serverAttemptId: serverAttemptId ?? this.serverAttemptId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<String>(attempt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (submitted.present) {
      map['submitted'] = Variable<bool>(submitted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (serverAttemptId.present) {
      map['server_attempt_id'] = Variable<String>(serverAttemptId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('attempt: $attempt, ')
          ..write('payload: $payload, ')
          ..write('submitted: $submitted, ')
          ..write('synced: $synced, ')
          ..write('serverAttemptId: $serverAttemptId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMistakesTable extends LocalMistakes with TableInfo<$LocalMistakesTable, LocalMistakeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMistakesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wrongAtMeta = const VerificationMeta('wrongAt');
  @override
  late final GeneratedColumn<int> wrongAt = GeneratedColumn<int>(
    'wrong_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [questionId, wrongAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_mistakes';
  @override
  VerificationContext validateIntegrity(Insertable<LocalMistakeRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(_questionIdMeta, questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('wrong_at')) {
      context.handle(_wrongAtMeta, wrongAt.isAcceptableOrUnknown(data['wrong_at']!, _wrongAtMeta));
    } else if (isInserting) {
      context.missing(_wrongAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  LocalMistakeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMistakeRow(
      questionId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      wrongAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}wrong_at'])!,
    );
  }

  @override
  $LocalMistakesTable createAlias(String alias) {
    return $LocalMistakesTable(attachedDatabase, alias);
  }
}

class LocalMistakeRow extends DataClass implements Insertable<LocalMistakeRow> {
  final String questionId;
  final int wrongAt;
  const LocalMistakeRow({required this.questionId, required this.wrongAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    map['wrong_at'] = Variable<int>(wrongAt);
    return map;
  }

  LocalMistakesCompanion toCompanion(bool nullToAbsent) {
    return LocalMistakesCompanion(questionId: Value(questionId), wrongAt: Value(wrongAt));
  }

  factory LocalMistakeRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMistakeRow(
      questionId: serializer.fromJson<String>(json['questionId']),
      wrongAt: serializer.fromJson<int>(json['wrongAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'wrongAt': serializer.toJson<int>(wrongAt),
    };
  }

  LocalMistakeRow copyWith({String? questionId, int? wrongAt}) =>
      LocalMistakeRow(questionId: questionId ?? this.questionId, wrongAt: wrongAt ?? this.wrongAt);
  LocalMistakeRow copyWithCompanion(LocalMistakesCompanion data) {
    return LocalMistakeRow(
      questionId: data.questionId.present ? data.questionId.value : this.questionId,
      wrongAt: data.wrongAt.present ? data.wrongAt.value : this.wrongAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMistakeRow(')
          ..write('questionId: $questionId, ')
          ..write('wrongAt: $wrongAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(questionId, wrongAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMistakeRow && other.questionId == this.questionId && other.wrongAt == this.wrongAt);
}

class LocalMistakesCompanion extends UpdateCompanion<LocalMistakeRow> {
  final Value<String> questionId;
  final Value<int> wrongAt;
  final Value<int> rowid;
  const LocalMistakesCompanion({
    this.questionId = const Value.absent(),
    this.wrongAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMistakesCompanion.insert({required String questionId, required int wrongAt, this.rowid = const Value.absent()})
    : questionId = Value(questionId),
      wrongAt = Value(wrongAt);
  static Insertable<LocalMistakeRow> custom({
    Expression<String>? questionId,
    Expression<int>? wrongAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (wrongAt != null) 'wrong_at': wrongAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMistakesCompanion copyWith({Value<String>? questionId, Value<int>? wrongAt, Value<int>? rowid}) {
    return LocalMistakesCompanion(
      questionId: questionId ?? this.questionId,
      wrongAt: wrongAt ?? this.wrongAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (wrongAt.present) {
      map['wrong_at'] = Variable<int>(wrongAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMistakesCompanion(')
          ..write('questionId: $questionId, ')
          ..write('wrongAt: $wrongAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $SrsCardStatesTable srsCardStates = $SrsCardStatesTable(this);
  late final $SrsReviewLogsTable srsReviewLogs = $SrsReviewLogsTable(this);
  late final $ExamDraftsTable examDrafts = $ExamDraftsTable(this);
  late final $ExamAnswersTable examAnswers = $ExamAnswersTable(this);
  late final $LocalDecksTable localDecks = $LocalDecksTable(this);
  late final $LocalCardsTable localCards = $LocalCardsTable(this);
  late final $OfflinePacksTable offlinePacks = $OfflinePacksTable(this);
  late final $OfflineItemsTable offlineItems = $OfflineItemsTable(this);
  late final $OfflineFilesTable offlineFiles = $OfflineFilesTable(this);
  late final $OfflineLeaseRowsTable offlineLeaseRows = $OfflineLeaseRowsTable(this);
  late final $LocalAttemptsTable localAttempts = $LocalAttemptsTable(this);
  late final $LocalMistakesTable localMistakes = $LocalMistakesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValues,
    srsCardStates,
    srsReviewLogs,
    examDrafts,
    examAnswers,
    localDecks,
    localCards,
    offlinePacks,
    offlineItems,
    offlineFiles,
    offlineLeaseRows,
    localAttempts,
    localMistakes,
  ];
}

typedef $$KeyValuesTableCreateCompanionBuilder =
    KeyValuesCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$KeyValuesTableUpdateCompanionBuilder =
    KeyValuesCompanion Function({Value<String> key, Value<String> value, Value<DateTime> updatedAt, Value<int> rowid});

class $$KeyValuesTableFilterComposer extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$KeyValuesTableOrderingComposer extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$KeyValuesTableAnnotationComposer extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion(key: key, value: value, updatedAt: updatedAt, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion.insert(key: key, value: value, updatedAt: updatedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;
typedef $$SrsCardStatesTableCreateCompanionBuilder =
    SrsCardStatesCompanion Function({
      required String flashcardId,
      required String state,
      required int step,
      required int dueAt,
      required int intervalDays,
      required double ease,
      required int reps,
      required int lapses,
      Value<int?> lastReviewedAt,
      Value<int> rowid,
    });
typedef $$SrsCardStatesTableUpdateCompanionBuilder =
    SrsCardStatesCompanion Function({
      Value<String> flashcardId,
      Value<String> state,
      Value<int> step,
      Value<int> dueAt,
      Value<int> intervalDays,
      Value<double> ease,
      Value<int> reps,
      Value<int> lapses,
      Value<int?> lastReviewedAt,
      Value<int> rowid,
    });

class $$SrsCardStatesTableFilterComposer extends Composer<_$AppDatabase, $SrsCardStatesTable> {
  $$SrsCardStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get flashcardId =>
      $composableBuilder(column: $table.flashcardId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get step => $composableBuilder(column: $table.step, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueAt => $composableBuilder(column: $table.dueAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intervalDays =>
      $composableBuilder(column: $table.intervalDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ease => $composableBuilder(column: $table.ease, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastReviewedAt =>
      $composableBuilder(column: $table.lastReviewedAt, builder: (column) => ColumnFilters(column));
}

class $$SrsCardStatesTableOrderingComposer extends Composer<_$AppDatabase, $SrsCardStatesTable> {
  $$SrsCardStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get flashcardId =>
      $composableBuilder(column: $table.flashcardId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intervalDays =>
      $composableBuilder(column: $table.intervalDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastReviewedAt =>
      $composableBuilder(column: $table.lastReviewedAt, builder: (column) => ColumnOrderings(column));
}

class $$SrsCardStatesTableAnnotationComposer extends Composer<_$AppDatabase, $SrsCardStatesTable> {
  $$SrsCardStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get flashcardId =>
      $composableBuilder(column: $table.flashcardId, builder: (column) => column);

  GeneratedColumn<String> get state => $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step => $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<int> get dueAt => $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(column: $table.intervalDays, builder: (column) => column);

  GeneratedColumn<double> get ease => $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<int> get reps => $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses => $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get lastReviewedAt =>
      $composableBuilder(column: $table.lastReviewedAt, builder: (column) => column);
}

class $$SrsCardStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SrsCardStatesTable,
          SrsCardState,
          $$SrsCardStatesTableFilterComposer,
          $$SrsCardStatesTableOrderingComposer,
          $$SrsCardStatesTableAnnotationComposer,
          $$SrsCardStatesTableCreateCompanionBuilder,
          $$SrsCardStatesTableUpdateCompanionBuilder,
          (SrsCardState, BaseReferences<_$AppDatabase, $SrsCardStatesTable, SrsCardState>),
          SrsCardState,
          PrefetchHooks Function()
        > {
  $$SrsCardStatesTableTableManager(_$AppDatabase db, $SrsCardStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SrsCardStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SrsCardStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SrsCardStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> flashcardId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> step = const Value.absent(),
                Value<int> dueAt = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int?> lastReviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SrsCardStatesCompanion(
                flashcardId: flashcardId,
                state: state,
                step: step,
                dueAt: dueAt,
                intervalDays: intervalDays,
                ease: ease,
                reps: reps,
                lapses: lapses,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String flashcardId,
                required String state,
                required int step,
                required int dueAt,
                required int intervalDays,
                required double ease,
                required int reps,
                required int lapses,
                Value<int?> lastReviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SrsCardStatesCompanion.insert(
                flashcardId: flashcardId,
                state: state,
                step: step,
                dueAt: dueAt,
                intervalDays: intervalDays,
                ease: ease,
                reps: reps,
                lapses: lapses,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SrsCardStatesTable, SrsCardState>(table),
                  BaseReferences<_$AppDatabase, $SrsCardStatesTable, SrsCardState>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SrsCardStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SrsCardStatesTable,
      SrsCardState,
      $$SrsCardStatesTableFilterComposer,
      $$SrsCardStatesTableOrderingComposer,
      $$SrsCardStatesTableAnnotationComposer,
      $$SrsCardStatesTableCreateCompanionBuilder,
      $$SrsCardStatesTableUpdateCompanionBuilder,
      (SrsCardState, BaseReferences<_$AppDatabase, $SrsCardStatesTable, SrsCardState>),
      SrsCardState,
      PrefetchHooks Function()
    >;
typedef $$SrsReviewLogsTableCreateCompanionBuilder =
    SrsReviewLogsCompanion Function({
      required String id,
      required String flashcardId,
      required String rating,
      required String before,
      required String after,
      required int reviewedAt,
      Value<int?> durationMs,
      Value<bool> undone,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$SrsReviewLogsTableUpdateCompanionBuilder =
    SrsReviewLogsCompanion Function({
      Value<String> id,
      Value<String> flashcardId,
      Value<String> rating,
      Value<String> before,
      Value<String> after,
      Value<int> reviewedAt,
      Value<int?> durationMs,
      Value<bool> undone,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$SrsReviewLogsTableFilterComposer extends Composer<_$AppDatabase, $SrsReviewLogsTable> {
  $$SrsReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get flashcardId =>
      $composableBuilder(column: $table.flashcardId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get before =>
      $composableBuilder(column: $table.before, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get after =>
      $composableBuilder(column: $table.after, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewedAt =>
      $composableBuilder(column: $table.reviewedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get undone =>
      $composableBuilder(column: $table.undone, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$SrsReviewLogsTableOrderingComposer extends Composer<_$AppDatabase, $SrsReviewLogsTable> {
  $$SrsReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get flashcardId =>
      $composableBuilder(column: $table.flashcardId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get before =>
      $composableBuilder(column: $table.before, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get after =>
      $composableBuilder(column: $table.after, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewedAt =>
      $composableBuilder(column: $table.reviewedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get undone =>
      $composableBuilder(column: $table.undone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$SrsReviewLogsTableAnnotationComposer extends Composer<_$AppDatabase, $SrsReviewLogsTable> {
  $$SrsReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get flashcardId =>
      $composableBuilder(column: $table.flashcardId, builder: (column) => column);

  GeneratedColumn<String> get rating => $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get before => $composableBuilder(column: $table.before, builder: (column) => column);

  GeneratedColumn<String> get after => $composableBuilder(column: $table.after, builder: (column) => column);

  GeneratedColumn<int> get reviewedAt => $composableBuilder(column: $table.reviewedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<bool> get undone => $composableBuilder(column: $table.undone, builder: (column) => column);

  GeneratedColumn<bool> get synced => $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$SrsReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SrsReviewLogsTable,
          SrsReviewLog,
          $$SrsReviewLogsTableFilterComposer,
          $$SrsReviewLogsTableOrderingComposer,
          $$SrsReviewLogsTableAnnotationComposer,
          $$SrsReviewLogsTableCreateCompanionBuilder,
          $$SrsReviewLogsTableUpdateCompanionBuilder,
          (SrsReviewLog, BaseReferences<_$AppDatabase, $SrsReviewLogsTable, SrsReviewLog>),
          SrsReviewLog,
          PrefetchHooks Function()
        > {
  $$SrsReviewLogsTableTableManager(_$AppDatabase db, $SrsReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SrsReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SrsReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SrsReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> flashcardId = const Value.absent(),
                Value<String> rating = const Value.absent(),
                Value<String> before = const Value.absent(),
                Value<String> after = const Value.absent(),
                Value<int> reviewedAt = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> undone = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SrsReviewLogsCompanion(
                id: id,
                flashcardId: flashcardId,
                rating: rating,
                before: before,
                after: after,
                reviewedAt: reviewedAt,
                durationMs: durationMs,
                undone: undone,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String flashcardId,
                required String rating,
                required String before,
                required String after,
                required int reviewedAt,
                Value<int?> durationMs = const Value.absent(),
                Value<bool> undone = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SrsReviewLogsCompanion.insert(
                id: id,
                flashcardId: flashcardId,
                rating: rating,
                before: before,
                after: after,
                reviewedAt: reviewedAt,
                durationMs: durationMs,
                undone: undone,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SrsReviewLogsTable, SrsReviewLog>(table),
                  BaseReferences<_$AppDatabase, $SrsReviewLogsTable, SrsReviewLog>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SrsReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SrsReviewLogsTable,
      SrsReviewLog,
      $$SrsReviewLogsTableFilterComposer,
      $$SrsReviewLogsTableOrderingComposer,
      $$SrsReviewLogsTableAnnotationComposer,
      $$SrsReviewLogsTableCreateCompanionBuilder,
      $$SrsReviewLogsTableUpdateCompanionBuilder,
      (SrsReviewLog, BaseReferences<_$AppDatabase, $SrsReviewLogsTable, SrsReviewLog>),
      SrsReviewLog,
      PrefetchHooks Function()
    >;
typedef $$ExamDraftsTableCreateCompanionBuilder =
    ExamDraftsCompanion Function({
      required String attemptId,
      required String attempt,
      Value<bool> submitPending,
      Value<int?> timeSpentMs,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ExamDraftsTableUpdateCompanionBuilder =
    ExamDraftsCompanion Function({
      Value<String> attemptId,
      Value<String> attempt,
      Value<bool> submitPending,
      Value<int?> timeSpentMs,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ExamDraftsTableFilterComposer extends Composer<_$AppDatabase, $ExamDraftsTable> {
  $$ExamDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get submitPending =>
      $composableBuilder(column: $table.submitPending, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeSpentMs =>
      $composableBuilder(column: $table.timeSpentMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ExamDraftsTableOrderingComposer extends Composer<_$AppDatabase, $ExamDraftsTable> {
  $$ExamDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get submitPending =>
      $composableBuilder(column: $table.submitPending, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeSpentMs =>
      $composableBuilder(column: $table.timeSpentMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ExamDraftsTableAnnotationComposer extends Composer<_$AppDatabase, $ExamDraftsTable> {
  $$ExamDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attemptId => $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<String> get attempt => $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<bool> get submitPending =>
      $composableBuilder(column: $table.submitPending, builder: (column) => column);

  GeneratedColumn<int> get timeSpentMs => $composableBuilder(column: $table.timeSpentMs, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ExamDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExamDraftsTable,
          ExamDraftRow,
          $$ExamDraftsTableFilterComposer,
          $$ExamDraftsTableOrderingComposer,
          $$ExamDraftsTableAnnotationComposer,
          $$ExamDraftsTableCreateCompanionBuilder,
          $$ExamDraftsTableUpdateCompanionBuilder,
          (ExamDraftRow, BaseReferences<_$AppDatabase, $ExamDraftsTable, ExamDraftRow>),
          ExamDraftRow,
          PrefetchHooks Function()
        > {
  $$ExamDraftsTableTableManager(_$AppDatabase db, $ExamDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ExamDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ExamDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ExamDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> attemptId = const Value.absent(),
                Value<String> attempt = const Value.absent(),
                Value<bool> submitPending = const Value.absent(),
                Value<int?> timeSpentMs = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamDraftsCompanion(
                attemptId: attemptId,
                attempt: attempt,
                submitPending: submitPending,
                timeSpentMs: timeSpentMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attemptId,
                required String attempt,
                Value<bool> submitPending = const Value.absent(),
                Value<int?> timeSpentMs = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExamDraftsCompanion.insert(
                attemptId: attemptId,
                attempt: attempt,
                submitPending: submitPending,
                timeSpentMs: timeSpentMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExamDraftsTable, ExamDraftRow>(table),
                  BaseReferences<_$AppDatabase, $ExamDraftsTable, ExamDraftRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExamDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExamDraftsTable,
      ExamDraftRow,
      $$ExamDraftsTableFilterComposer,
      $$ExamDraftsTableOrderingComposer,
      $$ExamDraftsTableAnnotationComposer,
      $$ExamDraftsTableCreateCompanionBuilder,
      $$ExamDraftsTableUpdateCompanionBuilder,
      (ExamDraftRow, BaseReferences<_$AppDatabase, $ExamDraftsTable, ExamDraftRow>),
      ExamDraftRow,
      PrefetchHooks Function()
    >;
typedef $$ExamAnswersTableCreateCompanionBuilder =
    ExamAnswersCompanion Function({
      required String attemptId,
      required String questionId,
      Value<String?> selectedOptionId,
      Value<String?> writtenAnswer,
      Value<bool> flagged,
      Value<int?> timeSpentMs,
      Value<bool> dirty,
      Value<int> rowid,
    });
typedef $$ExamAnswersTableUpdateCompanionBuilder =
    ExamAnswersCompanion Function({
      Value<String> attemptId,
      Value<String> questionId,
      Value<String?> selectedOptionId,
      Value<String?> writtenAnswer,
      Value<bool> flagged,
      Value<int?> timeSpentMs,
      Value<bool> dirty,
      Value<int> rowid,
    });

class $$ExamAnswersTableFilterComposer extends Composer<_$AppDatabase, $ExamAnswersTable> {
  $$ExamAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId =>
      $composableBuilder(column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selectedOptionId =>
      $composableBuilder(column: $table.selectedOptionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get writtenAnswer =>
      $composableBuilder(column: $table.writtenAnswer, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get flagged =>
      $composableBuilder(column: $table.flagged, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeSpentMs =>
      $composableBuilder(column: $table.timeSpentMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$ExamAnswersTableOrderingComposer extends Composer<_$AppDatabase, $ExamAnswersTable> {
  $$ExamAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId =>
      $composableBuilder(column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selectedOptionId =>
      $composableBuilder(column: $table.selectedOptionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get writtenAnswer =>
      $composableBuilder(column: $table.writtenAnswer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get flagged =>
      $composableBuilder(column: $table.flagged, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeSpentMs =>
      $composableBuilder(column: $table.timeSpentMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$ExamAnswersTableAnnotationComposer extends Composer<_$AppDatabase, $ExamAnswersTable> {
  $$ExamAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attemptId => $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(column: $table.questionId, builder: (column) => column);

  GeneratedColumn<String> get selectedOptionId =>
      $composableBuilder(column: $table.selectedOptionId, builder: (column) => column);

  GeneratedColumn<String> get writtenAnswer =>
      $composableBuilder(column: $table.writtenAnswer, builder: (column) => column);

  GeneratedColumn<bool> get flagged => $composableBuilder(column: $table.flagged, builder: (column) => column);

  GeneratedColumn<int> get timeSpentMs => $composableBuilder(column: $table.timeSpentMs, builder: (column) => column);

  GeneratedColumn<bool> get dirty => $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$ExamAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExamAnswersTable,
          ExamAnswerRow,
          $$ExamAnswersTableFilterComposer,
          $$ExamAnswersTableOrderingComposer,
          $$ExamAnswersTableAnnotationComposer,
          $$ExamAnswersTableCreateCompanionBuilder,
          $$ExamAnswersTableUpdateCompanionBuilder,
          (ExamAnswerRow, BaseReferences<_$AppDatabase, $ExamAnswersTable, ExamAnswerRow>),
          ExamAnswerRow,
          PrefetchHooks Function()
        > {
  $$ExamAnswersTableTableManager(_$AppDatabase db, $ExamAnswersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ExamAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ExamAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ExamAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> attemptId = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String?> selectedOptionId = const Value.absent(),
                Value<String?> writtenAnswer = const Value.absent(),
                Value<bool> flagged = const Value.absent(),
                Value<int?> timeSpentMs = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamAnswersCompanion(
                attemptId: attemptId,
                questionId: questionId,
                selectedOptionId: selectedOptionId,
                writtenAnswer: writtenAnswer,
                flagged: flagged,
                timeSpentMs: timeSpentMs,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attemptId,
                required String questionId,
                Value<String?> selectedOptionId = const Value.absent(),
                Value<String?> writtenAnswer = const Value.absent(),
                Value<bool> flagged = const Value.absent(),
                Value<int?> timeSpentMs = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamAnswersCompanion.insert(
                attemptId: attemptId,
                questionId: questionId,
                selectedOptionId: selectedOptionId,
                writtenAnswer: writtenAnswer,
                flagged: flagged,
                timeSpentMs: timeSpentMs,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExamAnswersTable, ExamAnswerRow>(table),
                  BaseReferences<_$AppDatabase, $ExamAnswersTable, ExamAnswerRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExamAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExamAnswersTable,
      ExamAnswerRow,
      $$ExamAnswersTableFilterComposer,
      $$ExamAnswersTableOrderingComposer,
      $$ExamAnswersTableAnnotationComposer,
      $$ExamAnswersTableCreateCompanionBuilder,
      $$ExamAnswersTableUpdateCompanionBuilder,
      (ExamAnswerRow, BaseReferences<_$AppDatabase, $ExamAnswersTable, ExamAnswerRow>),
      ExamAnswerRow,
      PrefetchHooks Function()
    >;
typedef $$LocalDecksTableCreateCompanionBuilder =
    LocalDecksCompanion Function({
      required String id,
      required String name,
      Value<String?> subjectId,
      Value<String?> color,
      required int sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });
typedef $$LocalDecksTableUpdateCompanionBuilder =
    LocalDecksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> subjectId,
      Value<String?> color,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });

class $$LocalDecksTableFilterComposer extends Composer<_$AppDatabase, $LocalDecksTable> {
  $$LocalDecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$LocalDecksTableOrderingComposer extends Composer<_$AppDatabase, $LocalDecksTable> {
  $$LocalDecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$LocalDecksTableAnnotationComposer extends Composer<_$AppDatabase, $LocalDecksTable> {
  $$LocalDecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get subjectId => $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty => $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$LocalDecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDecksTable,
          LocalDeckRow,
          $$LocalDecksTableFilterComposer,
          $$LocalDecksTableOrderingComposer,
          $$LocalDecksTableAnnotationComposer,
          $$LocalDecksTableCreateCompanionBuilder,
          $$LocalDecksTableUpdateCompanionBuilder,
          (LocalDeckRow, BaseReferences<_$AppDatabase, $LocalDecksTable, LocalDeckRow>),
          LocalDeckRow,
          PrefetchHooks Function()
        > {
  $$LocalDecksTableTableManager(_$AppDatabase db, $LocalDecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalDecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalDecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalDecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDecksCompanion(
                id: id,
                name: name,
                subjectId: subjectId,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> subjectId = const Value.absent(),
                Value<String?> color = const Value.absent(),
                required int sortOrder,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDecksCompanion.insert(
                id: id,
                name: name,
                subjectId: subjectId,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalDecksTable, LocalDeckRow>(table),
                  BaseReferences<_$AppDatabase, $LocalDecksTable, LocalDeckRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDecksTable,
      LocalDeckRow,
      $$LocalDecksTableFilterComposer,
      $$LocalDecksTableOrderingComposer,
      $$LocalDecksTableAnnotationComposer,
      $$LocalDecksTableCreateCompanionBuilder,
      $$LocalDecksTableUpdateCompanionBuilder,
      (LocalDeckRow, BaseReferences<_$AppDatabase, $LocalDecksTable, LocalDeckRow>),
      LocalDeckRow,
      PrefetchHooks Function()
    >;
typedef $$LocalCardsTableCreateCompanionBuilder =
    LocalCardsCompanion Function({
      required String id,
      required String deckId,
      required String kind,
      Value<String?> officialFlashcardId,
      Value<String?> frontText,
      Value<String?> backText,
      Value<String?> frontMediaId,
      Value<String?> backMediaId,
      Value<String?> frontImageJson,
      Value<String?> backImageJson,
      Value<Uint8List?> frontLocalImage,
      Value<Uint8List?> backLocalImage,
      Value<bool> locked,
      required int sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });
typedef $$LocalCardsTableUpdateCompanionBuilder =
    LocalCardsCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> kind,
      Value<String?> officialFlashcardId,
      Value<String?> frontText,
      Value<String?> backText,
      Value<String?> frontMediaId,
      Value<String?> backMediaId,
      Value<String?> frontImageJson,
      Value<String?> backImageJson,
      Value<Uint8List?> frontLocalImage,
      Value<Uint8List?> backLocalImage,
      Value<bool> locked,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<bool> dirty,
      Value<int> rowid,
    });

class $$LocalCardsTableFilterComposer extends Composer<_$AppDatabase, $LocalCardsTable> {
  $$LocalCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get officialFlashcardId =>
      $composableBuilder(column: $table.officialFlashcardId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frontText =>
      $composableBuilder(column: $table.frontText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backText =>
      $composableBuilder(column: $table.backText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frontMediaId =>
      $composableBuilder(column: $table.frontMediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backMediaId =>
      $composableBuilder(column: $table.backMediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frontImageJson =>
      $composableBuilder(column: $table.frontImageJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backImageJson =>
      $composableBuilder(column: $table.backImageJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get frontLocalImage =>
      $composableBuilder(column: $table.frontLocalImage, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get backLocalImage =>
      $composableBuilder(column: $table.backLocalImage, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$LocalCardsTableOrderingComposer extends Composer<_$AppDatabase, $LocalCardsTable> {
  $$LocalCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get officialFlashcardId =>
      $composableBuilder(column: $table.officialFlashcardId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frontText =>
      $composableBuilder(column: $table.frontText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backText =>
      $composableBuilder(column: $table.backText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frontMediaId =>
      $composableBuilder(column: $table.frontMediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backMediaId =>
      $composableBuilder(column: $table.backMediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frontImageJson =>
      $composableBuilder(column: $table.frontImageJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backImageJson =>
      $composableBuilder(column: $table.backImageJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get frontLocalImage =>
      $composableBuilder(column: $table.frontLocalImage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get backLocalImage =>
      $composableBuilder(column: $table.backLocalImage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$LocalCardsTableAnnotationComposer extends Composer<_$AppDatabase, $LocalCardsTable> {
  $$LocalCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deckId => $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get officialFlashcardId =>
      $composableBuilder(column: $table.officialFlashcardId, builder: (column) => column);

  GeneratedColumn<String> get frontText => $composableBuilder(column: $table.frontText, builder: (column) => column);

  GeneratedColumn<String> get backText => $composableBuilder(column: $table.backText, builder: (column) => column);

  GeneratedColumn<String> get frontMediaId =>
      $composableBuilder(column: $table.frontMediaId, builder: (column) => column);

  GeneratedColumn<String> get backMediaId =>
      $composableBuilder(column: $table.backMediaId, builder: (column) => column);

  GeneratedColumn<String> get frontImageJson =>
      $composableBuilder(column: $table.frontImageJson, builder: (column) => column);

  GeneratedColumn<String> get backImageJson =>
      $composableBuilder(column: $table.backImageJson, builder: (column) => column);

  GeneratedColumn<Uint8List> get frontLocalImage =>
      $composableBuilder(column: $table.frontLocalImage, builder: (column) => column);

  GeneratedColumn<Uint8List> get backLocalImage =>
      $composableBuilder(column: $table.backLocalImage, builder: (column) => column);

  GeneratedColumn<bool> get locked => $composableBuilder(column: $table.locked, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty => $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$LocalCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCardsTable,
          LocalCardRow,
          $$LocalCardsTableFilterComposer,
          $$LocalCardsTableOrderingComposer,
          $$LocalCardsTableAnnotationComposer,
          $$LocalCardsTableCreateCompanionBuilder,
          $$LocalCardsTableUpdateCompanionBuilder,
          (LocalCardRow, BaseReferences<_$AppDatabase, $LocalCardsTable, LocalCardRow>),
          LocalCardRow,
          PrefetchHooks Function()
        > {
  $$LocalCardsTableTableManager(_$AppDatabase db, $LocalCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> officialFlashcardId = const Value.absent(),
                Value<String?> frontText = const Value.absent(),
                Value<String?> backText = const Value.absent(),
                Value<String?> frontMediaId = const Value.absent(),
                Value<String?> backMediaId = const Value.absent(),
                Value<String?> frontImageJson = const Value.absent(),
                Value<String?> backImageJson = const Value.absent(),
                Value<Uint8List?> frontLocalImage = const Value.absent(),
                Value<Uint8List?> backLocalImage = const Value.absent(),
                Value<bool> locked = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCardsCompanion(
                id: id,
                deckId: deckId,
                kind: kind,
                officialFlashcardId: officialFlashcardId,
                frontText: frontText,
                backText: backText,
                frontMediaId: frontMediaId,
                backMediaId: backMediaId,
                frontImageJson: frontImageJson,
                backImageJson: backImageJson,
                frontLocalImage: frontLocalImage,
                backLocalImage: backLocalImage,
                locked: locked,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String kind,
                Value<String?> officialFlashcardId = const Value.absent(),
                Value<String?> frontText = const Value.absent(),
                Value<String?> backText = const Value.absent(),
                Value<String?> frontMediaId = const Value.absent(),
                Value<String?> backMediaId = const Value.absent(),
                Value<String?> frontImageJson = const Value.absent(),
                Value<String?> backImageJson = const Value.absent(),
                Value<Uint8List?> frontLocalImage = const Value.absent(),
                Value<Uint8List?> backLocalImage = const Value.absent(),
                Value<bool> locked = const Value.absent(),
                required int sortOrder,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCardsCompanion.insert(
                id: id,
                deckId: deckId,
                kind: kind,
                officialFlashcardId: officialFlashcardId,
                frontText: frontText,
                backText: backText,
                frontMediaId: frontMediaId,
                backMediaId: backMediaId,
                frontImageJson: frontImageJson,
                backImageJson: backImageJson,
                frontLocalImage: frontLocalImage,
                backLocalImage: backLocalImage,
                locked: locked,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalCardsTable, LocalCardRow>(table),
                  BaseReferences<_$AppDatabase, $LocalCardsTable, LocalCardRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCardsTable,
      LocalCardRow,
      $$LocalCardsTableFilterComposer,
      $$LocalCardsTableOrderingComposer,
      $$LocalCardsTableAnnotationComposer,
      $$LocalCardsTableCreateCompanionBuilder,
      $$LocalCardsTableUpdateCompanionBuilder,
      (LocalCardRow, BaseReferences<_$AppDatabase, $LocalCardsTable, LocalCardRow>),
      LocalCardRow,
      PrefetchHooks Function()
    >;
typedef $$OfflinePacksTableCreateCompanionBuilder =
    OfflinePacksCompanion Function({
      required String packKey,
      required String scopeType,
      Value<String?> subjectId,
      Value<String?> teacherTrackId,
      required String scopeTitle,
      required String kind,
      Value<String?> unitId,
      Value<String?> deckId,
      required String titleAr,
      required String status,
      Value<String?> version,
      Value<String?> remoteVersion,
      Value<bool> premium,
      Value<int?> normalizationVersion,
      Value<int> sizeBytes,
      Value<int> downloadedBytes,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$OfflinePacksTableUpdateCompanionBuilder =
    OfflinePacksCompanion Function({
      Value<String> packKey,
      Value<String> scopeType,
      Value<String?> subjectId,
      Value<String?> teacherTrackId,
      Value<String> scopeTitle,
      Value<String> kind,
      Value<String?> unitId,
      Value<String?> deckId,
      Value<String> titleAr,
      Value<String> status,
      Value<String?> version,
      Value<String?> remoteVersion,
      Value<bool> premium,
      Value<int?> normalizationVersion,
      Value<int> sizeBytes,
      Value<int> downloadedBytes,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$OfflinePacksTableFilterComposer extends Composer<_$AppDatabase, $OfflinePacksTable> {
  $$OfflinePacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packKey =>
      $composableBuilder(column: $table.packKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scopeType =>
      $composableBuilder(column: $table.scopeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teacherTrackId =>
      $composableBuilder(column: $table.teacherTrackId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scopeTitle =>
      $composableBuilder(column: $table.scopeTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteVersion =>
      $composableBuilder(column: $table.remoteVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get premium =>
      $composableBuilder(column: $table.premium, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get normalizationVersion =>
      $composableBuilder(column: $table.normalizationVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedBytes =>
      $composableBuilder(column: $table.downloadedBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OfflinePacksTableOrderingComposer extends Composer<_$AppDatabase, $OfflinePacksTable> {
  $$OfflinePacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packKey =>
      $composableBuilder(column: $table.packKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scopeType =>
      $composableBuilder(column: $table.scopeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teacherTrackId =>
      $composableBuilder(column: $table.teacherTrackId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scopeTitle =>
      $composableBuilder(column: $table.scopeTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteVersion =>
      $composableBuilder(column: $table.remoteVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get premium =>
      $composableBuilder(column: $table.premium, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get normalizationVersion =>
      $composableBuilder(column: $table.normalizationVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedBytes =>
      $composableBuilder(column: $table.downloadedBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OfflinePacksTableAnnotationComposer extends Composer<_$AppDatabase, $OfflinePacksTable> {
  $$OfflinePacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packKey => $composableBuilder(column: $table.packKey, builder: (column) => column);

  GeneratedColumn<String> get scopeType => $composableBuilder(column: $table.scopeType, builder: (column) => column);

  GeneratedColumn<String> get subjectId => $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get teacherTrackId =>
      $composableBuilder(column: $table.teacherTrackId, builder: (column) => column);

  GeneratedColumn<String> get scopeTitle => $composableBuilder(column: $table.scopeTitle, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get unitId => $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get deckId => $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<String> get titleAr => $composableBuilder(column: $table.titleAr, builder: (column) => column);

  GeneratedColumn<String> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get version => $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get remoteVersion =>
      $composableBuilder(column: $table.remoteVersion, builder: (column) => column);

  GeneratedColumn<bool> get premium => $composableBuilder(column: $table.premium, builder: (column) => column);

  GeneratedColumn<int> get normalizationVersion =>
      $composableBuilder(column: $table.normalizationVersion, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes => $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes =>
      $composableBuilder(column: $table.downloadedBytes, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OfflinePacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflinePacksTable,
          OfflinePackRow,
          $$OfflinePacksTableFilterComposer,
          $$OfflinePacksTableOrderingComposer,
          $$OfflinePacksTableAnnotationComposer,
          $$OfflinePacksTableCreateCompanionBuilder,
          $$OfflinePacksTableUpdateCompanionBuilder,
          (OfflinePackRow, BaseReferences<_$AppDatabase, $OfflinePacksTable, OfflinePackRow>),
          OfflinePackRow,
          PrefetchHooks Function()
        > {
  $$OfflinePacksTableTableManager(_$AppDatabase db, $OfflinePacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OfflinePacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OfflinePacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OfflinePacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packKey = const Value.absent(),
                Value<String> scopeType = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> teacherTrackId = const Value.absent(),
                Value<String> scopeTitle = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> unitId = const Value.absent(),
                Value<String?> deckId = const Value.absent(),
                Value<String> titleAr = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String?> remoteVersion = const Value.absent(),
                Value<bool> premium = const Value.absent(),
                Value<int?> normalizationVersion = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflinePacksCompanion(
                packKey: packKey,
                scopeType: scopeType,
                subjectId: subjectId,
                teacherTrackId: teacherTrackId,
                scopeTitle: scopeTitle,
                kind: kind,
                unitId: unitId,
                deckId: deckId,
                titleAr: titleAr,
                status: status,
                version: version,
                remoteVersion: remoteVersion,
                premium: premium,
                normalizationVersion: normalizationVersion,
                sizeBytes: sizeBytes,
                downloadedBytes: downloadedBytes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packKey,
                required String scopeType,
                Value<String?> subjectId = const Value.absent(),
                Value<String?> teacherTrackId = const Value.absent(),
                required String scopeTitle,
                required String kind,
                Value<String?> unitId = const Value.absent(),
                Value<String?> deckId = const Value.absent(),
                required String titleAr,
                required String status,
                Value<String?> version = const Value.absent(),
                Value<String?> remoteVersion = const Value.absent(),
                Value<bool> premium = const Value.absent(),
                Value<int?> normalizationVersion = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OfflinePacksCompanion.insert(
                packKey: packKey,
                scopeType: scopeType,
                subjectId: subjectId,
                teacherTrackId: teacherTrackId,
                scopeTitle: scopeTitle,
                kind: kind,
                unitId: unitId,
                deckId: deckId,
                titleAr: titleAr,
                status: status,
                version: version,
                remoteVersion: remoteVersion,
                premium: premium,
                normalizationVersion: normalizationVersion,
                sizeBytes: sizeBytes,
                downloadedBytes: downloadedBytes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflinePacksTable, OfflinePackRow>(table),
                  BaseReferences<_$AppDatabase, $OfflinePacksTable, OfflinePackRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflinePacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflinePacksTable,
      OfflinePackRow,
      $$OfflinePacksTableFilterComposer,
      $$OfflinePacksTableOrderingComposer,
      $$OfflinePacksTableAnnotationComposer,
      $$OfflinePacksTableCreateCompanionBuilder,
      $$OfflinePacksTableUpdateCompanionBuilder,
      (OfflinePackRow, BaseReferences<_$AppDatabase, $OfflinePacksTable, OfflinePackRow>),
      OfflinePackRow,
      PrefetchHooks Function()
    >;
typedef $$OfflineItemsTableCreateCompanionBuilder =
    OfflineItemsCompanion Function({
      required String packKey,
      required String itemId,
      required String type,
      required int version,
      required bool isFree,
      required String json,
      Value<int> rowid,
    });
typedef $$OfflineItemsTableUpdateCompanionBuilder =
    OfflineItemsCompanion Function({
      Value<String> packKey,
      Value<String> itemId,
      Value<String> type,
      Value<int> version,
      Value<bool> isFree,
      Value<String> json,
      Value<int> rowid,
    });

class $$OfflineItemsTableFilterComposer extends Composer<_$AppDatabase, $OfflineItemsTable> {
  $$OfflineItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packKey =>
      $composableBuilder(column: $table.packKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFree =>
      $composableBuilder(column: $table.isFree, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(column: $table.json, builder: (column) => ColumnFilters(column));
}

class $$OfflineItemsTableOrderingComposer extends Composer<_$AppDatabase, $OfflineItemsTable> {
  $$OfflineItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packKey =>
      $composableBuilder(column: $table.packKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFree =>
      $composableBuilder(column: $table.isFree, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnOrderings(column));
}

class $$OfflineItemsTableAnnotationComposer extends Composer<_$AppDatabase, $OfflineItemsTable> {
  $$OfflineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packKey => $composableBuilder(column: $table.packKey, builder: (column) => column);

  GeneratedColumn<String> get itemId => $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get version => $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isFree => $composableBuilder(column: $table.isFree, builder: (column) => column);

  GeneratedColumn<String> get json => $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$OfflineItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineItemsTable,
          OfflineItemRow,
          $$OfflineItemsTableFilterComposer,
          $$OfflineItemsTableOrderingComposer,
          $$OfflineItemsTableAnnotationComposer,
          $$OfflineItemsTableCreateCompanionBuilder,
          $$OfflineItemsTableUpdateCompanionBuilder,
          (OfflineItemRow, BaseReferences<_$AppDatabase, $OfflineItemsTable, OfflineItemRow>),
          OfflineItemRow,
          PrefetchHooks Function()
        > {
  $$OfflineItemsTableTableManager(_$AppDatabase db, $OfflineItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OfflineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OfflineItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OfflineItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packKey = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> isFree = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineItemsCompanion(
                packKey: packKey,
                itemId: itemId,
                type: type,
                version: version,
                isFree: isFree,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packKey,
                required String itemId,
                required String type,
                required int version,
                required bool isFree,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => OfflineItemsCompanion.insert(
                packKey: packKey,
                itemId: itemId,
                type: type,
                version: version,
                isFree: isFree,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineItemsTable, OfflineItemRow>(table),
                  BaseReferences<_$AppDatabase, $OfflineItemsTable, OfflineItemRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineItemsTable,
      OfflineItemRow,
      $$OfflineItemsTableFilterComposer,
      $$OfflineItemsTableOrderingComposer,
      $$OfflineItemsTableAnnotationComposer,
      $$OfflineItemsTableCreateCompanionBuilder,
      $$OfflineItemsTableUpdateCompanionBuilder,
      (OfflineItemRow, BaseReferences<_$AppDatabase, $OfflineItemsTable, OfflineItemRow>),
      OfflineItemRow,
      PrefetchHooks Function()
    >;
typedef $$OfflineFilesTableCreateCompanionBuilder =
    OfflineFilesCompanion Function({
      required String packKey,
      required String mediaId,
      required int version,
      required String path,
      required int sizeBytes,
      Value<int> rowid,
    });
typedef $$OfflineFilesTableUpdateCompanionBuilder =
    OfflineFilesCompanion Function({
      Value<String> packKey,
      Value<String> mediaId,
      Value<int> version,
      Value<String> path,
      Value<int> sizeBytes,
      Value<int> rowid,
    });

class $$OfflineFilesTableFilterComposer extends Composer<_$AppDatabase, $OfflineFilesTable> {
  $$OfflineFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packKey =>
      $composableBuilder(column: $table.packKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnFilters(column));
}

class $$OfflineFilesTableOrderingComposer extends Composer<_$AppDatabase, $OfflineFilesTable> {
  $$OfflineFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packKey =>
      $composableBuilder(column: $table.packKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));
}

class $$OfflineFilesTableAnnotationComposer extends Composer<_$AppDatabase, $OfflineFilesTable> {
  $$OfflineFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packKey => $composableBuilder(column: $table.packKey, builder: (column) => column);

  GeneratedColumn<String> get mediaId => $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<int> get version => $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get path => $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes => $composableBuilder(column: $table.sizeBytes, builder: (column) => column);
}

class $$OfflineFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineFilesTable,
          OfflineFileRow,
          $$OfflineFilesTableFilterComposer,
          $$OfflineFilesTableOrderingComposer,
          $$OfflineFilesTableAnnotationComposer,
          $$OfflineFilesTableCreateCompanionBuilder,
          $$OfflineFilesTableUpdateCompanionBuilder,
          (OfflineFileRow, BaseReferences<_$AppDatabase, $OfflineFilesTable, OfflineFileRow>),
          OfflineFileRow,
          PrefetchHooks Function()
        > {
  $$OfflineFilesTableTableManager(_$AppDatabase db, $OfflineFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OfflineFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OfflineFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OfflineFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packKey = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineFilesCompanion(
                packKey: packKey,
                mediaId: mediaId,
                version: version,
                path: path,
                sizeBytes: sizeBytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packKey,
                required String mediaId,
                required int version,
                required String path,
                required int sizeBytes,
                Value<int> rowid = const Value.absent(),
              }) => OfflineFilesCompanion.insert(
                packKey: packKey,
                mediaId: mediaId,
                version: version,
                path: path,
                sizeBytes: sizeBytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineFilesTable, OfflineFileRow>(table),
                  BaseReferences<_$AppDatabase, $OfflineFilesTable, OfflineFileRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineFilesTable,
      OfflineFileRow,
      $$OfflineFilesTableFilterComposer,
      $$OfflineFilesTableOrderingComposer,
      $$OfflineFilesTableAnnotationComposer,
      $$OfflineFilesTableCreateCompanionBuilder,
      $$OfflineFilesTableUpdateCompanionBuilder,
      (OfflineFileRow, BaseReferences<_$AppDatabase, $OfflineFilesTable, OfflineFileRow>),
      OfflineFileRow,
      PrefetchHooks Function()
    >;
typedef $$OfflineLeaseRowsTableCreateCompanionBuilder =
    OfflineLeaseRowsCompanion Function({
      required String scopeKey,
      required int expiresAt,
      required int refreshedAt,
      Value<int> rowid,
    });
typedef $$OfflineLeaseRowsTableUpdateCompanionBuilder =
    OfflineLeaseRowsCompanion Function({
      Value<String> scopeKey,
      Value<int> expiresAt,
      Value<int> refreshedAt,
      Value<int> rowid,
    });

class $$OfflineLeaseRowsTableFilterComposer extends Composer<_$AppDatabase, $OfflineLeaseRowsTable> {
  $$OfflineLeaseRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get refreshedAt =>
      $composableBuilder(column: $table.refreshedAt, builder: (column) => ColumnFilters(column));
}

class $$OfflineLeaseRowsTableOrderingComposer extends Composer<_$AppDatabase, $OfflineLeaseRowsTable> {
  $$OfflineLeaseRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get refreshedAt =>
      $composableBuilder(column: $table.refreshedAt, builder: (column) => ColumnOrderings(column));
}

class $$OfflineLeaseRowsTableAnnotationComposer extends Composer<_$AppDatabase, $OfflineLeaseRowsTable> {
  $$OfflineLeaseRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scopeKey => $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<int> get expiresAt => $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get refreshedAt => $composableBuilder(column: $table.refreshedAt, builder: (column) => column);
}

class $$OfflineLeaseRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineLeaseRowsTable,
          OfflineLeaseRow,
          $$OfflineLeaseRowsTableFilterComposer,
          $$OfflineLeaseRowsTableOrderingComposer,
          $$OfflineLeaseRowsTableAnnotationComposer,
          $$OfflineLeaseRowsTableCreateCompanionBuilder,
          $$OfflineLeaseRowsTableUpdateCompanionBuilder,
          (OfflineLeaseRow, BaseReferences<_$AppDatabase, $OfflineLeaseRowsTable, OfflineLeaseRow>),
          OfflineLeaseRow,
          PrefetchHooks Function()
        > {
  $$OfflineLeaseRowsTableTableManager(_$AppDatabase db, $OfflineLeaseRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OfflineLeaseRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OfflineLeaseRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OfflineLeaseRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scopeKey = const Value.absent(),
                Value<int> expiresAt = const Value.absent(),
                Value<int> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineLeaseRowsCompanion(
                scopeKey: scopeKey,
                expiresAt: expiresAt,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scopeKey,
                required int expiresAt,
                required int refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => OfflineLeaseRowsCompanion.insert(
                scopeKey: scopeKey,
                expiresAt: expiresAt,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineLeaseRowsTable, OfflineLeaseRow>(table),
                  BaseReferences<_$AppDatabase, $OfflineLeaseRowsTable, OfflineLeaseRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineLeaseRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineLeaseRowsTable,
      OfflineLeaseRow,
      $$OfflineLeaseRowsTableFilterComposer,
      $$OfflineLeaseRowsTableOrderingComposer,
      $$OfflineLeaseRowsTableAnnotationComposer,
      $$OfflineLeaseRowsTableCreateCompanionBuilder,
      $$OfflineLeaseRowsTableUpdateCompanionBuilder,
      (OfflineLeaseRow, BaseReferences<_$AppDatabase, $OfflineLeaseRowsTable, OfflineLeaseRow>),
      OfflineLeaseRow,
      PrefetchHooks Function()
    >;
typedef $$LocalAttemptsTableCreateCompanionBuilder =
    LocalAttemptsCompanion Function({
      required String id,
      required String attempt,
      Value<String?> payload,
      Value<bool> submitted,
      Value<bool> synced,
      Value<String?> serverAttemptId,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$LocalAttemptsTableUpdateCompanionBuilder =
    LocalAttemptsCompanion Function({
      Value<String> id,
      Value<String> attempt,
      Value<String?> payload,
      Value<bool> submitted,
      Value<bool> synced,
      Value<String?> serverAttemptId,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$LocalAttemptsTableFilterComposer extends Composer<_$AppDatabase, $LocalAttemptsTable> {
  $$LocalAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get submitted =>
      $composableBuilder(column: $table.submitted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverAttemptId =>
      $composableBuilder(column: $table.serverAttemptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LocalAttemptsTableOrderingComposer extends Composer<_$AppDatabase, $LocalAttemptsTable> {
  $$LocalAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get submitted =>
      $composableBuilder(column: $table.submitted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverAttemptId =>
      $composableBuilder(column: $table.serverAttemptId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalAttemptsTableAnnotationComposer extends Composer<_$AppDatabase, $LocalAttemptsTable> {
  $$LocalAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get attempt => $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<String> get payload => $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<bool> get submitted => $composableBuilder(column: $table.submitted, builder: (column) => column);

  GeneratedColumn<bool> get synced => $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get serverAttemptId =>
      $composableBuilder(column: $table.serverAttemptId, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAttemptsTable,
          LocalAttemptRow,
          $$LocalAttemptsTableFilterComposer,
          $$LocalAttemptsTableOrderingComposer,
          $$LocalAttemptsTableAnnotationComposer,
          $$LocalAttemptsTableCreateCompanionBuilder,
          $$LocalAttemptsTableUpdateCompanionBuilder,
          (LocalAttemptRow, BaseReferences<_$AppDatabase, $LocalAttemptsTable, LocalAttemptRow>),
          LocalAttemptRow,
          PrefetchHooks Function()
        > {
  $$LocalAttemptsTableTableManager(_$AppDatabase db, $LocalAttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> attempt = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<bool> submitted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String?> serverAttemptId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAttemptsCompanion(
                id: id,
                attempt: attempt,
                payload: payload,
                submitted: submitted,
                synced: synced,
                serverAttemptId: serverAttemptId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String attempt,
                Value<String?> payload = const Value.absent(),
                Value<bool> submitted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String?> serverAttemptId = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalAttemptsCompanion.insert(
                id: id,
                attempt: attempt,
                payload: payload,
                submitted: submitted,
                synced: synced,
                serverAttemptId: serverAttemptId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAttemptsTable, LocalAttemptRow>(table),
                  BaseReferences<_$AppDatabase, $LocalAttemptsTable, LocalAttemptRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAttemptsTable,
      LocalAttemptRow,
      $$LocalAttemptsTableFilterComposer,
      $$LocalAttemptsTableOrderingComposer,
      $$LocalAttemptsTableAnnotationComposer,
      $$LocalAttemptsTableCreateCompanionBuilder,
      $$LocalAttemptsTableUpdateCompanionBuilder,
      (LocalAttemptRow, BaseReferences<_$AppDatabase, $LocalAttemptsTable, LocalAttemptRow>),
      LocalAttemptRow,
      PrefetchHooks Function()
    >;
typedef $$LocalMistakesTableCreateCompanionBuilder =
    LocalMistakesCompanion Function({required String questionId, required int wrongAt, Value<int> rowid});
typedef $$LocalMistakesTableUpdateCompanionBuilder =
    LocalMistakesCompanion Function({Value<String> questionId, Value<int> wrongAt, Value<int> rowid});

class $$LocalMistakesTableFilterComposer extends Composer<_$AppDatabase, $LocalMistakesTable> {
  $$LocalMistakesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId =>
      $composableBuilder(column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wrongAt =>
      $composableBuilder(column: $table.wrongAt, builder: (column) => ColumnFilters(column));
}

class $$LocalMistakesTableOrderingComposer extends Composer<_$AppDatabase, $LocalMistakesTable> {
  $$LocalMistakesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId =>
      $composableBuilder(column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wrongAt =>
      $composableBuilder(column: $table.wrongAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalMistakesTableAnnotationComposer extends Composer<_$AppDatabase, $LocalMistakesTable> {
  $$LocalMistakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(column: $table.questionId, builder: (column) => column);

  GeneratedColumn<int> get wrongAt => $composableBuilder(column: $table.wrongAt, builder: (column) => column);
}

class $$LocalMistakesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMistakesTable,
          LocalMistakeRow,
          $$LocalMistakesTableFilterComposer,
          $$LocalMistakesTableOrderingComposer,
          $$LocalMistakesTableAnnotationComposer,
          $$LocalMistakesTableCreateCompanionBuilder,
          $$LocalMistakesTableUpdateCompanionBuilder,
          (LocalMistakeRow, BaseReferences<_$AppDatabase, $LocalMistakesTable, LocalMistakeRow>),
          LocalMistakeRow,
          PrefetchHooks Function()
        > {
  $$LocalMistakesTableTableManager(_$AppDatabase db, $LocalMistakesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalMistakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalMistakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalMistakesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<int> wrongAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMistakesCompanion(questionId: questionId, wrongAt: wrongAt, rowid: rowid),
          createCompanionCallback:
              ({required String questionId, required int wrongAt, Value<int> rowid = const Value.absent()}) =>
                  LocalMistakesCompanion.insert(questionId: questionId, wrongAt: wrongAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMistakesTable, LocalMistakeRow>(table),
                  BaseReferences<_$AppDatabase, $LocalMistakesTable, LocalMistakeRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMistakesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMistakesTable,
      LocalMistakeRow,
      $$LocalMistakesTableFilterComposer,
      $$LocalMistakesTableOrderingComposer,
      $$LocalMistakesTableAnnotationComposer,
      $$LocalMistakesTableCreateCompanionBuilder,
      $$LocalMistakesTableUpdateCompanionBuilder,
      (LocalMistakeRow, BaseReferences<_$AppDatabase, $LocalMistakesTable, LocalMistakeRow>),
      LocalMistakeRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeyValuesTableTableManager get keyValues => $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$SrsCardStatesTableTableManager get srsCardStates => $$SrsCardStatesTableTableManager(_db, _db.srsCardStates);
  $$SrsReviewLogsTableTableManager get srsReviewLogs => $$SrsReviewLogsTableTableManager(_db, _db.srsReviewLogs);
  $$ExamDraftsTableTableManager get examDrafts => $$ExamDraftsTableTableManager(_db, _db.examDrafts);
  $$ExamAnswersTableTableManager get examAnswers => $$ExamAnswersTableTableManager(_db, _db.examAnswers);
  $$LocalDecksTableTableManager get localDecks => $$LocalDecksTableTableManager(_db, _db.localDecks);
  $$LocalCardsTableTableManager get localCards => $$LocalCardsTableTableManager(_db, _db.localCards);
  $$OfflinePacksTableTableManager get offlinePacks => $$OfflinePacksTableTableManager(_db, _db.offlinePacks);
  $$OfflineItemsTableTableManager get offlineItems => $$OfflineItemsTableTableManager(_db, _db.offlineItems);
  $$OfflineFilesTableTableManager get offlineFiles => $$OfflineFilesTableTableManager(_db, _db.offlineFiles);
  $$OfflineLeaseRowsTableTableManager get offlineLeaseRows =>
      $$OfflineLeaseRowsTableTableManager(_db, _db.offlineLeaseRows);
  $$LocalAttemptsTableTableManager get localAttempts => $$LocalAttemptsTableTableManager(_db, _db.localAttempts);
  $$LocalMistakesTableTableManager get localMistakes => $$LocalMistakesTableTableManager(_db, _db.localMistakes);
}
