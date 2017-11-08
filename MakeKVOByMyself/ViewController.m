//
//  ViewController.m
//  MakeKVOByMyself
//
//  Created by GiantAxe on 16/7/14.
//  Copyright © 2016年 GiantAxe. All rights reserved.
//

#import "ViewController.h"

// category
#import "NSObject+KVO.h"

@interface Person : NSObject

@property (nonatomic, copy) NSString *friend;

@end

@implementation Person

@end

@interface ViewController ()

@property (nonatomic, strong) Person *onePerson;

@end


@implementation ViewController

// ===============================================================
//                          Life Cycle
// ===============================================================

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.onePerson = [Person new];
    [self.onePerson AXE_addObserver:self forKey:NSStringFromSelector(@selector(friend)) withBlock:^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
        
        NSLog(@"%@-%@  old:%@  new:%@", observedObject, observedKey, oldValue, newValue);
    }];

    
}

- (void)dealloc
{
    [self.onePerson AXE_removeObserver:self forKey:NSStringFromSelector(@selector(friend))];
}


// ===============================================================
//                          事件处理
// ===============================================================

#pragma mark - 事件处理

- (IBAction)btnClick:(UIButton *)sender
{
    NSArray *friends = @[@"Cam", @"Mitch", @"Lily"];
    NSInteger index = arc4random_uniform((u_int32_t)friends.count);
    self.onePerson.friend = friends[index];
}

@end
