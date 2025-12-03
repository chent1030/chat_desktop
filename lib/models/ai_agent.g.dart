// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_agent.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAIAgentCollection on Isar {
  IsarCollection<AIAgent> get aIAgents => this.collection();
}

const AIAgentSchema = CollectionSchema(
  name: r'AIAgent',
  id: -1825643882321588297,
  properties: {
    r'agentId': PropertySchema(
      id: 0,
      name: r'agentId',
      type: IsarType.string,
    ),
    r'apiEndpoint': PropertySchema(
      id: 1,
      name: r'apiEndpoint',
      type: IsarType.string,
    ),
    r'apiKey': PropertySchema(
      id: 2,
      name: r'apiKey',
      type: IsarType.string,
    ),
    r'avatar': PropertySchema(
      id: 3,
      name: r'avatar',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'endpoint': PropertySchema(
      id: 6,
      name: r'endpoint',
      type: IsarType.string,
    ),
    r'isDefault': PropertySchema(
      id: 7,
      name: r'isDefault',
      type: IsarType.bool,
    ),
    r'isEnabled': PropertySchema(
      id: 8,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'isPreset': PropertySchema(
      id: 9,
      name: r'isPreset',
      type: IsarType.bool,
    ),
    r'lastUsedAt': PropertySchema(
      id: 10,
      name: r'lastUsedAt',
      type: IsarType.dateTime,
    ),
    r'messageCount': PropertySchema(
      id: 11,
      name: r'messageCount',
      type: IsarType.long,
    ),
    r'modelName': PropertySchema(
      id: 12,
      name: r'modelName',
      type: IsarType.string,
    ),
    r'modelParams': PropertySchema(
      id: 13,
      name: r'modelParams',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 14,
      name: r'name',
      type: IsarType.string,
    ),
    r'sortOrder': PropertySchema(
      id: 15,
      name: r'sortOrder',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 16,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _aIAgentEstimateSize,
  serialize: _aIAgentSerialize,
  deserialize: _aIAgentDeserialize,
  deserializeProp: _aIAgentDeserializeProp,
  idName: r'id',
  indexes: {
    r'agentId': IndexSchema(
      id: 7133481944148491938,
      name: r'agentId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'agentId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _aIAgentGetId,
  getLinks: _aIAgentGetLinks,
  attach: _aIAgentAttach,
  version: '3.1.0+1',
);

int _aIAgentEstimateSize(
  AIAgent object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.agentId.length * 3;
  bytesCount += 3 + object.apiEndpoint.length * 3;
  {
    final value = object.apiKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.avatar;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.endpoint.length * 3;
  {
    final value = object.modelName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.modelParams;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _aIAgentSerialize(
  AIAgent object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.agentId);
  writer.writeString(offsets[1], object.apiEndpoint);
  writer.writeString(offsets[2], object.apiKey);
  writer.writeString(offsets[3], object.avatar);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeString(offsets[5], object.description);
  writer.writeString(offsets[6], object.endpoint);
  writer.writeBool(offsets[7], object.isDefault);
  writer.writeBool(offsets[8], object.isEnabled);
  writer.writeBool(offsets[9], object.isPreset);
  writer.writeDateTime(offsets[10], object.lastUsedAt);
  writer.writeLong(offsets[11], object.messageCount);
  writer.writeString(offsets[12], object.modelName);
  writer.writeString(offsets[13], object.modelParams);
  writer.writeString(offsets[14], object.name);
  writer.writeLong(offsets[15], object.sortOrder);
  writer.writeDateTime(offsets[16], object.updatedAt);
}

AIAgent _aIAgentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AIAgent(
    agentId: reader.readString(offsets[0]),
    apiKey: reader.readStringOrNull(offsets[2]),
    avatar: reader.readStringOrNull(offsets[3]),
    createdAt: reader.readDateTime(offsets[4]),
    description: reader.readStringOrNull(offsets[5]),
    endpoint: reader.readString(offsets[6]),
    id: id,
    isDefault: reader.readBoolOrNull(offsets[7]) ?? false,
    isEnabled: reader.readBoolOrNull(offsets[8]) ?? true,
    isPreset: reader.readBoolOrNull(offsets[9]) ?? false,
    lastUsedAt: reader.readDateTime(offsets[10]),
    messageCount: reader.readLongOrNull(offsets[11]) ?? 0,
    modelName: reader.readStringOrNull(offsets[12]),
    modelParams: reader.readStringOrNull(offsets[13]),
    name: reader.readString(offsets[14]),
    sortOrder: reader.readLongOrNull(offsets[15]) ?? 0,
    updatedAt: reader.readDateTime(offsets[16]),
  );
  return object;
}

P _aIAgentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 8:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 9:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _aIAgentGetId(AIAgent object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _aIAgentGetLinks(AIAgent object) {
  return [];
}

void _aIAgentAttach(IsarCollection<dynamic> col, Id id, AIAgent object) {
  object.id = id;
}

extension AIAgentByIndex on IsarCollection<AIAgent> {
  Future<AIAgent?> getByAgentId(String agentId) {
    return getByIndex(r'agentId', [agentId]);
  }

  AIAgent? getByAgentIdSync(String agentId) {
    return getByIndexSync(r'agentId', [agentId]);
  }

  Future<bool> deleteByAgentId(String agentId) {
    return deleteByIndex(r'agentId', [agentId]);
  }

  bool deleteByAgentIdSync(String agentId) {
    return deleteByIndexSync(r'agentId', [agentId]);
  }

  Future<List<AIAgent?>> getAllByAgentId(List<String> agentIdValues) {
    final values = agentIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'agentId', values);
  }

  List<AIAgent?> getAllByAgentIdSync(List<String> agentIdValues) {
    final values = agentIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'agentId', values);
  }

  Future<int> deleteAllByAgentId(List<String> agentIdValues) {
    final values = agentIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'agentId', values);
  }

  int deleteAllByAgentIdSync(List<String> agentIdValues) {
    final values = agentIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'agentId', values);
  }

  Future<Id> putByAgentId(AIAgent object) {
    return putByIndex(r'agentId', object);
  }

  Id putByAgentIdSync(AIAgent object, {bool saveLinks = true}) {
    return putByIndexSync(r'agentId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByAgentId(List<AIAgent> objects) {
    return putAllByIndex(r'agentId', objects);
  }

  List<Id> putAllByAgentIdSync(List<AIAgent> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'agentId', objects, saveLinks: saveLinks);
  }
}

extension AIAgentQueryWhereSort on QueryBuilder<AIAgent, AIAgent, QWhere> {
  QueryBuilder<AIAgent, AIAgent, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AIAgentQueryWhere on QueryBuilder<AIAgent, AIAgent, QWhereClause> {
  QueryBuilder<AIAgent, AIAgent, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<AIAgent, AIAgent, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterWhereClause> idBetween(
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

  QueryBuilder<AIAgent, AIAgent, QAfterWhereClause> agentIdEqualTo(
      String agentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'agentId',
        value: [agentId],
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterWhereClause> agentIdNotEqualTo(
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
}

extension AIAgentQueryFilter
    on QueryBuilder<AIAgent, AIAgent, QFilterCondition> {
  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdEqualTo(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdGreaterThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdLessThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdBetween(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdStartsWith(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdEndsWith(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'agentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'agentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'agentId',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> agentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'agentId',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiEndpointEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiEndpointGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'apiEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiEndpointLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'apiEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiEndpointBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'apiEndpoint',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiEndpointStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'apiEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiEndpointEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'apiEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiEndpointContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'apiEndpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiEndpointMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'apiEndpoint',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiEndpointIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiEndpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition>
      apiEndpointIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'apiEndpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'apiKey',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'apiKey',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'apiKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'apiKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'apiKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> apiKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'apiKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatar',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatar',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatar',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatar',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> avatarIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatar',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endpoint',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'endpoint',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> endpointIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'endpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> idBetween(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> isDefaultEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDefault',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> isEnabledEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> isPresetEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPreset',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> lastUsedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUsedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> lastUsedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUsedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> lastUsedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUsedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> lastUsedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUsedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> messageCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> messageCountGreaterThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> messageCountLessThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> messageCountBetween(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'modelName',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'modelName',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modelName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modelName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modelName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelName',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modelName',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'modelParams',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'modelParams',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelParams',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modelParams',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modelParams',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modelParams',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modelParams',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modelParams',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modelParams',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modelParams',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> modelParamsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modelParams',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition>
      modelParamsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modelParams',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> sortOrderEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> sortOrderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> sortOrderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> sortOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sortOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<AIAgent, AIAgent, QAfterFilterCondition> updatedAtBetween(
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

extension AIAgentQueryObject
    on QueryBuilder<AIAgent, AIAgent, QFilterCondition> {}

extension AIAgentQueryLinks
    on QueryBuilder<AIAgent, AIAgent, QFilterCondition> {}

extension AIAgentQuerySortBy on QueryBuilder<AIAgent, AIAgent, QSortBy> {
  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByAgentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentId', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByAgentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentId', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByApiEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiEndpoint', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByApiEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiEndpoint', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatar', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatar', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByIsPreset() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPreset', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByIsPresetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPreset', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByLastUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByModelParams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelParams', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByModelParamsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelParams', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AIAgentQuerySortThenBy
    on QueryBuilder<AIAgent, AIAgent, QSortThenBy> {
  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByAgentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentId', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByAgentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'agentId', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByApiEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiEndpoint', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByApiEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiEndpoint', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByApiKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByApiKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiKey', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatar', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatar', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByIsDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDefault', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByIsPreset() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPreset', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByIsPresetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPreset', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByLastUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByModelName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByModelNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelName', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByModelParams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelParams', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByModelParamsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modelParams', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AIAgentQueryWhereDistinct
    on QueryBuilder<AIAgent, AIAgent, QDistinct> {
  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByAgentId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'agentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByApiEndpoint(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apiEndpoint', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByApiKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apiKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByAvatar(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatar', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByEndpoint(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endpoint', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByIsDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDefault');
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByIsPreset() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPreset');
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUsedAt');
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageCount');
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByModelName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByModelParams(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modelParams', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sortOrder');
    });
  }

  QueryBuilder<AIAgent, AIAgent, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension AIAgentQueryProperty
    on QueryBuilder<AIAgent, AIAgent, QQueryProperty> {
  QueryBuilder<AIAgent, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AIAgent, String, QQueryOperations> agentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'agentId');
    });
  }

  QueryBuilder<AIAgent, String, QQueryOperations> apiEndpointProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apiEndpoint');
    });
  }

  QueryBuilder<AIAgent, String?, QQueryOperations> apiKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apiKey');
    });
  }

  QueryBuilder<AIAgent, String?, QQueryOperations> avatarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatar');
    });
  }

  QueryBuilder<AIAgent, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<AIAgent, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<AIAgent, String, QQueryOperations> endpointProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endpoint');
    });
  }

  QueryBuilder<AIAgent, bool, QQueryOperations> isDefaultProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDefault');
    });
  }

  QueryBuilder<AIAgent, bool, QQueryOperations> isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<AIAgent, bool, QQueryOperations> isPresetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPreset');
    });
  }

  QueryBuilder<AIAgent, DateTime, QQueryOperations> lastUsedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUsedAt');
    });
  }

  QueryBuilder<AIAgent, int, QQueryOperations> messageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageCount');
    });
  }

  QueryBuilder<AIAgent, String?, QQueryOperations> modelNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelName');
    });
  }

  QueryBuilder<AIAgent, String?, QQueryOperations> modelParamsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modelParams');
    });
  }

  QueryBuilder<AIAgent, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<AIAgent, int, QQueryOperations> sortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sortOrder');
    });
  }

  QueryBuilder<AIAgent, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
