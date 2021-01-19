//
//  DBHelper.m
//  Template
//
//  Created by Bowen on 15/8/27.
//  Copyright (c) 2015年 Bowen. All rights reserved.
//

#import "DBHelper.h"
#import <sqlite3.h>

#if DEBUG
    #define ZBWDBLog(format, ...) \
        do { \
            printf(\
            "[ZBWDBLog]\n%s\n",\
            [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String]\
            );\
        } while (0)
#else
    #define ZBWDBLog(format, ...)
#endif

NSMutableDictionary *globalDBHelperMap()
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *globalDBHelperMap = nil;
    dispatch_once(&onceToken, ^{
        globalDBHelperMap = [NSMutableDictionary dictionaryWithCapacity:1];
    });
    return globalDBHelperMap;
}

NSMutableDictionary *globalDBHelperAliasMap()
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *globalDBHelperAliasMap = nil;
    dispatch_once(&onceToken, ^{
        globalDBHelperAliasMap = [NSMutableDictionary dictionaryWithCapacity:1];
    });
    return globalDBHelperAliasMap;
}

@interface DBHelper ()

@property (nonatomic, copy) NSString        *dbFilePath;
@property (nonatomic, assign) BOOL          useDatabasePool;        // 使用pool，并发操作数据库。默认为NO，默认使用queue来同步操作。
@property (nonatomic, copy) NSString        *encriptKey;            // 加密密钥


@property (nonatomic, retain) FMDatabasePool    *pool;
@property (nonatomic, retain) FMDatabaseQueue   *queue;

#pragma mark- queue
- (FMDatabaseQueue *)queue;
- (FMDatabaseQueue *)queueWithDatabaseName:(NSString *)databaseName;
- (FMDatabaseQueue *)queueWithDatabasePath:(NSString *)databasePath;

#pragma mark- pool
- (FMDatabasePool *)pool;
- (FMDatabasePool *)poolWithDatabaseName:(NSString *)databaseName;
- (FMDatabasePool *)poolWithDatabasePath:(NSString *)databasePath;

@end

static DBHelper  *s_defaultHelper = NULL;
@implementation DBHelper

+ (BOOL)registDB:(NSString *)dbFilePath
 useDatabasePool:(BOOL)useDatabasePool
      encriptKey:(NSString *)encriptKey
           alias:(NSString *)alias
     isDefaultDB:(BOOL)isDefaultDB {
    if (!dbFilePath) {
        ZBWDBLog(@"dbFilePath不能为空");
        return NO;
    }
    
    // 是否已经注册过
    @synchronized (self) {
        NSMutableDictionary *helperMap = globalDBHelperMap();
        NSMutableDictionary *aliasMap = globalDBHelperAliasMap();
        DBHelper *helper = helperMap[dbFilePath];
        if (!helper) {
            if (alias.length > 0 && aliasMap[alias]) {
                ZBWDBLog(@"别名已存在");
                return NO;
            }
            DBHelper *helper = [[DBHelper alloc] init];
            helper.dbFilePath = dbFilePath;
            helper.useDatabasePool = useDatabasePool;
            helper.encriptKey = encriptKey;
            
            helperMap[dbFilePath] = helper;
            if (alias.length > 0) {
                aliasMap[alias] = helper;
            }
            if (isDefaultDB) {
                s_defaultHelper = helper;
            }
        }
    }
    
    return YES;
}

+ (instancetype)dbHelper:(NSString *)dbFilePath {
    if (!dbFilePath) {
        return NULL;
    }
    @synchronized (self) {
        NSMutableDictionary *helperMap = globalDBHelperMap();
        DBHelper *helper = helperMap[dbFilePath];
        return helper;
    }
}

+ (instancetype)dbHelperWithAlias:(NSString *)alias {
    if (!alias) {
        return s_defaultHelper;
    }
    @synchronized (self) {
        NSMutableDictionary *helperMap = globalDBHelperAliasMap();
        DBHelper *helper = helperMap[alias];
        return helper;
    }
}

+ (instancetype)instance
{
    static DBHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DBHelper alloc] init];
    });
    return instance;
}

+ (void)setKeyForDB:(FMDatabase *)db {
    NSString *databasePath = db.databasePath;
    @synchronized (self) {
        NSMutableDictionary *helperMap = globalDBHelperMap();
        DBHelper *helper = helperMap[databasePath];
        if (helper.encriptKey) {
            [db setKey:helper.encriptKey];
        }
    }
}

#pragma mark- inDatabase

- (void)inDatabase:(void (^)(FMDatabase *))block
{
    if (self.useDatabasePool)
    {
        FMDatabasePool *pool = [self poolWithDatabasePath:self.dbFilePath];
        [pool inDatabase:block];
    }
    else
    {
        FMDatabaseQueue *queue = [self queueWithDatabasePath:self.dbFilePath];
        
        [queue inDatabase:block];
    }
}

#pragma mark- inTransaction
- (void)inTransaction:(void (^)(FMDatabase *, BOOL *))block
{
    if (self.useDatabasePool)
    {
        FMDatabasePool *pool = [self poolWithDatabasePath:self.dbFilePath];
        [pool inTransaction:block];
    }
    else
    {
        FMDatabaseQueue *queue = [self queueWithDatabasePath:self.dbFilePath];
        
        [queue inTransaction:block];
    }
}

#pragma mark- Queue
- (FMDatabaseQueue *)queueWithDatabasePath:(NSString *)databasePath
{
    if (!databasePath)
    {
        return nil;
    }
    
    FMDatabaseQueue *returnQueue = nil;

    @synchronized (self)
    {
        returnQueue = self.queue;
        if (!returnQueue)
        {
            returnQueue = [[FMDatabaseQueue alloc] initWithPath:databasePath];
            if (returnQueue)
            {
                self.queue = returnQueue;
            }
        }
    }
    return returnQueue;
}

#pragma mark- Pool
- (FMDatabasePool *)poolWithDatabasePath:(NSString *)databasePath
{
    if (!databasePath)
    {
        return nil;
    }
    
    FMDatabasePool *pool = nil;
    
    @synchronized(self)
    {
        pool = self.pool;
        if (!pool)
        {
            pool = [[FMDatabasePool alloc] initWithPath:databasePath];
            self.pool = pool;
        }
    }
    return pool;
}

//+ (NSString *)filePathWithDirectory:(NSString *)databaseDirectory databaseName:(NSString *)databaseName
//{
//    NSString *directory = databaseDirectory;
//    if(!directory || directory.length == 0) {
//        directory = [globalDataBaseDir copy];
//    }
//    NSString *fileName = databaseName;
//    if (!fileName || fileName.length == 0) {
//        fileName = globalDataBaseFileName;
//    }
//    
//    return [directory stringByAppendingPathComponent:fileName];
//}


@end


















