//
//  ViewController.m
//  WeatherLoc
//
//  Created by Zack Aroui on 6/3/17.
//  Copyright © 2017 Zack Aroui. All rights reserved.
//

#import "WLApiManager.h"
#import "AFNetworking.h"


@implementation WLApiManager

- (void)getApiCallToEndpoint:(NSString *)endpoint withParams:(NSDictionary *)parameters onCompletion:(RequestCompletion)compBlock{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
    
    [manager GET:endpoint parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        compBlock(responseObject, YES);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        compBlock(error, NO);
    }];
    
}

@end
