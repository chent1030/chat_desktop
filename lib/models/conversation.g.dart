// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetConversationCollection on Isar {
  IsarCollection<Conversation> get conversations => this.collection();
}

const ConversationSchema = CollectionSchema(
  name: r'Conversation',
  id: 7261696243536555740,
  properties: {
    r'agentId': PropertySchema(
      id: 0,
      name: r'agentId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isActive': PropertySchema(
      id: 2,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'isPinned': PropertySchema(
      id: 3,
      name: r'isPinned',
      type: IsarType.bool,
    ),
    r'lastMessageContent': PropertySchema(
      id: 4,
      name: r'lastMessageContent',
      type: IsarType.string,
    ),
    r'messageCount': PropertySchema(
      id: 5,
      name: r'messageCount',
      type: IsarType.long,
    ),
    r'metadata': PropertySchema(
      id: 6,
      name: r'metadata',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 7,
      name: r'title',
      type: IsarType.string,
    ),
    r'totalTokens': PropertySchema(
      id: 8,
      name: r'totalTokens',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _conversationEstimateSize,
  serialize: _conversationSerialize,
  deserialize: _conversationDeserialize,
  deserializeProp: _conversationDeserializeProp,
  idName: r'id',
  indexes: {
    r'agentId': IndexSchema(
      id: 7133481944148491938,
      name: r'agentId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'agentId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'isActive': IndexSchema(
      id: 8092228061260947457,
      name: r'isActive',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isActive',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _conversationGetId,
  getLinks: _conversationGetLinks,
  attach: _conversationAttach,
  version: '3.1.0+1',
);

int _conversationEstimateSize(
  Conversation object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.agentId.length * 3;
  {
    final value = object.lastMessageContent;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.metadata;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _conversationSerialize(
  Conversation object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.agentId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeBool(offsets[2], object.isActive);
  writer.writeBool(offsets[3], object.isPinned);
  writer.writeString(offsets[4], object.lastMessageContent);
  writer.writeLong(offsets[5], object.messageCount);
  writer.writeString(offsets[6], object.metadata);
  writer.writeString(offsets[7], object.title);
  writer.writeLong(offsets[8], object.totalTokens);
  writer.writeDateTime(offsets[9], object.updatedAt);
}

Conversation _conversationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Conversation(
    agentId: reader.readString(offsets[0]),
    createdAt: reader.readDateTime(offsets[1]),
    id: id,
    isActive: reader.readBoolOrNull(offsets[2]) ?? true,
    isPinned: reader.readBoolOrNull(offsets[3]) ?? false,
    lastMessageContent: reader.readStringOrNull(offsets[4]),
    messageCount: reader.readLongOrNull(offsets[5]) ?? 0,
    metadata: reader.readStringOrNull(offsets[6]),
    title: reader.readStringOrNull(offsets[7]) ?? '新对话',
    totalTokens: reader.readLongOrNull(offsets[8]),
    updatedAt: reader.readDateTime(offsets[9]),
  );
  return object;
}

P _conversationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset) ?? '新对话') as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _conversationGetId(Conversation object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _conversationGetLinks(Conversation object) {
  return [];
}

void _conversationAttach(
    IsarCollection<dynamic> col, Id id, Conversation object) {
  object.id = id;
}

extension ConversationQueryWhereSort
    on QueryBuilder<Conversation, Conversation, QWhere> {
  QueryBuilder<Conversation, Conversation, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhere> anyIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isActive'),
      );
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension ConversationQueryWhere
    on QueryBuilder<Conversation, Conversation, QWhereClause> {
  QueryBuilder<Conversation, Conversation, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> idBetween(
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

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> agentIdEqualTo(
      String agentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'agentId',
        value: [agentId],
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> agentIdNotEqualTo(
      String agentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'agentId',
              lower: [],
              upper: [agentId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'agentId',
              lower: [agentId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'agentId',
              lower: [agentId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'agentId',
              lower: [],
              upper: [agentId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> isActiveEqualTo(
      bool isActive) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isActive',
        value: [isActive],
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause>
      isActiveNotEqualTo(bool isActive) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [],
              upper: [isActive],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [isActive],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [isActive],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [],
              upper: [isActive],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> createdAtEqualTo(
      DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause>
      createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> updatedAtEqualTo(
      DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAt',
        value: [updatedAt],
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause>
      updatedAtNotEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause>
      updatedAtGreaterThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [updatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> updatedAtLessThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [],
        upper: [updatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterWhereClause> updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [lowerUpdatedAt],
        includeLower: includeLower,
        upper: [upperUpdatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ConversationQueryFilter
    on QueryBuilder<Conversation, Conversation, QFilterCondition> {
  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'agentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'agentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'agentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'agentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'agentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'agentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'agentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'agentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'agentId',
        value: '',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      agentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'agentId',
        value: '',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      isPinnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPinned',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastMessageContent',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastMessageContent',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageContent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastMessageContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastMessageContent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageContent',
        value: '',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      lastMessageContentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastMessageContent',
        value: '',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      messageCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      messageCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      messageCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      messageCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'metadata',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'metadata',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'metadata',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'metadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'metadata',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadata',
        value: '',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      metadataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'metadata',
        value: '',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> titleEqualTo(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      titleGreaterThan(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> titleLessThan(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> titleBetween(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      titleStartsWith(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> titleEndsWith(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> titleContains(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition> titleMatches(
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

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      totalTokensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalTokens',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      totalTokensIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalTokens',
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      totalTokensEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      totalTokensGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      totalTokensLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalTokens',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      totalTokensBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalTokens',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ConversationQueryObject
    on QueryBuilder<Conversation, Conversation, QFilterCondition> {}

extension ConversationQueryLinks
    on QueryBuilder<Conversation, Conversation, QFilterCondition> {}

extension ConversationQuerySortBy
    on QueryBuilder<Conversation, Conversation, QSortBy> {
  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByAgentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentId', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByAgentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentId', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy>
      sortByLastMessageContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageContent', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy>
      sortByLastMessageContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageContent', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy>
      sortByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByTotalTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokens', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy>
      sortByTotalTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokens', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ConversationQuerySortThenBy
    on QueryBuilder<Conversation, Conversation, QSortThenBy> {
  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByAgentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentId', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByAgentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentId', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy>
      thenByLastMessageContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageContent', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy>
      thenByLastMessageContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageContent', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy>
      thenByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadata', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByTotalTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokens', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy>
      thenByTotalTokensDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTokens', Sort.desc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Conversation, Conversation, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ConversationQueryWhereDistinct
    on QueryBuilder<Conversation, Conversation, QDistinct> {
  QueryBuilder<Conversation, Conversation, QDistinct> distinctByAgentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'agentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Conversation, Conversation, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Conversation, Conversation, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<Conversation, Conversation, QDistinct> distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<Conversation, Conversation, QDistinct>
      distinctByLastMessageContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageContent',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Conversation, Conversation, QDistinct> distinctByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageCount');
    });
  }

  QueryBuilder<Conversation, Conversation, QDistinct> distinctByMetadata(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadata', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Conversation, Conversation, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Conversation, Conversation, QDistinct> distinctByTotalTokens() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalTokens');
    });
  }

  QueryBuilder<Conversation, Conversation, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ConversationQueryProperty
    on QueryBuilder<Conversation, Conversation, QQueryProperty> {
  QueryBuilder<Conversation, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Conversation, String, QQueryOperations> agentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'agentId');
    });
  }

  QueryBuilder<Conversation, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Conversation, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<Conversation, bool, QQueryOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<Conversation, String?, QQueryOperations>
      lastMessageContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageContent');
    });
  }

  QueryBuilder<Conversation, int, QQueryOperations> messageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageCount');
    });
  }

  QueryBuilder<Conversation, String?, QQueryOperations> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadata');
    });
  }

  QueryBuilder<Conversation, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<Conversation, int?, QQueryOperations> totalTokensProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalTokens');
    });
  }

  QueryBuilder<Conversation, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
