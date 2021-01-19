//
//  DBHelper.h
//  Template
//
//  Created by Bowen on 15/8/27.
//  Copyright (c) 2015年 Bowen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

/*******************************************************************
 *                      【DBHelper】
 *
 *【功能】：封装FMDB，提供简单的API。
 *
 * 1、对外提供设置默认数据库文件路径、文件名；
 *
 * 2、提供数据库连接池和串行队列的方式，分别用于多线程并发操作和多线程同步操作；建议使用同步队列（即useDatabasePool使用默认值【NO】），除非有非用不可的需要，才考虑使用并发操作。
 *
 *
 *******************************************************************/

@interface DBHelper : NSObject

+ (BOOL)registDB:(NSString *)dbFilePath
 useDatabasePool:(BOOL)useDatabasePool
      encriptKey:(NSString *)encriptKey
           alias:(NSString *)alias
     isDefaultDB:(BOOL)isDefaultDB;

+ (instancetype)dbHelper:(NSString *)dbFilePath;
+ (instancetype)dbHelperWithAlias:(NSString *)alias;

+ (void)setKeyForDB:(FMDatabase *)db;

#pragma mark- inDatabase
- (void)inDatabase:(void (^) (FMDatabase* db))block;

#pragma mark- inTransaction  事务
- (void)inTransaction:(void (^) (FMDatabase *db, BOOL *rollback))block;


//+ (NSString *)filePathWithDirectory:(NSString *)databaseDirectory databaseName:(NSString *)databaseName;

@end
