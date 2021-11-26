//
//  main.m
//  BotsManager
//
//  Created by dacaiguoguo on 2019/10/22.
//  Copyright © 2019 dacaiguoguo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SessionDelegate.h"

/// https://developer.apple.com/library/archive/documentation/Xcode/Conceptual/XcodeServerAPIReference/Integrations.html 官方文档
/// https://xcodeserverapidocs.docs.apiary.io/#reference/bots/bot/edit-a-bot 比官方文档更全
int getBotList(NSString *server);
int updateBot(NSString *server, NSString *botId, NSString *name, NSString *branch, NSString *version);
int cleanBotIntegrations(NSString *server, NSString *botId);
int deleteBot(NSString *server, NSString *botId);
int duplicateBot(NSString *server, NSString *botId, NSString *name, NSString *branch, NSString *version);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSArray<NSString *> *arguments = [NSProcessInfo processInfo].arguments;
        BOOL isClean = NO;
        BOOL isUpdate = NO;
        BOOL isDelete = NO;
        BOOL isListBots = NO;
        NSString *branch = nil;
        NSString *name = nil;
        NSString *botId = nil;
        NSString *host = nil;
        NSString *version = nil;
        BOOL duplicate = NO;
        
        for (NSString *arguItem in arguments) {
            if ([arguItem isEqualToString:@"--clean"]) {
                isClean = YES;
            }
            if ([arguItem isEqualToString:@"--update"]) {
                isUpdate = YES;
            }
            if ([arguItem isEqualToString:@"--delete"]) {
                isDelete = YES;
            }
            if ([arguItem isEqualToString:@"--duplicate"]) {
                duplicate = YES;
            }
            if ([arguItem isEqualToString:@"--list"]) {
                isListBots = YES;
            }
            if ([arguItem hasPrefix:@"--branch="]) {
                branch = [arguItem substringFromIndex:@"--branch=".length];
            }
            if ([arguItem hasPrefix:@"--version="]) {
                version = [arguItem substringFromIndex:@"--version=".length];
            }
            if ([arguItem hasPrefix:@"--name="]) {
                name = [arguItem substringFromIndex:@"--name=".length];
            }
            if ([arguItem hasPrefix:@"--botId="]) {
                botId = [arguItem substringFromIndex:@"--botId=".length];
            }
            if ([arguItem hasPrefix:@"--host="]) {
                host = [arguItem substringFromIndex:@"--host=".length];
            }
        }

        if (host.length == 0) {
            NSLog(@"need --host=1.2.3.4");
            return 1;
        }

        // port is 20343
        NSString *server = [NSString stringWithFormat:@"https://%@:20343", host];
        // server = [NSString stringWithFormat:@"https://%@/xcode/internal", [botLinkUrl.host stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet]];

        if (isListBots) {
            getBotList(server);
        } else {
            if (botId.length == 0) {
                NSLog(@"need --botId=fsldjfls11213");
                return 1;
            }
            if (duplicate) {
                duplicateBot(server, botId, name, branch, version);
            } else if (isUpdate) {
                return updateBot(server, botId, name, branch, version);
            } else if (isClean) {
                return cleanBotIntegrations(server, botId);
            } else if (isDelete) {
                return cleanBotIntegrations(server, botId);
            }
        }
    }
    return 0;
}

int getBotList(NSString *server) {
    NSString *apiBotUrl = [NSString stringWithFormat:@"%@/api/bots", server];
    NSMutableURLRequest *requestBot = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:apiBotUrl]];
    requestBot.HTTPMethod = @"GET";
    [requestBot setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];/// 必须设置Content-Type application/json
    requestBot.timeoutInterval = 15;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:SessionDelegate.sharedDelegate delegateQueue:nil];
    [[session dataTaskWithRequest:requestBot completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!data) {
            NSLog(@"GET bot failed");
            exit(1);
        }
        NSMutableDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:nil];
        NSArray *botsList = jsonDic[@"results"];
        NSLog(@"%@", botsList);
    }] resume];
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:NSDate.distantFuture];
    return 0;
}

int duplicateBot(NSString *server, NSString *botId, NSString *name, NSString *branch, NSString *version) {
    NSString *apiBotUrl = [NSString stringWithFormat:@"%@/api/bots/%@/duplicate", server, botId];
    NSMutableURLRequest *requestBot = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:apiBotUrl]];
    requestBot.HTTPMethod = @"POST";
    [requestBot setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];/// 必须设置Content-Type application/json
    requestBot.timeoutInterval = 15;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:SessionDelegate.sharedDelegate delegateQueue:nil];
    [[session dataTaskWithRequest:requestBot completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!data) {
            NSLog(@"duplicate bot failed");
            exit(1);
        }
        NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
        if (httpRes.statusCode == 200 || httpRes.statusCode == 201) {
            NSMutableDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:nil];
            NSMutableDictionary *postDic = [NSMutableDictionary dictionary];
            postDic[@"configuration"] = jsonDic[@"configuration"];
            postDic[@"name"] = name;

            NSMutableDictionary *configuration = postDic[@"configuration"];
            NSMutableDictionary *sourceControlBlueprint = configuration[@"sourceControlBlueprint"];
            if (version.length > 0) {
                NSMutableArray *triggers = configuration[@"triggers"];
                for (NSMutableDictionary *tirggersItem in triggers) {
                    NSString *scriptBody = tirggersItem[@"scriptBody"];
                    NSString *newscriptBody = [scriptBody stringByReplacingOccurrencesOfString:@"8.7.80" withString:version];
                    tirggersItem[@"scriptBody"] = newscriptBody;
                }
            }
            NSMutableDictionary *DVTSourceControlWorkspaceBlueprintLocationsKey = sourceControlBlueprint[@"DVTSourceControlWorkspaceBlueprintLocationsKey"];

            NSMutableDictionary *DVTSourceControlBranch = nil;
            for (NSMutableDictionary *value in DVTSourceControlWorkspaceBlueprintLocationsKey.allValues) {
                if ([value[@"DVTSourceControlWorkspaceBlueprintLocationTypeKey"] isEqualToString:@"DVTSourceControlBranch"]) {
                    DVTSourceControlBranch = value;
                }
            }
            DVTSourceControlBranch[@"DVTSourceControlBranchIdentifierKey"] = branch;
            if (branch.length > 0) {
                if (!DVTSourceControlBranch) {
                    NSLog(@"GET DVTSourceControlBranch failed");
                    exit(1);
                }
            }

            NSString *updateUrl = [NSString stringWithFormat:@"%@/api/bots/%@?overwriteBlueprint=true", server, jsonDic[@"_id"]];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:updateUrl]];
            request.HTTPMethod = @"PATCH";
            request.timeoutInterval = 15;
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];/// 必须设置Content-Type application/json

            NSData *postData = [NSJSONSerialization dataWithJSONObject:postDic options:0 error:nil];
            request.HTTPBody = postData;
            [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
                if (httpRes.statusCode == 200 || httpRes.statusCode == 201) {
                    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:resData options:0 error:nil];
                    NSString *newId = jsonData[@"_id"];
                    printf("%s", newId.UTF8String);
                    exit(0);
                } else {
                    NSLog(@"%@", httpRes);
                    NSLog(@"%@", error);
                    exit(1);
                }

            }] resume];
        } else {
            NSLog(@"duplicate bot failed");
            exit(1);
        }

    }] resume];
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:NSDate.distantFuture];
    return 0;
}

int updateBot(NSString *server, NSString *botId, NSString *name, NSString *branch, NSString *version) {
    /// /Applications/Xcode.app/Contents/Developer/usr/share/xcs/xcsd/classes/botClass.js  写了 if (req.query.overwriteBlueprint === 'true') { 坑啊 ，文档里根本没提好吗！
    /// 在/Applications/Xcode.app/Contents/Developer/usr/share/xcs/xcsd/ 搜索 req.query 好好研究研究
    NSString *apiBotUrl = [NSString stringWithFormat:@"%@/api/bots/%@", server, botId];
    NSMutableURLRequest *requestBot = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:apiBotUrl]];
    requestBot.HTTPMethod = @"GET";
    [requestBot setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];/// 必须设置Content-Type application/json
    requestBot.timeoutInterval = 15;
    NSLog(@"GET bot:%@", botId);
    NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:SessionDelegate.sharedDelegate delegateQueue:nil];
    [[session dataTaskWithRequest:requestBot completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
        NSMutableDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:nil];
        if (httpRes.statusCode != 200) {
            NSLog(@"GET bot failed\n%@", jsonDic);
            exit(1);
        }
        NSMutableDictionary *postDic = [NSMutableDictionary dictionary];
        postDic[@"configuration"] = jsonDic[@"configuration"];
        postDic[@"name"] = name;
        
        NSMutableDictionary *configuration = postDic[@"configuration"];
        NSMutableDictionary *sourceControlBlueprint = configuration[@"sourceControlBlueprint"];
        if (version.length > 0) {
            NSMutableArray *triggers = configuration[@"triggers"];
            for (NSMutableDictionary *tirggersItem in triggers) {
                NSString *scriptBody = tirggersItem[@"scriptBody"];
                NSString *newscriptBody = [scriptBody stringByReplacingOccurrencesOfString:@"8.7.80" withString:version];
                tirggersItem[@"scriptBody"] = newscriptBody;
            }
        }
        NSMutableDictionary *DVTSourceControlWorkspaceBlueprintLocationsKey = sourceControlBlueprint[@"DVTSourceControlWorkspaceBlueprintLocationsKey"];
        
        NSMutableDictionary *DVTSourceControlBranch = nil;
        for (NSMutableDictionary *value in DVTSourceControlWorkspaceBlueprintLocationsKey.allValues) {
            if ([value[@"DVTSourceControlWorkspaceBlueprintLocationTypeKey"] isEqualToString:@"DVTSourceControlBranch"]) {
                DVTSourceControlBranch = value;
            }
        }
        DVTSourceControlBranch[@"DVTSourceControlBranchIdentifierKey"] = branch;
        if (branch.length > 0) {
            if (!DVTSourceControlBranch) {
                NSLog(@"GET DVTSourceControlBranch failed");
                exit(1);
            }
        }
        
        NSString *updateUrl = [NSString stringWithFormat:@"%@/api/bots/%@?overwriteBlueprint=true", server, botId];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:updateUrl]];
        request.HTTPMethod = @"PATCH";
        request.timeoutInterval = 15;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];/// 必须设置Content-Type application/json
        
        NSData *postData = [NSJSONSerialization dataWithJSONObject:postDic options:0 error:nil];
        request.HTTPBody = postData;
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
            NSLog(@"%@", httpRes);
            NSLog(@"%@", error);
            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:resData options:0 error:nil];
            NSData *prettyData = [NSJSONSerialization dataWithJSONObject:jsonData options:NSJSONWritingPrettyPrinted error:nil];
            NSLog(@"%@", [[NSString alloc] initWithData:prettyData encoding:NSUTF8StringEncoding]);
            exit(0);
        }] resume];
    }] resume];
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:NSDate.distantFuture];
    return 0;
}


int cleanBotIntegrations(NSString *server, NSString *botId) {
    NSString *integrationsUrl = [NSString stringWithFormat:@"%@/api/bots/%@/integrations", server, botId];
    NSLog(@"GET integrations list");
    NSURL *serverUrl = [NSURL URLWithString:integrationsUrl];
    NSMutableURLRequest *requestIntegrations = [[NSMutableURLRequest alloc] initWithURL:serverUrl];
    requestIntegrations.HTTPMethod = @"GET";
    [requestIntegrations setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];/// 必须设置Content-Type application/json
    requestIntegrations.timeoutInterval = 15;
    NSLog(@"GET bot:%@", botId);
    NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:SessionDelegate.sharedDelegate delegateQueue:nil];
    [[session dataTaskWithRequest:requestIntegrations completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!data) {
            NSLog(@"GET integrations list failed");
            exit(1);
        }
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *results = jsonDictionary[@"results"];
        if (results.count > 1) {
            results = [results subarrayWithRange:NSMakeRange(1, results.count - 1)];
            dispatch_group_t group = dispatch_group_create();
            NSLog(@"There is %d tasks to be DELETE", (int)results.count);

            NSLog(@"DELETE task is beginning");

            [results enumerateObjectsWithOptions:NSEnumerationReverse|NSEnumerationConcurrent
                                      usingBlock:^(NSDictionary *objItem, NSUInteger idx, BOOL * _Nonnull stop) {
                dispatch_group_enter(group);
                NSString *toDeleteId = objItem[@"_id"];
                NSString *toDeleteNumber = objItem[@"number"];
                NSLog(@"DELETE Beginning integration number : %@", toDeleteNumber);

                NSString *deleteUrl = [NSString stringWithFormat:@"%@/api/integrations/%@",server, toDeleteId];
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:deleteUrl]];
                request.HTTPMethod = @"DELETE";
                request.timeoutInterval = 15;
                [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable resData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
                    if (httpRes.statusCode == 200 || httpRes.statusCode == 204) {
                        NSLog(@"DELETE Success integration number is: %@", toDeleteNumber);
                    } else {
                        NSLog(@"DELETE Failed integration number is: %@\n %@", toDeleteNumber, httpRes);
                    }
                    dispatch_group_leave(group);
                }] resume];
            }];

            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                NSLog(@"DELETE group is over");
                exit(0);
            });
            NSLog(@"DELETE task is beginning over");

        } else {
            NSLog(@"There is no integrations to DELETE");
            exit(0);
        }
    }] resume];
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:NSDate.distantFuture];
    return 0;
}


int deleteBot(NSString *server, NSString *botId) {
    NSString *integrationsUrl = [NSString stringWithFormat:@"%@/api/bots/%@", server, botId];
    NSURL *serverUrl = [NSURL URLWithString:integrationsUrl];
    NSMutableURLRequest *requestIntegrations = [[NSMutableURLRequest alloc] initWithURL:serverUrl];
    requestIntegrations.HTTPMethod = @"DELETE";
    [requestIntegrations setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];/// 必须设置Content-Type application/json
    requestIntegrations.timeoutInterval = 15;
    NSLog(@"Delete bot:%@", botId);
    NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:SessionDelegate.sharedDelegate delegateQueue:nil];
    [[session dataTaskWithRequest:requestIntegrations completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
        if (httpRes.statusCode == 200 || httpRes.statusCode == 204) {
            NSLog(@"DELETE Success: %@", botId);
            exit(0);
        } else {
            NSLog(@"DELETE Failed: %@", botId);
            exit(1);
        }
    }] resume];
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:NSDate.distantFuture];
    return 0;
}
