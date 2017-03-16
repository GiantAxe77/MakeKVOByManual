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

@property (nonatomic, strong) Person *p;

@end



@implementation ViewController

- (IBAction)btnClick:(UIButton *)sender {
    
    NSArray *friends = @[@"Giant", @"Axe", @"77"];
    NSInteger index = arc4random_uniform((u_int32_t)friends.count);
    self.p.friend = friends[index];
    
}



- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.p = [Person new];
    [self.p AXE_addObserver:self forKey:NSStringFromSelector(@selector(friend)) withBlock:^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
        
        NSLog(@"%@-%@  old:%@  new:%@", observedObject, observedKey, oldValue, newValue);
    }];

    
}


@end
