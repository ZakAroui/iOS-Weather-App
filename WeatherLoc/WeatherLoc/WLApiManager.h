//
//  ViewController.m
//  WeatherLoc
//
//  Created by Zack Aroui on 6/3/17.
//  Copyright © 2017 Zack Aroui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLApiManager : NSObject

typedef void(^RequestCompletion)(id, BOOL);

- (void) getApiCallToEndpoint: (NSString *)endpoint withParams: (NSDictionary *)parameters onCompletion:(RequestCompletion)compBlock;

@end
