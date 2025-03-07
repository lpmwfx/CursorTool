// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_database.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbChatCollection on Isar {
  IsarCollection<DbChat> get dbChats => this.collection();
}

const DbChatSchema = CollectionSchema(
  name: r'DbChat',
  id: 8083793233802279222,
  properties: {
    r'contextQueries': PropertySchema(
      id: 0,
      name: r'contextQueries',
      type: IsarType.stringList,
    ),
    r'cursorId': PropertySchema(
      id: 1,
      name: r'cursorId',
      type: IsarType.string,
    ),
    r'isFavorite': PropertySchema(
      id: 2,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'lastMessageTime': PropertySchema(
      id: 3,
      name: r'lastMessageTime',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(
      id: 4,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _dbChatEstimateSize,
  serialize: _dbChatSerialize,
  deserialize: _dbChatDeserialize,
  deserializeProp: _dbChatDeserializeProp,
  idName: r'id',
  indexes: {
    r'cursorId': IndexSchema(
      id: -3567881170490246652,
      name: r'cursorId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'cursorId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'messages': LinkSchema(
      id: 96980102294349061,
      name: r'messages',
      target: r'DbMessage',
      single: false,
      linkName: r'chat',
    ),
    r'tags': LinkSchema(
      id: -4463049217488154555,
      name: r'tags',
      target: r'DbTag',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _dbChatGetId,
  getLinks: _dbChatGetLinks,
  attach: _dbChatAttach,
  version: '3.1.0+1',
);

int _dbChatEstimateSize(
  DbChat object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.contextQueries;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  bytesCount += 3 + object.cursorId.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _dbChatSerialize(
  DbChat object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.contextQueries);
  writer.writeString(offsets[1], object.cursorId);
  writer.writeBool(offsets[2], object.isFavorite);
  writer.writeDateTime(offsets[3], object.lastMessageTime);
  writer.writeString(offsets[4], object.title);
}

DbChat _dbChatDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbChat();
  object.contextQueries = reader.readStringList(offsets[0]);
  object.cursorId = reader.readString(offsets[1]);
  object.id = id;
  object.isFavorite = reader.readBool(offsets[2]);
  object.lastMessageTime = reader.readDateTime(offsets[3]);
  object.title = reader.readString(offsets[4]);
  return object;
}

P _dbChatDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbChatGetId(DbChat object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbChatGetLinks(DbChat object) {
  return [object.messages, object.tags];
}

void _dbChatAttach(IsarCollection<dynamic> col, Id id, DbChat object) {
  object.id = id;
  object.messages
      .attach(col, col.isar.collection<DbMessage>(), r'messages', id);
  object.tags.attach(col, col.isar.collection<DbTag>(), r'tags', id);
}

extension DbChatByIndex on IsarCollection<DbChat> {
  Future<DbChat?> getByCursorId(String cursorId) {
    return getByIndex(r'cursorId', [cursorId]);
  }

  DbChat? getByCursorIdSync(String cursorId) {
    return getByIndexSync(r'cursorId', [cursorId]);
  }

  Future<bool> deleteByCursorId(String cursorId) {
    return deleteByIndex(r'cursorId', [cursorId]);
  }

  bool deleteByCursorIdSync(String cursorId) {
    return deleteByIndexSync(r'cursorId', [cursorId]);
  }

  Future<List<DbChat?>> getAllByCursorId(List<String> cursorIdValues) {
    final values = cursorIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'cursorId', values);
  }

  List<DbChat?> getAllByCursorIdSync(List<String> cursorIdValues) {
    final values = cursorIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'cursorId', values);
  }

  Future<int> deleteAllByCursorId(List<String> cursorIdValues) {
    final values = cursorIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'cursorId', values);
  }

  int deleteAllByCursorIdSync(List<String> cursorIdValues) {
    final values = cursorIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'cursorId', values);
  }

  Future<Id> putByCursorId(DbChat object) {
    return putByIndex(r'cursorId', object);
  }

  Id putByCursorIdSync(DbChat object, {bool saveLinks = true}) {
    return putByIndexSync(r'cursorId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCursorId(List<DbChat> objects) {
    return putAllByIndex(r'cursorId', objects);
  }

  List<Id> putAllByCursorIdSync(List<DbChat> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'cursorId', objects, saveLinks: saveLinks);
  }
}

extension DbChatQueryWhereSort on QueryBuilder<DbChat, DbChat, QWhere> {
  QueryBuilder<DbChat, DbChat, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbChatQueryWhere on QueryBuilder<DbChat, DbChat, QWhereClause> {
  QueryBuilder<DbChat, DbChat, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterWhereClause> cursorIdEqualTo(
      String cursorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'cursorId',
        value: [cursorId],
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterWhereClause> cursorIdNotEqualTo(
      String cursorId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cursorId',
              lower: [],
              upper: [cursorId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cursorId',
              lower: [cursorId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cursorId',
              lower: [cursorId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cursorId',
              lower: [],
              upper: [cursorId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DbChatQueryFilter on QueryBuilder<DbChat, DbChat, QFilterCondition> {
  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> contextQueriesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contextQueries',
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contextQueries',
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contextQueries',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contextQueries',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contextQueries',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contextQueries',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contextQueries',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contextQueries',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contextQueries',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contextQueries',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contextQueries',
        value: '',
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contextQueries',
        value: '',
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contextQueries',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> contextQueriesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contextQueries',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contextQueries',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contextQueries',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contextQueries',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      contextQueriesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'contextQueries',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cursorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cursorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cursorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cursorId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cursorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cursorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cursorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cursorId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cursorId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> cursorIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cursorId',
        value: '',
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> isFavoriteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> lastMessageTimeEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition>
      lastMessageTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> lastMessageTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageTime',
        value: value,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> lastMessageTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension DbChatQueryObject on QueryBuilder<DbChat, DbChat, QFilterCondition> {}

extension DbChatQueryLinks on QueryBuilder<DbChat, DbChat, QFilterCondition> {
  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> messages(
      FilterQuery<DbMessage> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'messages');
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> messagesLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', length, true, length, true);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> messagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', 0, true, 0, true);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> messagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', 0, false, 999999, true);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> messagesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', 0, true, length, include);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> messagesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', length, include, 999999, true);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> messagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'messages', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> tags(
      FilterQuery<DbTag> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'tags');
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> tagsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'tags', length, true, length, true);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'tags', 0, true, 0, true);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'tags', 0, false, 999999, true);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'tags', 0, true, length, include);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'tags', length, include, 999999, true);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterFilterCondition> tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'tags', lower, includeLower, upper, includeUpper);
    });
  }
}

extension DbChatQuerySortBy on QueryBuilder<DbChat, DbChat, QSortBy> {
  QueryBuilder<DbChat, DbChat, QAfterSortBy> sortByCursorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursorId', Sort.asc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> sortByCursorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursorId', Sort.desc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> sortByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.asc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> sortByLastMessageTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.desc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension DbChatQuerySortThenBy on QueryBuilder<DbChat, DbChat, QSortThenBy> {
  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenByCursorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursorId', Sort.asc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenByCursorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursorId', Sort.desc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.asc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenByLastMessageTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.desc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<DbChat, DbChat, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension DbChatQueryWhereDistinct on QueryBuilder<DbChat, DbChat, QDistinct> {
  QueryBuilder<DbChat, DbChat, QDistinct> distinctByContextQueries() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contextQueries');
    });
  }

  QueryBuilder<DbChat, DbChat, QDistinct> distinctByCursorId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cursorId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbChat, DbChat, QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<DbChat, DbChat, QDistinct> distinctByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageTime');
    });
  }

  QueryBuilder<DbChat, DbChat, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension DbChatQueryProperty on QueryBuilder<DbChat, DbChat, QQueryProperty> {
  QueryBuilder<DbChat, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbChat, List<String>?, QQueryOperations>
      contextQueriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contextQueries');
    });
  }

  QueryBuilder<DbChat, String, QQueryOperations> cursorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cursorId');
    });
  }

  QueryBuilder<DbChat, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<DbChat, DateTime, QQueryOperations> lastMessageTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageTime');
    });
  }

  QueryBuilder<DbChat, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbMessageCollection on Isar {
  IsarCollection<DbMessage> get dbMessages => this.collection();
}

const DbMessageSchema = CollectionSchema(
  name: r'DbMessage',
  id: -2918095356535724979,
  properties: {
    r'content': PropertySchema(
      id: 0,
      name: r'content',
      type: IsarType.string,
    ),
    r'isUser': PropertySchema(
      id: 1,
      name: r'isUser',
      type: IsarType.bool,
    ),
    r'summary': PropertySchema(
      id: 2,
      name: r'summary',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _dbMessageEstimateSize,
  serialize: _dbMessageSerialize,
  deserialize: _dbMessageDeserialize,
  deserializeProp: _dbMessageDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'chat': LinkSchema(
      id: -8716846817128293862,
      name: r'chat',
      target: r'DbChat',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _dbMessageGetId,
  getLinks: _dbMessageGetLinks,
  attach: _dbMessageAttach,
  version: '3.1.0+1',
);

int _dbMessageEstimateSize(
  DbMessage object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  {
    final value = object.summary;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dbMessageSerialize(
  DbMessage object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.content);
  writer.writeBool(offsets[1], object.isUser);
  writer.writeString(offsets[2], object.summary);
  writer.writeDateTime(offsets[3], object.timestamp);
}

DbMessage _dbMessageDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbMessage();
  object.content = reader.readString(offsets[0]);
  object.id = id;
  object.isUser = reader.readBool(offsets[1]);
  object.summary = reader.readStringOrNull(offsets[2]);
  object.timestamp = reader.readDateTime(offsets[3]);
  return object;
}

P _dbMessageDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbMessageGetId(DbMessage object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbMessageGetLinks(DbMessage object) {
  return [object.chat];
}

void _dbMessageAttach(IsarCollection<dynamic> col, Id id, DbMessage object) {
  object.id = id;
  object.chat.attach(col, col.isar.collection<DbChat>(), r'chat', id);
}

extension DbMessageQueryWhereSort
    on QueryBuilder<DbMessage, DbMessage, QWhere> {
  QueryBuilder<DbMessage, DbMessage, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbMessageQueryWhere
    on QueryBuilder<DbMessage, DbMessage, QWhereClause> {
  QueryBuilder<DbMessage, DbMessage, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbMessageQueryFilter
    on QueryBuilder<DbMessage, DbMessage, QFilterCondition> {
  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> contentContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> contentMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> isUserEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUser',
        value: value,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'summary',
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'summary',
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'summary',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'summary',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> summaryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'summary',
        value: '',
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition>
      summaryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'summary',
        value: '',
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> timestampEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DbMessageQueryObject
    on QueryBuilder<DbMessage, DbMessage, QFilterCondition> {}

extension DbMessageQueryLinks
    on QueryBuilder<DbMessage, DbMessage, QFilterCondition> {
  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> chat(
      FilterQuery<DbChat> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'chat');
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterFilterCondition> chatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chat', 0, true, 0, true);
    });
  }
}

extension DbMessageQuerySortBy on QueryBuilder<DbMessage, DbMessage, QSortBy> {
  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> sortByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> sortByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> sortBySummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summary', Sort.asc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> sortBySummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summary', Sort.desc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension DbMessageQuerySortThenBy
    on QueryBuilder<DbMessage, DbMessage, QSortThenBy> {
  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.asc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenByIsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUser', Sort.desc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenBySummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summary', Sort.asc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenBySummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summary', Sort.desc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension DbMessageQueryWhereDistinct
    on QueryBuilder<DbMessage, DbMessage, QDistinct> {
  QueryBuilder<DbMessage, DbMessage, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QDistinct> distinctByIsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUser');
    });
  }

  QueryBuilder<DbMessage, DbMessage, QDistinct> distinctBySummary(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'summary', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DbMessage, DbMessage, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension DbMessageQueryProperty
    on QueryBuilder<DbMessage, DbMessage, QQueryProperty> {
  QueryBuilder<DbMessage, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbMessage, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<DbMessage, bool, QQueryOperations> isUserProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUser');
    });
  }

  QueryBuilder<DbMessage, String?, QQueryOperations> summaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'summary');
    });
  }

  QueryBuilder<DbMessage, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDbTagCollection on Isar {
  IsarCollection<DbTag> get dbTags => this.collection();
}

const DbTagSchema = CollectionSchema(
  name: r'DbTag',
  id: 570407730445455127,
  properties: {
    r'color': PropertySchema(
      id: 0,
      name: r'color',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _dbTagEstimateSize,
  serialize: _dbTagSerialize,
  deserialize: _dbTagDeserialize,
  deserializeProp: _dbTagDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'chats': LinkSchema(
      id: 5602982653041563462,
      name: r'chats',
      target: r'DbChat',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _dbTagGetId,
  getLinks: _dbTagGetLinks,
  attach: _dbTagAttach,
  version: '3.1.0+1',
);

int _dbTagEstimateSize(
  DbTag object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _dbTagSerialize(
  DbTag object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.color);
  writer.writeString(offsets[1], object.name);
}

DbTag _dbTagDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DbTag();
  object.color = reader.readLong(offsets[0]);
  object.id = id;
  object.name = reader.readString(offsets[1]);
  return object;
}

P _dbTagDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dbTagGetId(DbTag object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dbTagGetLinks(DbTag object) {
  return [object.chats];
}

void _dbTagAttach(IsarCollection<dynamic> col, Id id, DbTag object) {
  object.id = id;
  object.chats.attach(col, col.isar.collection<DbChat>(), r'chats', id);
}

extension DbTagByIndex on IsarCollection<DbTag> {
  Future<DbTag?> getByName(String name) {
    return getByIndex(r'name', [name]);
  }

  DbTag? getByNameSync(String name) {
    return getByIndexSync(r'name', [name]);
  }

  Future<bool> deleteByName(String name) {
    return deleteByIndex(r'name', [name]);
  }

  bool deleteByNameSync(String name) {
    return deleteByIndexSync(r'name', [name]);
  }

  Future<List<DbTag?>> getAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndex(r'name', values);
  }

  List<DbTag?> getAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'name', values);
  }

  Future<int> deleteAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'name', values);
  }

  int deleteAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'name', values);
  }

  Future<Id> putByName(DbTag object) {
    return putByIndex(r'name', object);
  }

  Id putByNameSync(DbTag object, {bool saveLinks = true}) {
    return putByIndexSync(r'name', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByName(List<DbTag> objects) {
    return putAllByIndex(r'name', objects);
  }

  List<Id> putAllByNameSync(List<DbTag> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'name', objects, saveLinks: saveLinks);
  }
}

extension DbTagQueryWhereSort on QueryBuilder<DbTag, DbTag, QWhere> {
  QueryBuilder<DbTag, DbTag, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DbTagQueryWhere on QueryBuilder<DbTag, DbTag, QWhereClause> {
  QueryBuilder<DbTag, DbTag, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterWhereClause> nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterWhereClause> nameNotEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DbTagQueryFilter on QueryBuilder<DbTag, DbTag, QFilterCondition> {
  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> colorEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'color',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> colorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'color',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> colorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'color',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> colorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'color',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension DbTagQueryObject on QueryBuilder<DbTag, DbTag, QFilterCondition> {}

extension DbTagQueryLinks on QueryBuilder<DbTag, DbTag, QFilterCondition> {
  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> chats(
      FilterQuery<DbChat> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'chats');
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> chatsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chats', length, true, length, true);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> chatsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chats', 0, true, 0, true);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> chatsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chats', 0, false, 999999, true);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> chatsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chats', 0, true, length, include);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> chatsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chats', length, include, 999999, true);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterFilterCondition> chatsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'chats', lower, includeLower, upper, includeUpper);
    });
  }
}

extension DbTagQuerySortBy on QueryBuilder<DbTag, DbTag, QSortBy> {
  QueryBuilder<DbTag, DbTag, QAfterSortBy> sortByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterSortBy> sortByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension DbTagQuerySortThenBy on QueryBuilder<DbTag, DbTag, QSortThenBy> {
  QueryBuilder<DbTag, DbTag, QAfterSortBy> thenByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterSortBy> thenByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DbTag, DbTag, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension DbTagQueryWhereDistinct on QueryBuilder<DbTag, DbTag, QDistinct> {
  QueryBuilder<DbTag, DbTag, QDistinct> distinctByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'color');
    });
  }

  QueryBuilder<DbTag, DbTag, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension DbTagQueryProperty on QueryBuilder<DbTag, DbTag, QQueryProperty> {
  QueryBuilder<DbTag, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DbTag, int, QQueryOperations> colorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'color');
    });
  }

  QueryBuilder<DbTag, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSearchIndexCollection on Isar {
  IsarCollection<SearchIndex> get searchIndexs => this.collection();
}

const SearchIndexSchema = CollectionSchema(
  name: r'SearchIndex',
  id: 4768691469594422700,
  properties: {
    r'isChat': PropertySchema(
      id: 0,
      name: r'isChat',
      type: IsarType.bool,
    ),
    r'refId': PropertySchema(
      id: 1,
      name: r'refId',
      type: IsarType.long,
    ),
    r'text': PropertySchema(
      id: 2,
      name: r'text',
      type: IsarType.string,
    ),
    r'vector': PropertySchema(
      id: 3,
      name: r'vector',
      type: IsarType.doubleList,
    )
  },
  estimateSize: _searchIndexEstimateSize,
  serialize: _searchIndexSerialize,
  deserialize: _searchIndexDeserialize,
  deserializeProp: _searchIndexDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _searchIndexGetId,
  getLinks: _searchIndexGetLinks,
  attach: _searchIndexAttach,
  version: '3.1.0+1',
);

int _searchIndexEstimateSize(
  SearchIndex object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.text.length * 3;
  bytesCount += 3 + object.vector.length * 8;
  return bytesCount;
}

void _searchIndexSerialize(
  SearchIndex object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isChat);
  writer.writeLong(offsets[1], object.refId);
  writer.writeString(offsets[2], object.text);
  writer.writeDoubleList(offsets[3], object.vector);
}

SearchIndex _searchIndexDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SearchIndex();
  object.id = id;
  object.isChat = reader.readBool(offsets[0]);
  object.refId = reader.readLong(offsets[1]);
  object.text = reader.readString(offsets[2]);
  object.vector = reader.readDoubleList(offsets[3]) ?? [];
  return object;
}

P _searchIndexDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDoubleList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _searchIndexGetId(SearchIndex object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _searchIndexGetLinks(SearchIndex object) {
  return [];
}

void _searchIndexAttach(
    IsarCollection<dynamic> col, Id id, SearchIndex object) {
  object.id = id;
}

extension SearchIndexQueryWhereSort
    on QueryBuilder<SearchIndex, SearchIndex, QWhere> {
  QueryBuilder<SearchIndex, SearchIndex, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SearchIndexQueryWhere
    on QueryBuilder<SearchIndex, SearchIndex, QWhereClause> {
  QueryBuilder<SearchIndex, SearchIndex, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SearchIndexQueryFilter
    on QueryBuilder<SearchIndex, SearchIndex, QFilterCondition> {
  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> isChatEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isChat',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> refIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'refId',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      refIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'refId',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> refIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'refId',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> refIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'refId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> textContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> textMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vector',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vector',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vector',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vector',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterFilterCondition>
      vectorLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'vector',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension SearchIndexQueryObject
    on QueryBuilder<SearchIndex, SearchIndex, QFilterCondition> {}

extension SearchIndexQueryLinks
    on QueryBuilder<SearchIndex, SearchIndex, QFilterCondition> {}

extension SearchIndexQuerySortBy
    on QueryBuilder<SearchIndex, SearchIndex, QSortBy> {
  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> sortByIsChat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isChat', Sort.asc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> sortByIsChatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isChat', Sort.desc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> sortByRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refId', Sort.asc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> sortByRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refId', Sort.desc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }
}

extension SearchIndexQuerySortThenBy
    on QueryBuilder<SearchIndex, SearchIndex, QSortThenBy> {
  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> thenByIsChat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isChat', Sort.asc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> thenByIsChatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isChat', Sort.desc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> thenByRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refId', Sort.asc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> thenByRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refId', Sort.desc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QAfterSortBy> thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }
}

extension SearchIndexQueryWhereDistinct
    on QueryBuilder<SearchIndex, SearchIndex, QDistinct> {
  QueryBuilder<SearchIndex, SearchIndex, QDistinct> distinctByIsChat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isChat');
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QDistinct> distinctByRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'refId');
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QDistinct> distinctByText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SearchIndex, SearchIndex, QDistinct> distinctByVector() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vector');
    });
  }
}

extension SearchIndexQueryProperty
    on QueryBuilder<SearchIndex, SearchIndex, QQueryProperty> {
  QueryBuilder<SearchIndex, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SearchIndex, bool, QQueryOperations> isChatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isChat');
    });
  }

  QueryBuilder<SearchIndex, int, QQueryOperations> refIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'refId');
    });
  }

  QueryBuilder<SearchIndex, String, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<SearchIndex, List<double>, QQueryOperations> vectorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vector');
    });
  }
}
