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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $SrsCardStatesTable srsCardStates = $SrsCardStatesTable(this);
  late final $SrsReviewLogsTable srsReviewLogs = $SrsReviewLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValues,
    srsCardStates,
    srsReviewLogs,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$SrsCardStatesTableTableManager get srsCardStates =>
      $$SrsCardStatesTableTableManager(_db, _db.srsCardStates);
  $$SrsReviewLogsTableTableManager get srsReviewLogs =>
      $$SrsReviewLogsTableTableManager(_db, _db.srsReviewLogs);
}
