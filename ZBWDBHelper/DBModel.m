//
//  DBModel.m
//  Template
//
//  Created by Bowen on 15/9/1.
//  Copyright (c) 2015年 Bowen. All rights reserved.
//

#import "DBModel.h"
#import <objc/runtime.h>
#import <FMDB/FMDB.h>
#import "DBHelper.h"
#import <objc/message.h>
#import "DBTableChange.h"
#import "DBProperty.h"

#define kDBModel_INVALID_ID     (-999)

static void * DBModel_ModelProperyMap;              // model属性名称 - 属性对象 映射关系
static void * DBModel_TableFieldMap;                // 表字段名称 - 属性对象 映射关系
static void * DBModel_TableFieldList;               // 表字段列表
static void * DBModel_TableFieldTypeList;

@implementation DBModel

+ (void)initialize
{
    if (self != [DBModel class]) {
//        [self DB_createTable];
        [self DB_initTable];
    }
}

#pragma mark- Public
- (instancetype)init {
    if (self = [super init]) {
#if DB_AUTOCREATE_PRIMARY_KEY
        self.id = kDBModel_INVALID_ID;
#endif
    }
    return self;
}

#pragma mark- private
+ (DBHelper *)dbHelper {
    return [DBHelper dbHelperWithAlias:[self DB_databaseAlias]];
}

#pragma mark- 保存操作（insert、update）
- (BOOL)DB_save
{
    return [self _DB_save:YES];
}

- (BOOL)DB_saveSelective {
    return [self _DB_saveSelective:YES];
}

+ (BOOL)DB_saveList:(NSArray *)itemList
{
    return [self _DB_saveList:itemList needReplace:YES];
}

+ (BOOL)DB_saveListSelective:(NSArray *)itemList
{
    return [self _DB_saveListSelective:itemList needReplace:YES];
}


// 插入/更新 所有字段
- (BOOL)DB_saveNotReplace {
    return [self _DB_save:NO];
}
+ (BOOL)DB_saveListNotReplace:(NSArray *)itemList {
    return [self _DB_saveList:itemList needReplace:NO];
}

// 插入/更新 非空字段
- (BOOL)DB_saveSelectiveNotReplace {
    return [self _DB_saveSelective:NO];
}
+ (BOOL)DB_saveListSelectiveNotReplace:(NSArray *)itemList {
    return [self _DB_saveListSelective:itemList needReplace:NO];
}


- (BOOL)_DB_save:(BOOL)needReplace
{
    // 主键是否有值
    if (![self DB_isPrimaryValueValid])
    {
        return NO;
    }
    
    __block BOOL result = NO;
    
    __weak typeof(self) _self = self;
    [[self.class dbHelper] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        result = [db executeUpdate:[[_self class] DB_sqlForInsert:YES] withArgumentsInArray:[_self DB_valuesForInsert]];
        
        if (result) {
#if DB_AUTOCREATE_PRIMARY_KEY
            if (_self.id == kDBModel_INVALID_ID) {
                _self.id = [db lastInsertRowId];
            }
#endif
        }
    }
     ];
    
    return result;
}

- (BOOL)_DB_saveSelective:(BOOL)needReplace {
    // 主键是否有值
    if (![self DB_isPrimaryValueValid])
    {
        return NO;
    }
    
    __block BOOL result = NO;
    
    __weak typeof(self) _self = self;
    [[self.class dbHelper] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSArray *selectiveFields = [_self DB_selectiveFields];
        if (selectiveFields.count == 0) {
            return;
        }
        result = [db executeUpdate:[_self DB_sqlForSaveSelective:selectiveFields needReplace:YES]
              withArgumentsInArray:[_self DB_valuesForFields:selectiveFields]];
        
        if (result) {
#if DB_AUTOCREATE_PRIMARY_KEY
            if (_self.id == kDBModel_INVALID_ID) {
                _self.id = [db lastInsertRowId];
            }
#endif
        }
    }
     ];
    
    return result;
}

+ (BOOL)_DB_saveList:(NSArray *)itemList needReplace:(BOOL)needReplace
{
    __block BOOL result = YES;
    [[self dbHelper] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (DBModel* item in itemList)
        {
            BOOL ret = NO;
            // 主键值 存在
            if (![(DBModel *)item DB_isPrimaryValueValid])
            {
                result = NO;
                continue;
            }
            
            ret = [db executeUpdate:[[self class] DB_sqlForInsert:needReplace] withArgumentsInArray:[item DB_valuesForInsert]];
            
            if (!ret)
            {
                result = NO;
            }
            else {
#if DB_AUTOCREATE_PRIMARY_KEY
                if (item.id == kDBModel_INVALID_ID) {
                    item.id = [db lastInsertRowId];
                }
#endif
            }
        }
    }
     ];
    
    return result;
}

+ (BOOL)_DB_saveListSelective:(NSArray *)itemList needReplace:(BOOL)needReplace
{
    __block BOOL result = YES;
    [[self dbHelper] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (DBModel* item in itemList)
        {
            BOOL ret = NO;
            // 主键值 存在
            if (![(DBModel *)item DB_isPrimaryValueValid])
            {
                result = NO;
                continue;
            }
            
            NSArray *selectiveFields = [item DB_selectiveFields];
            if (selectiveFields.count == 0) {
                return;
            }
            result = [db executeUpdate:[item DB_sqlForSaveSelective:selectiveFields needReplace:needReplace]
                  withArgumentsInArray:[item DB_valuesForFields:selectiveFields]];
            
            if (!ret)
            {
                result = NO;
            }
            else {
#if DB_AUTOCREATE_PRIMARY_KEY
                if (item.id == kDBModel_INVALID_ID) {
                    item.id = [db lastInsertRowId];
                }
#endif
            }
        }
    }
     ];
    
    return result;
}

#pragma mark- 删除操作 （delete、drop)


- (BOOL)DB_delete
{
    __block BOOL result = NO;
    __weak typeof(self) _self = self;
    [[self.class dbHelper] inDatabase:^(FMDatabase *db){
        result = [db executeUpdate:[[_self class] DB_sqlForDelete] withArgumentsInArray:[_self DB_valuesForPrimary]];
    }];
    
    return result;
}

+ (BOOL)DB_deleteList:(NSArray *)itemList
{
    __block BOOL result = YES;
    
    [[self dbHelper] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (DBModel* item in itemList)
        {
            BOOL ret = NO;
            // 主键值 存在
            if (![item DB_isPrimaryValueValid])
            {
                result = NO;
                continue;
            }
            
            ret = [db executeUpdate:[self DB_sqlForDelete] withArgumentsInArray:[item DB_valuesForPrimary]];
            
            if (!ret)
            {
                result = NO;
            }
        }
    }
    ];
    
    return result;
}

+ (BOOL)DB_clearTable
{
    __block BOOL result = YES;
    [[self dbHelper] inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:[NSString stringWithFormat:@"delete from %@",[self DB_tableName]]];
    }
    ];
    
    return result;
}

+ (BOOL)DB_deleteById:(NSInteger)pkId {
    return [self DB_deleteWithCondition:@"id = ? " argumentsInArray:@[@(pkId)]];
}

+ (BOOL)DB_deleteWithCondition:(NSString *)where argumentsInArray:(NSArray *)arguments {
    NSString *sqlStr = [NSString stringWithFormat:@"delete from %@", [self DB_tableName]];
    if (where) {
        sqlStr = [NSString stringWithFormat:@"%@ where %@",sqlStr, where];
    }
    
    __block BOOL result = YES;
    [[self dbHelper] inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sqlStr withArgumentsInArray:arguments];
    }
    ];
    
    return result;
}


+ (BOOL)DB_dropTable
{
    __block BOOL result = YES;

    [[self dbHelper] inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:[NSString stringWithFormat:@"drop table %@",[self DB_tableName]]];
    }
    ];
    
    return result;
}

#pragma mark- Query 查询表

+ (id)DB_queryById:(NSInteger)pkId {
    NSArray *array = [self DB_queryRecordsWithFields:nil
                                            distinct:NO
                                           condition:@"id = ?"
                                             orderBy:nil
                                             descend:YES
                                               range:NSMakeRange(-1, 0)
                                    argumentsInArray:@[@(pkId)]];
    
    if (array.count > 0) {
        return [array lastObject];
    }
    return nil;
}

+ (NSArray *)DB_queryAllRecords
{
    return [self DB_queryRecords:nil withArgumentsInArray:nil];
}

+ (NSArray *)DB_queryRecords:(NSString *)condition withArgumentsInArray:(NSArray *)arguments
{
    return [self DB_queryRecords:condition orderBy:nil descend:YES argumentsInArray:arguments];
}

+ (NSArray *)DB_queryRecords:(NSString *)condition
                orderBy:(NSString *)fieldName
                descend:(BOOL)isDescend
       argumentsInArray:(NSArray *)arguments
{
    return [self DB_queryRecords:condition orderBy:fieldName descend:isDescend range:NSMakeRange(-1, 0) argumentsInArray:arguments];
}

+ (NSArray *)DB_queryRecords:(NSString *)condition orderBy:(NSString *)fieldName descend:(BOOL)isDescend range:(NSRange)range argumentsInArray:(NSArray *)arguments
{
    return [self DB_queryRecordsWithFields:nil distinct:NO condition:condition orderBy:fieldName descend:isDescend range:range argumentsInArray:arguments];
}

+ (NSArray *)DB_queryRecordsWithFields:(NSArray *)fields
                              distinct:(BOOL)distinct
                             condition:(NSString *)condition
                               orderBy:(NSString *)fieldName
                               descend:(BOOL)isDescend
                                 range:(NSRange)range
                      argumentsInArray:(NSArray *)arguments {
    NSMutableArray *records = [NSMutableArray arrayWithCapacity:10];
    
    // 校验fields是否存在
    for (NSString *field in fields) {
        if (![[self DB_tableFieldList] containsObject:field]) {
            NSString *errorLog = [NSString stringWithFormat:@"【%@】字段不存在", field];
            NSAssert(NO, errorLog);
        }
    }
    
#if DB_AUTOCREATE_PRIMARY_KEY
    if (fields.count > 0 && ![fields containsObject:@"id"]) {
        fields = [NSMutableArray arrayWithArray:fields];
        [(NSMutableArray *)fields addObject:@"id"];
    }
#endif
    
    NSString *fieldStr = @"*";
    if (fields.count > 0) {
        fieldStr = [fields componentsJoinedByString:@","];
    }
    
    NSString *sqlStr = [NSString stringWithFormat:@"select %@ %@ from %@", (distinct ? @"distinct" :@""), fieldStr, [self DB_tableName]];
    if (condition)
    {
        sqlStr = [NSString stringWithFormat:@"%@ where %@",sqlStr, condition];
    }
    
    if (fieldName && [[self DB_tableFieldList] containsObject:fieldName])
    {
        sqlStr = [NSString stringWithFormat:@"%@ order by %@ %@", sqlStr ,fieldName, isDescend ? @"desc" : @"asc"];
    }
    
    if (range.location != -1) {
        sqlStr = [NSString stringWithFormat:@"%@ limit %ld,%ld", sqlStr, range.location, range.length];
    }
    
    [[self dbHelper] inDatabase:^(FMDatabase *db){
        FMResultSet *resultSet = [db executeQuery:sqlStr withArgumentsInArray:arguments];
        
        NSArray *fieldArray = fields;
        if (fieldArray.count == 0) {
            fieldArray = [self.class DB_tableFieldList];
        }
        NSDictionary *propertyDic = [self.class DB_tableFieldMap];
        
        while ([resultSet next])
        {
            id record = [[self alloc] init];
            for (int i = 0 ; i < fieldArray.count ; i++)
            {
                NSString *fieldName = fieldArray[i];
                DBProperty *property = propertyDic[fieldName];
                NSString *propertyName = property.propertyName;
                
                NSString *type = property.fieldType;
                SEL setter = NSSelectorFromString([self DB_setterMethodName:propertyName]);
                
                id value = [resultSet objectForColumn:fieldName];
                if (value)
                {
                    if (type == DB_SQLITE_BLOB || type == DB_SQLITE_TEXT)
                    {
                        [record setValue:value forKey:propertyName];
                    }
                    else if (type == DB_SQLITE_REAL)
                    {
                        ((void (*) (id, SEL, double))objc_msgSend)(record, setter, [value doubleValue]);
                    }
                    else if ( type == DB_SQLITE_DATE) {
                        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
                        [record setValue:date forKey:propertyName];
                    }
                    else
                    {
                        ((void (*) (id, SEL, NSInteger))objc_msgSend)(record, setter, [value integerValue]);
                    }
                }
            }
            [records addObject:record];
        }
    }
    ];
    
    return records;
}

+ (NSInteger)DB_queryCount:(NSString *)condition argumentsInArray:(NSArray *)arguments
{
    return [self DB_queryCount:condition distinctField:nil argumentsInArray:arguments];
}

+ (NSInteger)DB_queryCount:(NSString *)condition distinctField:(NSString *)fieldName argumentsInArray:(NSArray *)arguments
{
    __block NSInteger count = 0;
    
    NSString *sqlStr = [NSString stringWithFormat:@"select count() from %@ ", [self DB_tableName]];
    if (fieldName && [[self DB_tableFieldList] containsObject:fieldName])
    {
        sqlStr = [NSString stringWithFormat:@"select count(distinct %@) from %@ ", fieldName, [self DB_tableName]];
    }
    if (condition.length > 0)
    {
        sqlStr = [NSString stringWithFormat:@"%@ where %@",sqlStr, condition];
    }

    [[self dbHelper] inDatabase:^(FMDatabase *db) {
        FMResultSet * resultSet = [db executeQuery:sqlStr withArgumentsInArray:arguments];
        while ([resultSet next])
        {
            count = [resultSet longForColumnIndex:0];
            break;
        }
    }
    ];
    
    return count;
}

+ (double)DB_queryAverage:(NSString *)condition field:(NSString *)fieldName argumentsInArray:(NSArray *)arguments
{
    __block double average = 0;
    
    if (!fieldName || ![[self DB_tableFieldList] containsObject:fieldName])
    {
        return average;
    }
    NSString *sqlStr = [NSString stringWithFormat:@"select avg(%@) from %@ ", fieldName, [self DB_tableName]];
    if (condition.length > 0)
    {
        sqlStr = [NSString stringWithFormat:@"%@ where %@",sqlStr, condition];
    }
    
    [[self dbHelper] inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:sqlStr withArgumentsInArray:arguments];
        
        while ([resultSet next])
        {
            average = [resultSet doubleForColumnIndex:0];
            break;
        }
    }
    ];
    
    return average;
}

+ (double)DB_querySum:(NSString *)condition field:(NSString *)fieldName argumentsInArray:(NSArray *)arguments
{
    __block double sum = 0;
    
    if (!fieldName || ![[self DB_tableFieldList] containsObject:fieldName])
    {
        return sum;
    }
    NSString *sqlStr = [NSString stringWithFormat:@"select sum(%@) from %@ ", fieldName, [self DB_tableName]];
    if (condition.length > 0)
    {
        sqlStr = [NSString stringWithFormat:@"%@ where %@",sqlStr, condition];
    }
    
    [[self dbHelper] inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:sqlStr withArgumentsInArray:arguments];
        
        while ([resultSet next])
        {
            sum = [resultSet doubleForColumnIndex:0];
            break;
        }
    }
    ];
    
    return sum;
}

#pragma mark- Private

+ (void)DB_initTable {
    //
    [self DB_initData];
    
    // 从数据库中获取表信息
    [[self dbHelper] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        // 创建 db_version 版本表
        BOOL result = [db executeUpdate:@"create table if not exists db_version (tablename text, version integer default 0, primary key(tablename))"];
        
        // 没有设置版本号，不进行升级处理
        if ([self DB_version] == DB_VERSION_IGNORE_UPDATE) {
            BOOL r = [db executeUpdate:[self DB_sqlForCreateTable]];
            return ;
        }
        
        NSInteger version = -1;
        // 获取当前 table 的版本号
        if (result) {
            FMResultSet* resultSet = [db executeQuery:@"select version from db_version where tablename=?" withArgumentsInArray:@[[self DB_tableName]]];
            
            while (resultSet && [resultSet next]) {
                version = [resultSet longForColumnIndex:0];
                break;
            }
        }
        
        // 没有当前 table 的版本号， 认为没有当前表；
        if (version == -1) {
//            [self DB_dropTable];
//            [self DB_createTable];
            [db executeUpdate:[NSString stringWithFormat:@"drop table %@",[self DB_tableName]]];
            [db executeUpdate:[self DB_sqlForCreateTable]];
            [db executeUpdate:@"insert or replace into db_version(tablename, version) values(?, ?)", [self DB_tableName], @([self DB_version])];
        }
        else {
            // 当前版本已经是最新版本
            if ([self DB_version] == version) {
                return;
            }
            
            // 根据表的版本号，进行版本升级
            NSInteger i = version;
            for (; i < [self DB_version]; i++) {
                BOOL rt = [((DBTableChange *)[self DB_modifyList][i]) updateTable:db tableName:[self DB_tableName]];
                if (!rt) {
                    
                    // 更新version
                    
                    return;
                }
            }
            
            [db executeUpdate:@"update db_version set version=? where tablename = ?", @(i), [self DB_tableName]];
        }
        
    }];
    
    
    
    // 根据表的版本号，进行版本升级
    
    // 不存在表，则直接创建新表
    
    // 更新版本号到数据库中
}

#pragma mark- 创建表
+ (void)DB_createTable
{
    [[self dbHelper] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL result = [db executeUpdate:[self DB_sqlForCreateTable]];
        
//        NSMutableArray *columns = [NSMutableArray arrayWithCapacity:10];
//        FMResultSet *resultSet = [db getTableSchema:[self DB_tableName]];
//        while ([resultSet next]) {
//            NSString *column = [resultSet stringForColumn:@"name"];
//            [columns addObject:column];
//        }
//        
//        NSArray *properties = [self DB_tableFieldList];
//        NSArray *fieldTypeList = [self DB_fieldTypeList];
//        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
//        //过滤数组
//        NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
//        for (NSString *column in resultArray)
//        {
//            NSUInteger index = [properties indexOfObject:column];
//            NSString *proType = [fieldTypeList objectAtIndex:index];
//            NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
//            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",[self DB_tableName],fieldSql];
//            if (![db executeUpdate:sql])
//            {
//                result = NO;
//                *rollback = YES;
//                return ;
//            }
//        }
    }
    ];
}

#pragma mark- values  用于sql中，bing对应参数的values
// 获取制定字段的value数组
- (NSArray *)DB_valuesForFields:(NSArray *)fields
{
    if (fields.count == 0) {
        return nil;
    }
    NSMutableArray *insertValues = [NSMutableArray arrayWithCapacity:fields.count];
    
    NSDictionary *propertyDic = [self.class DB_tableFieldMap];
    
    for (int i = 0 ; i < fields.count; i++)
    {
        NSString *fieldName = fields[i];
        DBProperty *property = propertyDic[fieldName];
        
        id value = [self valueForKey:property.propertyName];
        
#if DB_AUTOCREATE_PRIMARY_KEY
        // primary key id
        if ([fieldName isEqualToString:@"id"]) {
            if ([(NSNumber *)value intValue] == kDBModel_INVALID_ID) {
                value = [NSNull null];
            }
        }
#endif
        
        if (!value)
        {
            value = property.defaultDBValue;
        }
        [insertValues addObject:value];
    }
    return insertValues;
}

// 获取全字段 value数组
- (NSArray *)DB_valuesForInsert
{
    NSMutableArray *insertValues = [NSMutableArray arrayWithCapacity:[[self class] DB_fieldCount]];
    NSArray* tableFieldList = [[self class] DB_tableFieldList];
    
    NSDictionary *propertyDic = [self.class DB_tableFieldMap];
    
    for (int i = 0 ; i < tableFieldList.count; i++)
    {
        NSString *fieldName = tableFieldList[i];
        DBProperty *property = propertyDic[fieldName];
        id value = [self valueForKey:property.propertyName];
        
#if DB_AUTOCREATE_PRIMARY_KEY
        // primary key id
        if ([fieldName isEqualToString:@"id"]) {
            if ([(NSNumber *)value intValue] == kDBModel_INVALID_ID) {
                value = [NSNull null];
            }
        }
#endif
        
        if (!value)
        {
            value = property.defaultDBValue;
        }
        [insertValues addObject:value];
    }
    return insertValues;
}

- (NSArray *)DB_valuesForUpdate
{
    NSMutableArray *argValues = [NSMutableArray arrayWithCapacity:[[self class] DB_fieldCount]];
    NSArray* tableFieldList = [[self class] DB_tableFieldList];
    NSDictionary *propertyDic = [self.class DB_tableFieldMap];
    
    for (int i = 0; i < tableFieldList.count; i++)
    {
        NSString *fieldName = tableFieldList[i];
        DBProperty *property = propertyDic[fieldName];
        id value = [self valueForKey:property.propertyName];
        
#if DB_AUTOCREATE_PRIMARY_KEY
        // primary key id
        if ([fieldName isEqualToString:@"id"]) {
            if ([(NSNumber *)value intValue] == kDBModel_INVALID_ID) {
                value = [NSNull null];
            }
        }
#endif
        if (!value)
        {
            value = property.defaultDBValue;
        }
        [argValues addObject:value];
    }
    [argValues addObjectsFromArray:[self DB_valuesForPrimary]];
    return argValues;
}

- (NSArray *)DB_valuesForPrimary
{
    NSArray *primaryKeys = [[self class] DB_primaryKeys];
    NSMutableArray *primaryValues = [NSMutableArray arrayWithCapacity:5];

    NSDictionary *propertyDic = [self.class DB_tableFieldMap];
    for (int i = 0; i < primaryKeys.count; i++)
    {
        NSString *propertyName = primaryKeys[i];
        DBProperty *property = propertyDic[propertyName];
        
        id value = [self valueForKey:property.propertyName];
        if (!value)
        {
            value = property.defaultDBValue;
        }
        [primaryValues addObject:value];
    }
    return primaryValues;
}

#pragma mark- 属性和表的字段映射

+ (void)DB_initData {
    NSMutableDictionary *propertyDic = objc_getAssociatedObject(self, &DBModel_ModelProperyMap);
    NSMutableDictionary *fieldDic = objc_getAssociatedObject(self, &DBModel_TableFieldMap);
    if (propertyDic) {
        return;
    }
    @synchronized (self) {
        if (propertyDic) {
            return;
        }
        
        NSArray *ignoreArr = [[self class] instancesRespondToSelector:@selector(DB_ignoreProperty)] ? [self DB_ignoreProperty] : nil;
        
        NSDictionary *orm = nil;
        if ([self respondsToSelector:@selector(DB_orm)]) {
            orm = [self DB_orm];
        }
        
        propertyDic = [[NSMutableDictionary alloc] initWithCapacity:10];
        fieldDic = [[NSMutableDictionary alloc] initWithCapacity:10];
        
#if DB_AUTOCREATE_PRIMARY_KEY
        DBProperty *property = [[DBProperty alloc] init];
        property.propertyName = @"id";
        property.fieldName = @"id";
        property.fieldType = DB_SQLITE_INTEGER;
        property.isPrimaryKey = YES;
        
        [propertyDic setObject:property forKey:property.propertyName];
        
        [fieldDic setObject:property forKey:property.fieldName];
#endif
        
        unsigned int propertyCount = 0;
        objc_property_t *propertyList = class_copyPropertyList(self, &propertyCount);
        for (int i = 0; i < propertyCount; i++)
        {
            objc_property_t propertyItem = propertyList[i];
            // 获取属性的name
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(propertyItem)];
            
            // 是否要被忽略
            if ([ignoreArr containsObject:propertyName]) {
                continue;
            }
            
            DBProperty *property = [[DBProperty alloc] init];
            property.propertyName = propertyName;
            property.fieldName = propertyName;
            
            NSString *orm_fieldName = orm[propertyName];
            if (orm_fieldName) {
                property.fieldName = orm_fieldName;
            }
            
            // 获取属性的type
            const char *attr = property_getAttributes(propertyItem);
            NSString *attrStr = [NSString stringWithUTF8String:attr];
            
            property.propertyType = attrStr;
            
            [propertyDic setObject:property forKey:property.propertyName];
            
            [fieldDic setObject:property forKey:property.fieldName];
            //
//            NSLog(@"%@", property.description);
        }
        free(propertyList);
        objc_setAssociatedObject(self, &DBModel_ModelProperyMap, propertyDic, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(self, &DBModel_TableFieldMap, fieldDic, OBJC_ASSOCIATION_RETAIN);
        
        
        // 表字段列表
        NSArray *fieldList = [fieldDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *str1 = obj1;
            NSString *str2 = obj2;
            return [str1 compare:str2 options:NSCaseInsensitiveSearch];
        }];
        
        objc_setAssociatedObject(self, &DBModel_TableFieldList, fieldList, OBJC_ASSOCIATION_RETAIN);
    }
}

+ (NSDictionary *)DB_tableFieldMap {
    return objc_getAssociatedObject(self, &DBModel_TableFieldMap);
}

+ (NSDictionary *)DB_propertyMap {
    return objc_getAssociatedObject(self, &DBModel_ModelProperyMap);
}

+ (NSArray *)DB_tableFieldList
{
    id value = objc_getAssociatedObject(self, &DBModel_TableFieldList);

    return value;
}

+ (NSInteger)DB_fieldCount
{
    return [self DB_tableFieldList].count;
}

#pragma mark- DBModelProtocol
+ (NSString *)DB_databaseAlias {
    return nil;
}

+ (NSString *)DB_tableName
{
    return nil;
}

+ (NSArray *)DB_ignoreProperty
{
    return nil;
}

+ (NSArray *)DB_primaryKeys
{
    return @[@"id"];
}

+ (NSArray *)DB_uniqueKeys
{
    return nil;
}

+ (NSInteger)DB_version {
    return DB_VERSION_IGNORE_UPDATE;
}

+ (NSArray *)DB_modifyList{
    return nil;
}

#pragma mark- SQL string

- (NSArray *)DB_selectiveFields {
    // 所有字段
    NSArray *allFields = [self.class DB_tableFieldList];
    NSDictionary *fieldDic = [self.class DB_tableFieldMap];
    
    NSMutableArray *selectiveFields = [NSMutableArray arrayWithCapacity:allFields.count];
    for (NSString *fieldName in allFields) {
        DBProperty *property = fieldDic[fieldName];
        
        id value = [self valueForKey:property.propertyName];
        if (value && value != [NSNull null]) {
            [selectiveFields addObject:fieldName];
        }
    }
    return selectiveFields;
}

- (NSString *)DB_sqlForSaveSelective:(NSArray *)selectiveFields needReplace:(BOOL)needReplace {
    NSInteger fieldCount = selectiveFields.count;
    // 没有非空字段
    if (fieldCount == 0) {
        return nil;
    }
    
    NSMutableArray *valueArr = [NSMutableArray arrayWithCapacity:fieldCount];

    // 对字段value判断，排除NULL值
    for (int i = 0; i < fieldCount; i++)
    {
        [valueArr addObject:@"?"];
    }

    NSString *sql = [NSString stringWithFormat:@"INSERT %@ INTO %@(%@) VALUES(%@)", needReplace ? @"OR REPLACE" : @"", [self.class DB_tableName],[selectiveFields componentsJoinedByString:@","] ,[valueArr componentsJoinedByString:@","]];

//    NSLog(@"[%@  insertSQL] : %@", self, sql);
    return sql;
}

/*
 CREATE TABLE IF NOT EXISTS student (id INTEGER primary key,age INTEGER,isMale INTEGER,name TEXT,other TEXT,sid TEXT,UNIQUE(sid) ON CONFLICT IGNORE);
 CREATE TABLE IF NOT EXISTS student (age INTEGER,isMale INTEGER,name TEXT,other TEXT,sid TEXT,uniqueId TEXT,primary key(sid),unique(uniqueId));
 */
+ (NSString *)DB_sqlForCreateTable
{
    NSString *str = @"";
    NSArray *primaryKeys = [self DB_primaryKeys];
    NSArray *uniqueKeys = [self DB_uniqueKeys];

    NSArray *tableFieldList = [self DB_tableFieldList];
    
    // 表字段map
    NSDictionary *fieldlDic = [self.class DB_tableFieldMap];
    // 属性map
    NSDictionary *propertyDic = [self.class DB_propertyMap];
    
    for (int i = 0; i < tableFieldList.count; i++)
    {
        NSString *fieldName = tableFieldList[i];
        DBProperty *property = fieldlDic[fieldName];
        
#if DB_AUTOCREATE_PRIMARY_KEY
        if ([fieldName isEqualToString:@"id"]) {
            str = [NSString stringWithFormat:@"id INTEGER not null PRIMARY KEY AUTOINCREMENT %@ %@", str.length > 0 ? @"," : @"", str];
        } else {
            str = [NSString stringWithFormat:@"%@%@%@ %@", str, str.length > 0 ? @"," : @"", fieldName, property.fieldType];
        }
#else
        str = [NSString stringWithFormat:@"%@%@%@ %@", str, str.length > 0 ? @"," : @"", fieldName, property.fieldType];
#endif
    }
#if DB_AUTOCREATE_PRIMARY_KEY
#else
     NSString *primaryStr = @"";
     if (primaryKeys.count > 0)
     {
     primaryStr = [NSString stringWithFormat:@"primary key(%@)", [primaryKeys componentsJoinedByString:@","]];
     str = [NSString stringWithFormat:@"%@,%@", str, primaryStr];
     }
#endif
    
    __block NSString *uniqueStr = @"";
    if (uniqueKeys.count > 0)
    {
        [uniqueKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *str = @"unique()";
            if ([obj isKindOfClass:[NSArray class]] && [(NSArray *)obj count] > 0)
            {
                NSInteger count = [(NSArray *)obj count];
                // 把 属性字段 转成 表字段
                NSMutableArray *fieldArray = [NSMutableArray arrayWithCapacity:count];
                [(NSArray *)obj enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *str = obj;
                    DBProperty *property = propertyDic[str];
                    if (property) {
                        [fieldArray addObject:property.fieldName];
                    }
                }];
                
                if (fieldArray.count != count) {
                    NSLog(@"unique key error! %@", [(NSArray *)obj description]);
                    return;
                }
                
                NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",tableFieldList];
                //过滤数组
                NSArray *resultArray = [fieldArray filteredArrayUsingPredicate:filterPredicate];
                if (resultArray.count > 0)
                {
                    NSLog(@"unique key error! 有字段不在表中。 %@", [(NSArray *)obj description]);
                    return;
                }
                
                str = [NSString stringWithFormat:@"unique(%@)", [fieldArray componentsJoinedByString:@","]];
            }
            else if ([obj isKindOfClass:[NSString class]])
            {
                DBProperty *property = propertyDic[obj];
                if (!property || ![tableFieldList containsObject:property.fieldName])
                {
                    NSLog(@"unique key error! 有字段[%@]不在表中.", obj);
                    return;
                }
                str = [NSString stringWithFormat:@"unique(%@)", obj];
            }
            else
            {
//                *stop = YES;
                return ;
            }
            uniqueStr = [NSString stringWithFormat:@"%@%@%@",uniqueStr,uniqueStr.length > 0 ? @"," : @"", str];
        }];
        
        if (uniqueStr.length > 0)
        {
            str = [NSString stringWithFormat:@"%@,%@", str, uniqueStr];
        }
    }
    
    
    str = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@);", [self DB_tableName], str];
    
//    NSLog(@"[%@  creatTableSQL] : %@", self, str);
    
    return str;
}

/*
 INSERT INTO student(age,isMale,name,other,sid,uniqueId) VALUES(?,?,?,?,?,?)
 */
+ (NSString *)DB_sqlForInsert:(BOOL)needReplace
{
    NSInteger fieldCount = [self DB_fieldCount];
    NSMutableArray *valueArr = [NSMutableArray arrayWithCapacity:fieldCount];
    for (int i = 0; i < fieldCount; i++)
    {
        [valueArr addObject:@"?"];
    }
    
    NSString *sql = [NSString stringWithFormat:@"INSERT %@ INTO %@(%@) VALUES(%@)", needReplace ? @"OR REPLACE" : @"", [self DB_tableName],[[self DB_tableFieldList] componentsJoinedByString:@","] ,[valueArr componentsJoinedByString:@","]];
    
//    NSLog(@"[%@  insertSQL] : %@", self, sql);
    return sql;
}

/*
 UPDATE student SET age=?,isMale=?,name=?,other=?,sid=?,uniqueId=? where sid=?
 */
+ (NSString *)DB_sqlForUpdate
{
    NSMutableString *setStr = [[NSMutableString alloc] init];
    NSArray *tableFieldList = [self DB_tableFieldList];
    for (int i = 0; i < tableFieldList.count; i++)
    {
        [setStr appendFormat:@"%@%@=?", (setStr.length > 0 ? @"," : @""), tableFieldList[i]];
    }

    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ where %@", [self DB_tableName], setStr, [self DB_sqlForArray:[self DB_primaryKeys]]];
//    NSLog(@"[%@  insertSQL] : %@", self, sql);
    return sql;
}

+ (NSString *)DB_sqlForDelete
{
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", [self DB_tableName],[self DB_sqlForArray:[self DB_primaryKeys]]];
    return sql;
}

+ (NSString *)DB_sqlForArray:(NSArray *)keyArray
{
    if (keyArray.count == 0)
    {
        return @"";
    }
    NSString *sql = [keyArray componentsJoinedByString:@"=? and "];
    sql = [NSString stringWithFormat:@"%@%@",sql, @"=? "];
    return sql;
}


#pragma mark-

+ (NSString *)DB_setterMethodName:(NSString *)propertyName
{
    if ([propertyName length] == 0)
        return @"";
    
    NSString *firstChar = [propertyName substringToIndex:1];
    firstChar = [firstChar uppercaseString];
    NSString *lastName = [propertyName substringFromIndex:1];
    return [NSString stringWithFormat:@"set%@%@:", firstChar, lastName];
}

- (BOOL)DB_isPrimaryValueValid
{
    NSArray *primaryKeys = [[self class] DB_primaryKeys];
    for (int i = 0; i < primaryKeys.count; i++)
    {
        id value = [self valueForKey:primaryKeys[i]];
        if (!value)
        {
            return NO;
        }
    }
    
    return YES;
}

@end


