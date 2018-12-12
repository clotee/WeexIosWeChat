//
//  WXShareModel.m
//  Kiwi
//
//  Created by star diao on 12/12/2018.
//

#import "WXShareModel.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import "Wechat.h"

@implementation WXShareModel

@synthesize weexInstance;

WX_PlUGIN_EXPORT_MODULE(wechat, WXShareModel)
WX_EXPORT_METHOD(@selector(init::))
WX_EXPORT_METHOD(@selector(checkInstalled:))
WX_EXPORT_METHOD(@selector(share::))
WX_EXPORT_METHOD(@selector(pay::))
WX_EXPORT_METHOD(@selector(auth::))

- (void)init:(NSString *)appId :(WXModuleCallback)callback{
    [[WeexWechat singletonManger] init:appId :^(id error, id result) {
        if (error) {
            if (callback) {
                callback(error);
            }
        } else {
            if (callback) {
                callback(result);
            }
        }
    }];
}

- (void)checkInstalled:(WXModuleCallback)callback{
    [[WeexWechat singletonManger] checkInstalled:^(id error, id result) {
        if (error) {
            if (callback) {
                callback(error);
            }
        } else {
            if (callback) {
                callback(result);
            }
        }
    }];
}

- (void)share:(NSDictionary *)params :(WXModuleCallback)callback{
    [[WeexWechat singletonManger] share:params :^(id error, id result) {
        if (error) {
            if (callback) {
                callback(error);
            }
        } else {
            if (callback) {
                callback(result);
            }
        }
    }];
}

- (void)pay:(NSDictionary *)params :(WXModuleCallback)callback{
    [[WeexWechat singletonManger] pay:params :^(id error, id result) {
        if (error) {
            if (callback) {
                callback(error);
            }
        } else {
            if (callback) {
                callback(result);
            }
        }
    }];
}

- (void)auth:(NSDictionary *)params :(WXModuleCallback)callback{
    [[WeexWechat singletonManger] auth:params :^(id error, id result) {
        if (error) {
            if (callback) {
                callback(error);
            }
        } else {
            if (callback) {
                callback(result);
            }
        }
    }];
}

@end

