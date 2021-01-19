//
//  DBTableChange.h
//  DBHelper
//
//  Created by Bowen on 16/1/15.
//  Copyright © 2016年 Bowen. All rights reserved.
//

#import <Foundation/Foundation.h>

// 宏定义，构造
#define kDBTableChange(fieldChange, ...)                [DBTableChange tableChange:fieldChange, __VA_ARGS__]
#define kDBAddField_Change(aName, aType, aDfltValue)    [DBAddFieldChange addFieldChange:aName type:aType defaultValue:aDfltValue]
#define kDBDropField_Change(aName)                      [DBDropFieldChange dropFieldChange:aName]

@class DBFieldChange;


/**
 *  表修改记录
 */
@interface DBTableChange : NSObject

+ (instancetype)tableChange:(DBFieldChange *)fieldChange, ... NS_REQUIRES_NIL_TERMINATION;

/**
 *  根据当前表的修改记录，进行数据更新
 *
 *  @param db        FMDatabase实例
 *  @param tableName 表名
 *
 *  @return 是否成功
 */
- (BOOL)updateTable:(id)db tableName:(NSString *)tableName;

@end


/**
 *  表字段的修改
 */
@interface DBFieldChange : NSObject

@property (nonatomic, copy) NSString        *fieldName;         // 字段名称
@property (nonatomic, copy) NSString        *type;              // 数据类型 DB_SQLITE_INTEGER，DB_SQLITE_REAL DB_SQLITE_TEXT DB_SQLITE_BLOB

- (instancetype)initWithFieldName:(NSString *)fieldName type:(NSString *)type;

@end

/**
 *  新增表字段
 */
@interface DBAddFieldChange : DBFieldChange

@property (nonatomic) id                    defaultValue;

+ (instancetype)addFieldChange:(NSString *)fieldName type:(NSString *)type defaultValue:(id)value;
+ (instancetype)addFieldChange:(NSString *)fieldName type:(NSString *)type;

@end

/**
 *  删除表字段
 */
@interface DBDropFieldChange : DBFieldChange

+ (instancetype)dropFieldChange:(NSString *)fieldName;

@end
