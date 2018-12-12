//
//  WXShareModel.h
//  Pods
//
//  Created by star diao on 12/12/2018.
//

#import <Foundation/Foundation.h>
#import <WeexSDK/WeexSDK.h>

@protocol WXWechatPro <WXModuleProtocol>

- (void)init:(NSString *)appId :(WXModuleCallback)callback;
- (void)checkInstalled:(WXModuleCallback)callback;
- (void)share:(NSDictionary *)params :(WXModuleCallback)callback;
- (void)pay:(NSDictionary *)params :(WXModuleCallback)callback;
- (void)auth:(NSDictionary *)params :(WXModuleCallback)callback;

@end

@interface WXShareModel : NSObject<WXWechatPro>

@end

