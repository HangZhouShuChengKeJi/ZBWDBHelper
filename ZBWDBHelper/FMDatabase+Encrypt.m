//
//  FMDatabase+Encrypt.m
//  Template
//
//  Created by Bowen on 15/9/15.
//  Copyright (c) 2015年 Bowen. All rights reserved.
//

#import "FMDatabase+Encrypt.h"
#import <objc/runtime.h>
#import "DBHelper.h"

@implementation FMDatabase(Encrypt)

+ (void)load
{
    [super load];
    
    Class zClass = FMDatabase.class;
    SEL selector = @selector(open);
    Method orgMethod = class_getInstanceMethod(zClass, selector);
    IMP orgImp = method_getImplementation(orgMethod);
    IMP newImp = imp_implementationWithBlock(^BOOL (id obj) {
        BOOL result = ((BOOL (*)(id,SEL))orgImp)(obj,selector);
        
        [DBHelper setKeyForDB:(FMDatabase *)obj];
        return result;
    });
    
    if (!class_addMethod(zClass, selector, newImp, method_getTypeEncoding(orgMethod))) {
        method_setImplementation(orgMethod, newImp);
    }
    
    
    selector = @selector(openWithFlags:vfs:);
    orgMethod = class_getInstanceMethod(zClass, selector);
    orgImp = method_getImplementation(orgMethod);
    newImp = imp_implementationWithBlock(^BOOL (id obj, int flags, NSString* vfsName) {
        BOOL result = ((BOOL (*)(id,SEL,int,NSString*))orgImp)(obj,selector, flags, vfsName);
        
        [DBHelper setKeyForDB:(FMDatabase *)obj];
        return result;
    });
    
    if (!class_addMethod(zClass, selector, newImp, method_getTypeEncoding(orgMethod))) {
        method_setImplementation(orgMethod, newImp);
    }
}


@end
