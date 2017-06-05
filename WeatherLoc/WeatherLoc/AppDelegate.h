//
//  AppDelegate.h
//  WeatherLoc
//
//  Created by Zack Aroui on 6/3/17.
//  Copyright © 2017 Zack Aroui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

