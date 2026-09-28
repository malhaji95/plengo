// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
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
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
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
  const KeyValue({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
      KeyValue(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
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
      (other is KeyValue &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
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

class $SrsCardStatesTable extends SrsCardStates
    with TableInfo<$SrsCardStatesTable, SrsCardState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsCardStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _flashcardIdMeta = const VerificationMeta(
    'flashcardId',
  );
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
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
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
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
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
  VerificationContext validateIntegrity(
    Insertable<SrsCardState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('flashcard_id')) {
      context.handle(
        _flashcardIdMeta,
        flashcardId.isAcceptableOrUnknown(
          data['flashcard_id']!,
          _flashcardIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_flashcardIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalDaysMeta);
    }
    if (data.containsKey('ease')) {
      context.handle(
        _easeMeta,
        ease.isAcceptableOrUnknown(data['ease']!, _easeMeta),
      );
    } else if (isInserting) {
      context.missing(_easeMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    } else if (isInserting) {
      context.missing(_lapsesMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
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
      flashcardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flashcard_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      ease: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reviewed_at'],
      ),
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
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
    );
  }

  factory SrsCardState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
  );
  SrsCardState copyWithCompanion(SrsCardStatesCompanion data) {
    return SrsCardState(
      flashcardId: data.flashcardId.present
          ? data.flashcardId.value
          : this.flashcardId,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      ease: data.ease.present ? data.ease.value : this.ease,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
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
  int get hashCode => Object.hash(
    flashcardId,
    state,
    step,
    dueAt,
    intervalDays,
    ease,
    reps,
    lapses,
    lastReviewedAt,
  );
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

class $SrsReviewLogsTable extends SrsReviewLogs
    with TableInfo<$SrsReviewLogsTable, SrsReviewLog> {
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
  static const VerificationMeta _flashcardIdMeta = const VerificationMeta(
    'flashcardId',
  );
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
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<int> reviewedAt = GeneratedColumn<int>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("undone" IN (0, 1))',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
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
  VerificationContext validateIntegrity(
    Insertable<SrsReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('flashcard_id')) {
      context.handle(
        _flashcardIdMeta,
        flashcardId.isAcceptableOrUnknown(
          data['flashcard_id']!,
          _flashcardIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_flashcardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('before')) {
      context.handle(
        _beforeMeta,
        before.isAcceptableOrUnknown(data['before']!, _beforeMeta),
      );
    } else if (isInserting) {
      context.missing(_beforeMeta);
    }
    if (data.containsKey('after')) {
      context.handle(
        _afterMeta,
        after.isAcceptableOrUnknown(data['after']!, _afterMeta),
      );
    } else if (isInserting) {
      context.missing(_afterMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('undone')) {
      context.handle(
        _undoneMeta,
        undone.isAcceptableOrUnknown(data['undone']!, _undoneMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SrsReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      flashcardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flashcard_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      )!,
      before: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}before'],
      )!,
      after: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}after'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviewed_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      undone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}undone'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
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
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      undone: Value(undone),
      synced: Value(synced),
    );
  }

  factory SrsReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
      flashcardId: data.flashcardId.present
          ? data.flashcardId.value
          : this.flashcardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      before: data.before.present ? data.before.value : this.before,
      after: data.after.present ? data.after.value : this.after,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
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
  int get hashCode => Object.hash(
    id,
    flashcardId,
    rating,
    before,
    after,
    reviewedAt,
    durationMs,
    undone,
    synced,
  );
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

class $ExamDraftsTable extends ExamDrafts
    with TableInfo<$ExamDraftsTable, ExamDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<String> attemptId = GeneratedColumn<String>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  @override
  late final GeneratedColumn<String> attempt = GeneratedColumn<String>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _submitPendingMeta = const VerificationMeta(
    'submitPending',
  );
  @override
  late final GeneratedColumn<bool> submitPending = GeneratedColumn<bool>(
    'submit_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("submit_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timeSpentMsMeta = const VerificationMeta(
    'timeSpentMs',
  );
  @override
  late final GeneratedColumn<int> timeSpentMs = GeneratedColumn<int>(
    'time_spent_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
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
    attemptId,
    attempt,
    submitPending,
    timeSpentMs,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exam_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExamDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptMeta);
    }
    if (data.containsKey('submit_pending')) {
      context.handle(
        _submitPendingMeta,
        submitPending.isAcceptableOrUnknown(
          data['submit_pending']!,
          _submitPendingMeta,
        ),
      );
    }
    if (data.containsKey('time_spent_ms')) {
      context.handle(
        _timeSpentMsMeta,
        timeSpentMs.isAcceptableOrUnknown(
          data['time_spent_ms']!,
          _timeSpentMsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
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
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempt_id'],
      )!,
      attempt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempt'],
      )!,
      submitPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}submit_pending'],
      )!,
      timeSpentMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_spent_ms'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
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
      timeSpentMs: timeSpentMs == null && nullToAbsent
          ? const Value.absent()
          : Value(timeSpentMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExamDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
      submitPending: data.submitPending.present
          ? data.submitPending.value
          : this.submitPending,
      timeSpentMs: data.timeSpentMs.present
          ? data.timeSpentMs.value
          : this.timeSpentMs,
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
  int get hashCode =>
      Object.hash(attemptId, attempt, submitPending, timeSpentMs, updatedAt);
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

class $ExamAnswersTable extends ExamAnswers
    with TableInfo<$ExamAnswersTable, ExamAnswerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<String> attemptId = GeneratedColumn<String>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedOptionIdMeta = const VerificationMeta(
    'selectedOptionId',
  );
  @override
  late final GeneratedColumn<String> selectedOptionId = GeneratedColumn<String>(
    'selected_option_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _writtenAnswerMeta = const VerificationMeta(
    'writtenAnswer',
  );
  @override
  late final GeneratedColumn<String> writtenAnswer = GeneratedColumn<String>(
    'written_answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flaggedMeta = const VerificationMeta(
    'flagged',
  );
  @override
  late final GeneratedColumn<bool> flagged = GeneratedColumn<bool>(
    'flagged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("flagged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timeSpentMsMeta = const VerificationMeta(
    'timeSpentMs',
  );
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
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
  VerificationContext validateIntegrity(
    Insertable<ExamAnswerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('selected_option_id')) {
      context.handle(
        _selectedOptionIdMeta,
        selectedOptionId.isAcceptableOrUnknown(
          data['selected_option_id']!,
          _selectedOptionIdMeta,
        ),
      );
    }
    if (data.containsKey('written_answer')) {
      context.handle(
        _writtenAnswerMeta,
        writtenAnswer.isAcceptableOrUnknown(
          data['written_answer']!,
          _writtenAnswerMeta,
        ),
      );
    }
    if (data.containsKey('flagged')) {
      context.handle(
        _flaggedMeta,
        flagged.isAcceptableOrUnknown(data['flagged']!, _flaggedMeta),
      );
    }
    if (data.containsKey('time_spent_ms')) {
      context.handle(
        _timeSpentMsMeta,
        timeSpentMs.isAcceptableOrUnknown(
          data['time_spent_ms']!,
          _timeSpentMsMeta,
        ),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attemptId, questionId};
  @override
  ExamAnswerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamAnswerRow(
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempt_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      selectedOptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_option_id'],
      ),
      writtenAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}written_answer'],
      ),
      flagged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}flagged'],
      )!,
      timeSpentMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_spent_ms'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
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
      selectedOptionId: selectedOptionId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedOptionId),
      writtenAnswer: writtenAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(writtenAnswer),
      flagged: Value(flagged),
      timeSpentMs: timeSpentMs == null && nullToAbsent
          ? const Value.absent()
          : Value(timeSpentMs),
      dirty: Value(dirty),
    );
  }

  factory ExamAnswerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
    selectedOptionId: selectedOptionId.present
        ? selectedOptionId.value
        : this.selectedOptionId,
    writtenAnswer: writtenAnswer.present
        ? writtenAnswer.value
        : this.writtenAnswer,
    flagged: flagged ?? this.flagged,
    timeSpentMs: timeSpentMs.present ? timeSpentMs.value : this.timeSpentMs,
    dirty: dirty ?? this.dirty,
  );
  ExamAnswerRow copyWithCompanion(ExamAnswersCompanion data) {
    return ExamAnswerRow(
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      selectedOptionId: data.selectedOptionId.present
          ? data.selectedOptionId.value
          : this.selectedOptionId,
      writtenAnswer: data.writtenAnswer.present
          ? data.writtenAnswer.value
          : this.writtenAnswer,
      flagged: data.flagged.present ? data.flagged.value : this.flagged,
      timeSpentMs: data.timeSpentMs.present
          ? data.timeSpentMs.value
          : this.timeSpentMs,
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
  int get hashCode => Object.hash(
    attemptId,
    questionId,
    selectedOptionId,
    writtenAnswer,
    flagged,
    timeSpentMs,
    dirty,
  );
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $SrsCardStatesTable srsCardStates = $SrsCardStatesTable(this);
  late final $SrsReviewLogsTable srsReviewLogs = $SrsReviewLogsTable(this);
  late final $ExamDraftsTable examDrafts = $ExamDraftsTable(this);
  late final $ExamAnswersTable examAnswers = $ExamAnswersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValues,
    srsCardStates,
    srsReviewLogs,
    examDrafts,
    examAnswers,
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
    KeyValuesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
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
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>(
                    db,
                    table,
                    e,
                  ),
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

class $$SrsCardStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SrsCardStatesTable> {
  $$SrsCardStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get flashcardId => $composableBuilder(
    column: $table.flashcardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SrsCardStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SrsCardStatesTable> {
  $$SrsCardStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get flashcardId => $composableBuilder(
    column: $table.flashcardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SrsCardStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SrsCardStatesTable> {
  $$SrsCardStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get flashcardId => $composableBuilder(
    column: $table.flashcardId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );
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
          (
            SrsCardState,
            BaseReferences<_$AppDatabase, $SrsCardStatesTable, SrsCardState>,
          ),
          SrsCardState,
          PrefetchHooks Function()
        > {
  $$SrsCardStatesTableTableManager(_$AppDatabase db, $SrsCardStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SrsCardStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SrsCardStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SrsCardStatesTableAnnotationComposer($db: db, $table: table),
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
                  BaseReferences<
                    _$AppDatabase,
                    $SrsCardStatesTable,
                    SrsCardState
                  >(db, table, e),
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
      (
        SrsCardState,
        BaseReferences<_$AppDatabase, $SrsCardStatesTable, SrsCardState>,
      ),
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

class $$SrsReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SrsReviewLogsTable> {
  $$SrsReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flashcardId => $composableBuilder(
    column: $table.flashcardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get before => $composableBuilder(
    column: $table.before,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get after => $composableBuilder(
    column: $table.after,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get undone => $composableBuilder(
    column: $table.undone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SrsReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SrsReviewLogsTable> {
  $$SrsReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flashcardId => $composableBuilder(
    column: $table.flashcardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get before => $composableBuilder(
    column: $table.before,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get after => $composableBuilder(
    column: $table.after,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get undone => $composableBuilder(
    column: $table.undone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SrsReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SrsReviewLogsTable> {
  $$SrsReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get flashcardId => $composableBuilder(
    column: $table.flashcardId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get before =>
      $composableBuilder(column: $table.before, builder: (column) => column);

  GeneratedColumn<String> get after =>
      $composableBuilder(column: $table.after, builder: (column) => column);

  GeneratedColumn<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get undone =>
      $composableBuilder(column: $table.undone, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
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
          (
            SrsReviewLog,
            BaseReferences<_$AppDatabase, $SrsReviewLogsTable, SrsReviewLog>,
          ),
          SrsReviewLog,
          PrefetchHooks Function()
        > {
  $$SrsReviewLogsTableTableManager(_$AppDatabase db, $SrsReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SrsReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SrsReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SrsReviewLogsTableAnnotationComposer($db: db, $table: table),
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
                  BaseReferences<
                    _$AppDatabase,
                    $SrsReviewLogsTable,
                    SrsReviewLog
                  >(db, table, e),
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
      (
        SrsReviewLog,
        BaseReferences<_$AppDatabase, $SrsReviewLogsTable, SrsReviewLog>,
      ),
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

class $$ExamDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $ExamDraftsTable> {
  $$ExamDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get submitPending => $composableBuilder(
    column: $table.submitPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSpentMs => $composableBuilder(
    column: $table.timeSpentMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExamDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExamDraftsTable> {
  $$ExamDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get submitPending => $composableBuilder(
    column: $table.submitPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSpentMs => $composableBuilder(
    column: $table.timeSpentMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExamDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExamDraftsTable> {
  $$ExamDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<String> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<bool> get submitPending => $composableBuilder(
    column: $table.submitPending,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeSpentMs => $composableBuilder(
    column: $table.timeSpentMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
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
          (
            ExamDraftRow,
            BaseReferences<_$AppDatabase, $ExamDraftsTable, ExamDraftRow>,
          ),
          ExamDraftRow,
          PrefetchHooks Function()
        > {
  $$ExamDraftsTableTableManager(_$AppDatabase db, $ExamDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamDraftsTableAnnotationComposer($db: db, $table: table),
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
                  BaseReferences<_$AppDatabase, $ExamDraftsTable, ExamDraftRow>(
                    db,
                    table,
                    e,
                  ),
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
      (
        ExamDraftRow,
        BaseReferences<_$AppDatabase, $ExamDraftsTable, ExamDraftRow>,
      ),
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

class $$ExamAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $ExamAnswersTable> {
  $$ExamAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedOptionId => $composableBuilder(
    column: $table.selectedOptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get writtenAnswer => $composableBuilder(
    column: $table.writtenAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get flagged => $composableBuilder(
    column: $table.flagged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSpentMs => $composableBuilder(
    column: $table.timeSpentMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExamAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $ExamAnswersTable> {
  $$ExamAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedOptionId => $composableBuilder(
    column: $table.selectedOptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get writtenAnswer => $composableBuilder(
    column: $table.writtenAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get flagged => $composableBuilder(
    column: $table.flagged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSpentMs => $composableBuilder(
    column: $table.timeSpentMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExamAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExamAnswersTable> {
  $$ExamAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedOptionId => $composableBuilder(
    column: $table.selectedOptionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get writtenAnswer => $composableBuilder(
    column: $table.writtenAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get flagged =>
      $composableBuilder(column: $table.flagged, builder: (column) => column);

  GeneratedColumn<int> get timeSpentMs => $composableBuilder(
    column: $table.timeSpentMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
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
          (
            ExamAnswerRow,
            BaseReferences<_$AppDatabase, $ExamAnswersTable, ExamAnswerRow>,
          ),
          ExamAnswerRow,
          PrefetchHooks Function()
        > {
  $$ExamAnswersTableTableManager(_$AppDatabase db, $ExamAnswersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamAnswersTableAnnotationComposer($db: db, $table: table),
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
                  BaseReferences<
                    _$AppDatabase,
                    $ExamAnswersTable,
                    ExamAnswerRow
                  >(db, table, e),
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
      (
        ExamAnswerRow,
        BaseReferences<_$AppDatabase, $ExamAnswersTable, ExamAnswerRow>,
      ),
      ExamAnswerRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$SrsCardStatesTableTableManager get srsCardStates =>
      $$SrsCardStatesTableTableManager(_db, _db.srsCardStates);
  $$SrsReviewLogsTableTableManager get srsReviewLogs =>
      $$SrsReviewLogsTableTableManager(_db, _db.srsReviewLogs);
  $$ExamDraftsTableTableManager get examDrafts =>
      $$ExamDraftsTableTableManager(_db, _db.examDrafts);
  $$ExamAnswersTableTableManager get examAnswers =>
      $$ExamAnswersTableTableManager(_db, _db.examAnswers);
}
