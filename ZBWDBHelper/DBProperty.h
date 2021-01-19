//
//  DBProperty.h
//  ZBWDBHelper
//
//  Created by Bowen on 2019/4/17.
//

#import <Foundation/Foundation.h>

OBJC_EXTERN NSString * DB_SQLITE_NULL;
OBJC_EXTERN NSString * DB_SQLITE_INTEGER;
OBJC_EXTERN NSString * DB_SQLITE_REAL;
OBJC_EXTERN NSString * DB_SQLITE_TEXT;
OBJC_EXTERN NSString * DB_SQLITE_BLOB;
OBJC_EXTERN NSString * DB_SQLITE_DATE;

@interface DBProperty : NSObject

@property (nonatomic, retain) NSString      *propertyName;  // 属性名称
@property (nonatomic, retain) NSString      *fieldName;     // 数据库字段名称

@property (nonatomic, retain) NSString      *propertyType;     // 属性的类型。
@property (nonatomic, retain) NSString      *fieldType;     // 数据库类型

@property (nonatomic, retain) id            defaultDBValue;   // 如果Model属性值为空，插入数据库时使用默认值

@property (nonatomic, assign) BOOL          isPrimaryKey;   // 是否为主键

@end

