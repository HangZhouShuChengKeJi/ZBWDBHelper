//
//  DBModel.h
//  Template
//
//  Created by Bowen on 15/9/1.
//  Copyright (c) 2015年 Bowen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DB_AUTOCREATE_PRIMARY_KEY   1

#define DB_VERSION_IGNORE_UPDATE    0


@class FMDatabase;

@protocol DBModelProtocol <NSObject>

// 表名
+ (NSString *)DB_tableName;

@optional
// 数据库注册时的alias别名
+ (NSString *)DB_databaseAlias;

// 忽略属性 (有些属性，不需要保存在数据库中)
+ (NSArray *)DB_ignoreProperty;

#if (DB_AUTOCREATE_PRIMARY_KEY != 1)
// 主键
/*
 @[@"a",@"b"]               代表 primary key(a,b)
 */
+ (NSArray *)DB_primaryKeys;
#endif

// 需要添加unique约束的键
/*
 @[[@"a",@"b"],
    [@"c",@"d"]]            代表 unique(a,b),unique(c,d)
 
 @[[@"a"],@[@"b"]]          代表 unique(a), unique(b)
 
 @[[@"a",@"b"]]             代表 unique(a,b)
*/
+ (NSArray *)DB_uniqueKeys;

/**
 *  当前版本号
 *
 *  用于版本比较，更新表字段
 *  @return 当前版本号
 */
+ (NSInteger)DB_version;


/**
 *  历史修改记录
 *
 *  @return 各版本修改表
 */
+ (NSArray *)DB_modifyList;


/**
 属性字段-表字段  对象关系映射

 @return key:属性名称  value:表字段名称
 */
+ (NSDictionary *)DB_orm;

@end

/******************************************************************
 *                  【DBModel】
 * 关系数据库中的实体model基类
 *
 * 1、使用runtime遍历所有属性，并创建属性和表字段的对照关系；
 *
 * 2、自动生成了一些sql语句，自动生成表，提供常用的插入、更新、删除和查询功能。
 *
 ******************************************************************/
@interface DBModel : NSObject <DBModelProtocol>

#if DB_AUTOCREATE_PRIMARY_KEY
@property (nonatomic, assign) NSInteger     id;
#endif

#pragma mark- 保存操作（insert、update）  insert or replace。 如果有约束条件，导致无法insert，会进行replace操作，进行更新。

// 插入/更新 所有字段
- (BOOL)DB_save;
+ (BOOL)DB_saveList:(NSArray *)itemList;

// 插入/更新 非空字段
- (BOOL)DB_saveSelective;
+ (BOOL)DB_saveListSelective:(NSArray *)itemList;


#pragma mark- just insert。 如果有约束条件，导致无法insert，不会进行replace操作。直接插入失败。
// 插入/更新 所有字段
- (BOOL)DB_saveNotReplace;
+ (BOOL)DB_saveListNotReplace:(NSArray *)itemList;

// 插入/更新 非空字段
- (BOOL)DB_saveSelectiveNotReplace;
+ (BOOL)DB_saveListSelectiveNotReplace:(NSArray *)itemList;

#pragma mark- 删除操作 （delete、drop）
- (BOOL)DB_delete;

+ (BOOL)DB_deleteList:(NSArray *)itemList;

+ (BOOL)DB_clearTable;

+ (BOOL)DB_deleteById:(NSInteger)pkId;

+ (BOOL)DB_deleteWithCondition:(NSString *)where argumentsInArray:(NSArray *)arguments;

+ (BOOL)DB_dropTable;

#pragma mark- Query 查询表记录

/**
 *  按pkid 查询
 */
+ (id)DB_queryById:(NSInteger)pkId;

/**
 *  查询所有的记录
 */
+ (NSArray *)DB_queryAllRecords;

/**
 *  查询符合条件的记录
 */
+ (NSArray *)DB_queryRecords:(NSString *)condition withArgumentsInArray:(NSArray *)arguments;

+ (NSArray *)DB_queryRecords:(NSString *)condition
                orderBy:(NSString *)fieldName
                descend:(BOOL)isDescend
       argumentsInArray:(NSArray *)arguments;

/**
 *  查询符合条件的记录
 *
 *  @param condition where条件                例如：@“age > ? and isMale = 1”
 *  @param fieldName 排序的字段                例如：@“age”
 *  @param isDescend 是否降序
 *  @param range     limit参数                例如：NSMakeRange(0,10)，代表“limit 0,10”
 *  @param arguments 传入参数                  例如：@[@(18)],对应上面的condition条件，值age>18
 *
 *  @return 符合条件的记录
 */
+ (NSArray *)DB_queryRecords:(NSString *)condition
                    orderBy:(NSString *)fieldName
                   descend:(BOOL)isDescend
                     range:(NSRange)range
          argumentsInArray:(NSArray *)arguments;

/**
 *  查询符合条件的记录 （部分字段查询）
 *
 *  @param fields    需要查询的字段             例如：@[@"name",@"age"]
*   @param distinct 是否去重                   YES：去重， NO：不去重
 *  @param condition where条件                例如：@“age > ? and isMale = 1”
 *  @param fieldName 排序的字段                例如：@“age”
 *  @param isDescend 是否降序
 *  @param range     limit参数                例如：NSMakeRange(0,10)，代表“limit 0,10”
 *  @param arguments 传入参数                  例如：@[@(18)],对应上面的condition条件，值age>18
 *
 *  @return 符合条件的记录
 */
+ (NSArray *)DB_queryRecordsWithFields:(NSArray *)fields
                              distinct:(BOOL)distinct
                             condition:(NSString *)condition
                               orderBy:(NSString *)fieldName
                               descend:(BOOL)isDescend
                                 range:(NSRange)range
                      argumentsInArray:(NSArray *)arguments;


#pragma mark- 查询Count、Avg、Sum

/**
 *  查询符合条件的记录总数
 */
+ (NSInteger)DB_queryCount:(NSString *)condition argumentsInArray:(NSArray *)arguments;

/**
 *  查询符合条件的记录数。针对fieldName参数去重
 */
+ (NSInteger)DB_queryCount:(NSString *)condition distinctField:(NSString *)fieldName argumentsInArray:(NSArray *)arguments;

// 查询某字段的平均值
+ (double)DB_queryAverage:(NSString *)condition field:(NSString *)fieldName argumentsInArray:(NSArray *)arguments;

// 查询某字段的总和
+ (double)DB_querySum:(NSString *)condition field:(NSString *)fieldName argumentsInArray:(NSArray *)arguments;

@end




