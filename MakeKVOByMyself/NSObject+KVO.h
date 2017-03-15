//
//  NSObject+KVO.h
//  MakeKVOByMyself
//
//  Created by GiantAxe on 16/7/14.
//  Copyright © 2016年 GiantAxe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AxeObservingBlock)(id observedObject, NSString *observedKey, id oldValue, id newValue);

@interface NSObject (KVO)

- (void)AXE_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(AxeObservingBlock)block;

- (void)AXE_removeObserver:(NSObject *)observer forKey:(NSString *)key;

@end
