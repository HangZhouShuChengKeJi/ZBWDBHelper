//
//  DBProperty.m
//  ZBWDBHelper
//
//  Created by Bowen on 2019/4/17.
//

#import "DBProperty.h"

const NSString  *DB_SQLITE_NULL = @"NULL";
const NSString  *DB_SQLITE_INTEGER = @"INTEGER";
const NSString  *DB_SQLITE_REAL = @"REAL";
const NSString  *DB_SQLITE_TEXT = @"TEXT";
const NSString  *DB_SQLITE_BLOB = @"BLOB";

const NSString *DB_SQLITE_DATE = @"Date";

@implementation DBProperty


- (void)setPropertyType:(NSString *)propertyType {
    _propertyType = propertyType;
    // sqlite中只有5中类型
    // 1、NULL
    // 2、INTEGER 整形
    // 3、REAL 浮点
    // 4、TEXT 文本
    // 5、BLOB 二进制
    if ([propertyType hasPrefix:@"T@\"NSString\""])
    {
        _fieldType = DB_SQLITE_TEXT;
    }
    else if([propertyType hasPrefix:@"Td"] || [propertyType hasPrefix:@"Tf"])
    {
        _fieldType = DB_SQLITE_REAL;
    }
    else if ([propertyType hasPrefix:@"T@\"NSData\""])
    {
        _fieldType = DB_SQLITE_BLOB;
    }
    else if ([propertyType hasPrefix:@"T@\"NSDate\""]) {
        _fieldType = DB_SQLITE_DATE;
    }
    else
    {
        _fieldType = DB_SQLITE_INTEGER;
    }
}


- (id)defaultDBValue {
    if (_defaultDBValue) {
        return _defaultDBValue;
    }
    
    @synchronized (self) {
        if (_defaultDBValue) {
            return _defaultDBValue;
        }
        
        NSString *type = self.fieldType;
        id value = nil;
        if (type == DB_SQLITE_BLOB)
        {
            value = [NSNull null];
        }
        else if (type == DB_SQLITE_TEXT)
        {
            value = @"";
        }
        else if (type == DB_SQLITE_REAL)
        {
            value = @(0.0);
        }
        else
        {
            value = @(0);
        }
        _defaultDBValue = value;
    }
    
    return _defaultDBValue;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"【DBProperty】【%@ <=> %@】【%@ <=> %@】【default=%@】【isPrimaryKey = %ld】",
            self.propertyName,
            self.fieldName,
            self.propertyType,
            self.fieldType,
            self.defaultDBValue,
            self.isPrimaryKey];
}

@end
