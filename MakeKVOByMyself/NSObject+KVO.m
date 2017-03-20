//
//  NSObject+KVO.m
//  MakeKVOByMyself
//
//  Created by GiantAxe on 16/7/14.
//  Copyright © 2016年 GiantAxe. All rights reserved.
//

#import "NSObject+KVO.h"

// system
#import <objc/message.h>

NSString *const kAXEKVOClassPrefix = @"AXEKVOClassPrefix_";
NSString *const kAXEKVOAssociatedObservers = @"AXEKVOAssociatedObservers";


@interface AXEObservationInfo : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) AxeObservingBlock block;

@end

@implementation AXEObservationInfo

// ===============================================================
//                          Setup
// ===============================================================

#pragma mark - Setup

- (instancetype)initWithObserver:(NSObject *)observer key:(NSString *)key block:(AxeObservingBlock)block
{
    if(self = [super init])
    {
        _observer = observer;
        _key = key;
        _block = block;
    }
    return self;
}

@end


@implementation NSObject (KVO)

// ===============================================================
//                          Add Observer
// ===============================================================

#pragma mark - Add Observer

- (void)AXE_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(AxeObservingBlock)block
{
    // 1.检查对象的类有没有相应的setter方法，如果没有抛出异常
    SEL setterSelector = NSSelectorFromString(getSetter(key));
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if(!setterMethod)
    {
        NSString *reason = [NSString stringWithFormat:@"%@ Object does not have a setter for key %@", self, key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        return;
    }
    
    // 2.检查对象isa指向的类是不是一个KVO类，如果不是，就新建一个继承原来类的子类，并把isa指向这个新建的子类
    Class cla = object_getClass(self);
    NSString *claName = NSStringFromClass(cla);
    
    if(![claName hasPrefix:kAXEKVOClassPrefix])
    {
        cla = [self makeKvoClassWithOriginalClassName:claName];
        object_setClass(self, cla);
    }
    
    // 3.检查对象的KVO类重写过没有这个setter方法，如果没有就添加重写的setter方法
    if(![self hasSelector:setterSelector])
    {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(cla, setterSelector, (IMP)kvo_setter, types);
    }
    
    AXEObservationInfo *info = [[AXEObservationInfo alloc] initWithObserver:observer key:key block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kAXEKVOAssociatedObservers));
    if(!observers)
    {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(kAXEKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
    
}

// ===============================================================
//                          Remove Observer
// ===============================================================

#pragma mark - Remove Observer

- (void)AXE_removeObserver:(NSObject *)observer forKey:(NSString *)key
{
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kAXEKVOAssociatedObservers));
    AXEObservationInfo *removeInfo;
    for (AXEObservationInfo *info in observers) {
        
        if(info.observer == observer && [info.key isEqualToString:key])
        {
            removeInfo = info;
            break;
        }
    }
    [observers removeObject:removeInfo];
}

// ===============================================================
//                          Method Support
// ===============================================================

#pragma mark - Method Support

static void kvo_setter(id self, SEL _cmd, id newValue)
{
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getGetter(setterName);
    
    if(!getterName)
    {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have setter %@", self, setterName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        return;
    }
    
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superCla = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    // 类型转换
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superCla, _cmd, newValue);
    
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kAXEKVOAssociatedObservers));
    typeof(self) __weak weakSelf = self;
    for (AXEObservationInfo *info in observers) {
        
        if([info.key isEqualToString:getterName])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                info.block(weakSelf, getterName, oldValue, newValue);
            });
        }
    }
    
}

static NSString *getGetter(NSString *setter)
{
    if(setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"])
    {
        return nil;
    }
    
    // 删除 set 和 :
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    
    if(key)
    {
        NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
        key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLetter];
        return key;
    }
    else
    {
        return nil;
    }
}


static NSString *getSetter(NSString *getter)
{
    if(getter.length <= 0)
    {
        return nil;
    }
    
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *leftLetters = [getter substringFromIndex:1];
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, leftLetters];
    
    return setter;
}

static Class kvo_class(id self, SEL _cmd)
{
    return class_getSuperclass(object_getClass(self));
}


- (Class)makeKvoClassWithOriginalClassName:(NSString *)claName
{
    NSString *kvoClaName = [kAXEKVOClassPrefix stringByAppendingString:claName];
    Class cla = NSClassFromString(kvoClaName);
    if(cla)
    {
        return cla;
    }
    
    Class originalCla = object_getClass(self);
    Class kvoCla = objc_allocateClassPair(originalCla, kvoClaName.UTF8String, 0);
    
    Method claMethod = class_getInstanceMethod(originalCla, @selector(class));
    const char *types = method_getTypeEncoding(claMethod);
    class_addMethod(kvoCla, @selector(class), (IMP)kvo_class, types);
    objc_registerClassPair(kvoCla);
    
    return kvoCla;
    
}


- (BOOL)hasSelector:(SEL)selector
{
    Class cla = object_getClass(self);
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(cla, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        
        SEL thisSelector = method_getName(methodList[i]);
        if(thisSelector == selector)
        {
            free(methodList);
            return YES;
        }
    }
    
    free(methodList);
    return NO;
    
}



@end


