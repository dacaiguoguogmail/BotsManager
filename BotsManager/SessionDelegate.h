//
//  SessionDelegate.h
//  BotsManager
//
//  Created by dacaiguoguo on 2020/8/6.
//  Copyright © 2020 dacaiguoguo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SessionDelegate : NSObject <NSURLSessionDelegate>
+ (instancetype)sharedDelegate;
@end

NS_ASSUME_NONNULL_END
