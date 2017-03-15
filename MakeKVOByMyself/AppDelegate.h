//
//  AppDelegate.h
//  MakeKVOByMyself
//
//  Created by GiantAxe on 16/7/14.
//  Copyright © 2016年 GiantAxe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

