//
//  DBTableChange.m
//  DBHelper
//
//  Created by Bowen on 16/1/15.
//  Copyright © 2016年 Bowen. All rights reserved.
//

#import "DBTableChange.h"
#import <FMDB/FMDB.h>

@interface DBTableChange ()

@property (nonatomic, copy) NSSet   *addFieldSet;
@property (nonatomic, copy) NSSet   *dropFieldSet;

@end

@implementation DBTableChange

+ (instancetype)tableChange:(DBFieldChange *)fieldChange, ...{
    DBTableChange *tableChange = [[DBTableChange alloc] init];
    NSMutableSet *addFieldSet = [NSMutableSet setWithCapacity:5];
    NSMutableSet *dropFieldSet = [NSMutableSet setWithCapacity:5];
    
    
    va_list args;
    va_start(args, fieldChange);
    
    DBFieldChange *change = fieldChange;
    while (change) {
        if ([change isKindOfClass:[DBAddFieldChange class]]) {
            [addFieldSet addObject:change];
        }
        else if ([change isKindOfClass:[DBDropFieldChange class]]) {
            [dropFieldSet addObject:change];
        }
        change = va_arg(args, id);
    }
    
    va_end(args);
    
    tableChange.addFieldSet = addFieldSet;
    tableChange.dropFieldSet = dropFieldSet;
    
    return tableChange;
}

- (BOOL)updateTable:(FMDatabase *)db tableName:(NSString *)tableName {
    
    NSAssert(tableName.length > 0, @"update table error: tableName.length is 0");
    NSAssert([db isKindOfClass:[FMDatabase class]], ([NSString stringWithFormat:@"update table [%@] error: db is not kind of FMDatabase class", tableName]));
    
    BOOL rt = YES;

    // get column names
    FMResultSet *resultSet = [db getTableSchema:tableName];
    NSMutableArray *fieldsArray = [[NSMutableArray alloc] initWithCapacity:5];
    while ([resultSet next]) {
        NSString *fieldStr = [resultSet stringForColumn:@"name"];
        if (fieldStr) {
            [fieldsArray addObject:fieldStr];
        }
    }
    
    NSAssert(fieldsArray.count > 0, ([NSString stringWithFormat:@"update table [%@] error: the count of column is 0", tableName]));
    
    // drop columns
    if (self.dropFieldSet.count > 0) {
        
        NSString *tempTableName = [NSString stringWithFormat:@"db_temp_%@", tableName];
        [db executeUpdate:[NSString stringWithFormat:@"drop table %@", tempTableName]];
        
        rt = [db executeUpdate:[NSString stringWithFormat:@"alter table %@ rename to %@", tableName, tempTableName]];
        if (!rt) {
            NSLog(@"update table [%@] error: rename table failed", tableName);
            return NO;
        }
        
        __block NSString *sql = [NSString stringWithFormat:@"create table %@ as select ", tableName];
        
        [self.dropFieldSet enumerateObjectsUsingBlock:^(DBFieldChange * obj, BOOL * _Nonnull stop) {
            if ([fieldsArray containsObject:obj.fieldName]) {
                [fieldsArray removeObject:obj.fieldName];
            }
        }];
        
        if (fieldsArray.count > 0) {
            sql = [NSString stringWithFormat:@"%@ %@", sql,[fieldsArray componentsJoinedByString:@","]];
        }
        
        if ([sql hasSuffix:@","]) {
            sql = [sql substringToIndex:sql.length - 1];
        }
        
        sql = [NSString stringWithFormat:@"%@ from %@", sql, tempTableName];
        
        rt = [db executeUpdate:sql];
        if (!rt) {
            NSLog(@"update table [%@] error: copy table failed", tableName);
            return NO;
        }
        
        [db executeUpdate:[NSString stringWithFormat:@"drop table %@", tempTableName]];
    }
    
    if (self.addFieldSet.count > 0) {
        NSMutableArray *sqlList = [[NSMutableArray alloc] initWithCapacity:self.addFieldSet.count];
        [self.addFieldSet enumerateObjectsUsingBlock:^(DBAddFieldChange *obj, BOOL * _Nonnull stop) {
            NSString *sql = [NSString stringWithFormat:@"alter table %@ add column %@ %@", tableName, obj.fieldName, obj.type];
            if (obj.defaultValue) {
                sql = [NSString stringWithFormat:@"%@ default %@", sql,((NSObject *)obj.defaultValue).description];
            }
            [sqlList addObject:sql];
        }];
        
        rt = [db executeStatements:[sqlList componentsJoinedByString:@";"]];
        
        if (!rt) {
            NSLog(@"update table [%@] error: add new columns failed", tableName);
        }
        
        return rt;
    }
    
    return YES;
}

@end


@implementation DBFieldChange

- (instancetype)initWithFieldName:(NSString *)fieldName type:(NSString *)type {
    if (self = [super init]) {
        self.fieldName = fieldName;
        self.type = type;
    }
    return self;
}

@end


@implementation DBAddFieldChange

+ (instancetype)addFieldChange:(NSString *)fieldName type:(NSString *)type {
    return [DBAddFieldChange addFieldChange:fieldName type:type defaultValue:nil];
}

+ (instancetype)addFieldChange:(NSString *)fieldName type:(NSString *)type defaultValue:(id)value {
    DBAddFieldChange *change = [[DBAddFieldChange alloc] initWithFieldName:fieldName type:type];
    change.defaultValue = value;
    return change;
}

@end

@implementation DBDropFieldChange

+ (instancetype)dropFieldChange:(NSString *)fieldName {
    DBDropFieldChange *change = [[DBDropFieldChange alloc] init];
    change.fieldName = fieldName;
    return change;
}

@end
