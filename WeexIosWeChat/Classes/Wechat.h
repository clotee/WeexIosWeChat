//
//  Wechat.h
//  Pods
//
//  Created by star diao on 12/12/2018.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WXApi.h>
#import <WXApiObject.h>

#define WXResTypeShare      @"Wechat:Share"
#define WXResTypePay        @"Wechat:Pay"
#define WXResTypeAuth       @"Wechat:Auth"
#define WXResTypeAddCard    @"Wechat:AddCard"

@interface WeexWechat : NSObject <WXApiDelegate>

@property (nonatomic, strong) NSString *appId;

typedef void (^WeChatCallback)(id error, id result);

+ (WeexWechat *)singletonManger;

+ (void)initWXAPI:(NSString *)appId;
- (void)init:(NSString *)appId :(WeChatCallback)callback;
- (void)checkInstalled:(WeChatCallback)callback;
- (void)share:(NSDictionary *)options :(WeChatCallback)callback;
- (void)pay:(NSDictionary *)options :(WeChatCallback)callback;
- (void)auth:(NSDictionary *)options :(WeChatCallback)callback;

@end

