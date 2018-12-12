//
//  Wechat.m
//  Kiwi
//
//  Created by star diao on 12/12/2018.
//

#import "Wechat.h"

static int const MAX_THUMBNAIL_SIZE = 320;

/** 分享类型 */
typedef NS_ENUM(NSInteger,shareType) {
    ShareTypeText,
    ShareTypeImage,
    ShareTypeTextImage,
    ShareTypeWebpage,
    ShareTypeMusic,
    ShareTypeVideo,
    ShareTypeMiniProgram
};

@interface WeexWechat ()
@end

@implementation WeexWechat

+ (WeexWechat *)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

+ (void)initWXAPI:(NSString *)appId {
    [WXApi registerApp: appId];
}

- (void)init:(NSString *)appId :(WeChatCallback)callback {
    [WeexWechat initWXAPI: appId];
    callback(nil, nil);
}

- (void)checkInstalled:(WeChatCallback)callback {
    BOOL isInstalled = [WXApi isWXAppInstalled];
    callback(nil, [NSNumber numberWithBool:isInstalled]);
}

- (void)share:(NSDictionary *)options :(WeChatCallback)callback {
    // check installed
    if (![WXApi isWXAppInstalled]) {
        callback(@{@"error":@{@"msg":@"微信未安装", @"code":@"301201"}}, nil);
        return;
    }
    
    
    //    NSDictionary *media = [options objectForKey:@"media"];
    //    NSInteger shareType = [[media objectForKey:@"shareType"] integerValue];
    //    id object = nil;
    //    id message = nil;
    //    switch (shareType) {
    //        case ShareTypeMiniProgram:{
    //            ((WXMiniProgramObject*)object).webpageUrl = [media objectForKey:@"webpageUrl"];
    //            ((WXMiniProgramObject*)object).userName = [media objectForKey:@"userName"];
    //            ((WXMiniProgramObject*)object).path = [media objectForKey:@"path"];
    //            ((WXMiniProgramObject*)object).hdImageData = nil;
    //            ((WXMiniProgramObject*)object).withShareTicket = YES;
    //            ((WXMiniProgramObject*)object).miniProgramType = WXMiniProgramTypePreview;
    //
    //            WXMediaMessage *message = [WXMediaMessage message];
    //            message.title = @"小程序标题";
    //            message.description = @"小程序描述";
    //            message.thumbData = nil;  //兼容旧版本节点的图片，小于32KB，新版本优先
    //            message.mediaObject = object;
    //            break;
    //        }
    //        default:
    //            NSLog(@"default share");
    //            break;
    //    }
    NSNumber *miniProgramType =  [options objectForKey:@"miniProgramType"];
    NSString *hdImageBase64 = [options objectForKey:@"hdImageData"];
    NSData *hdImageData = [[NSData alloc]initWithBase64EncodedString:hdImageBase64 options:(NSDataBase64DecodingIgnoreUnknownCharacters)];
    WXMiniProgramObject *object = [WXMiniProgramObject object];
    object.webpageUrl       = [options objectForKey:@"webpageUrl"];
    object.userName         = [options objectForKey:@"userName"];
    object.path             = [options objectForKey:@"path"];
    object.hdImageData      = hdImageData;
    object.withShareTicket  = YES;
    //    NSLog(@"numberWithInt %@", miniProgramType);
    if ([miniProgramType isEqualToNumber:[NSNumber numberWithInt:1]]) {
        object.miniProgramType  = WXMiniProgramTypeRelease;
    } else if ([miniProgramType isEqualToNumber:[NSNumber numberWithInt:2]]){
        object.miniProgramType  = WXMiniProgramTypeTest;
    } else if ([miniProgramType isEqualToNumber:[NSNumber numberWithInt:3]]) {
        object.miniProgramType  = WXMiniProgramTypePreview;
    } else {
        object.miniProgramType = WXMiniProgramTypeRelease;
    }
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = [options objectForKey:@"title"];
    message.description = [options objectForKey:@"description"];
    message.thumbData = nil;  //兼容旧版本节点的图片，小于32KB，新版本优先
    //使用WXMiniProgramObject的hdImageData属性
    message.mediaObject = object;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneSession;  //目前只支持会话
    
    
    
    if ([WXApi sendReq:req]) {
        __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:WXResTypeShare object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * notification) {
            [self handleProcessResponse:notification :callback];
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }];
    } else {
        callback(@{@"error":@{@"msg":@"发送请求失败", @"code":@"301401"}}, nil);
    }
}

- (void)auth:(NSDictionary *)options :(WeChatCallback)callback {
    
    SendAuthReq* req =[[SendAuthReq alloc] init];
    
    if ([options objectForKey:@"scene"]) {
        req.scope = [options objectForKey:@"scene"];
    } else {
        req.scope = @"snsapi_userinfo";
    }
    
    if ([options objectForKey:@"state"]) {
        req.state = [options objectForKey:@"state"];
    }
    
    if ([WXApi sendReq:req]) {
        __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:WXResTypeAuth object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * notification) {
            [self handleProcessResponse:notification :callback];
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }];
    } else {
        callback(@{@"error":@{@"msg":@"发送请求失败", @"code":@"301401"}}, nil);
    }
}

- (void)pay:(NSDictionary *)options :(WeChatCallback)callback {
    
    // check required parameters
    NSArray *requiredParams;
    
    if ([options objectForKey:@"mch_id"]) {
        requiredParams = @[@"mch_id", @"prepay_id", @"timestamp", @"nonce", @"sign"];
    } else {
        requiredParams = @[@"partnerid", @"prepayid", @"timestamp", @"noncestr", @"sign"];
    }
    
    for (NSString *key in requiredParams) {
        if (![options objectForKey:key]) {
            callback(@{@"error":@{@"msg":@"参数格式错误", @"code":@"301501"}}, nil);
            return;
        }
    }
    
    PayReq *req = [[PayReq alloc] init];
    req.partnerId = [options objectForKey:requiredParams[0]];
    req.prepayId = [options objectForKey:requiredParams[1]];
    req.timeStamp = [[options objectForKey:requiredParams[2]] intValue];
    req.nonceStr = [options objectForKey:requiredParams[3]];
    req.package = @"Sign=WXPay";
    req.sign = [options objectForKey:requiredParams[4]];
    
    if ([WXApi sendReq:req]) {
        __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:WXResTypePay object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * notification) {
            [self handleProcessResponse:notification :callback];
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }];
    } else {
        callback(@{@"error":@{@"msg":@"发送请求失败", @"code":@"301401"}}, nil);
    }
}

#pragma mark "Private methods"

- (void)handleProcessResponse:(NSNotification *)notification :(WeChatCallback)callback
{
    NSDictionary *result = notification.userInfo;
    int status = (int)[[result objectForKey:@"status"] integerValue];
    
    if (status == 0) {
        callback(nil, result);
    } else {
        NSDictionary *error = [result objectForKey:@"error"];
        callback(@{@"error":error}, nil);
    }
}

- (WXMediaMessage *)buildSharingMessage:(NSDictionary *)content
{
    WXMediaMessage *wxMediaMessage = [WXMediaMessage message];
    wxMediaMessage.title = [content objectForKey:@"title"];
    wxMediaMessage.description = [content objectForKey:@"description"];
    wxMediaMessage.mediaTagName = [content objectForKey:@"mediaTagName"];
    wxMediaMessage.messageExt = [content objectForKey:@"messageExt"];
    wxMediaMessage.messageAction = [content objectForKey:@"messageAction"];
    if ([content objectForKey:@"thumbUrl"])
    {
        [wxMediaMessage setThumbImage:[self getUIImageFromURL:[content objectForKey:@"thumbUrl"]]];
    }
    
    // media parameters
    id mediaObject = nil;
    
    // check types
    NSInteger type = [[content objectForKey:@"type"] integerValue];
    
    switch (type)
    {
        case 1:
            mediaObject = [WXAppExtendObject object];
            ((WXAppExtendObject*)mediaObject).extInfo = [content objectForKey:@"extInfo"];
            ((WXAppExtendObject*)mediaObject).url = [content objectForKey:@"filePath"];
            break;
            
        case 2:
            mediaObject = [WXEmoticonObject object];
            ((WXEmoticonObject*)mediaObject).emoticonData = [self getNSDataFromURL:[content objectForKey:@"dataUrl"]];
            break;
            
        case 3:
            mediaObject = [WXFileObject object];
            ((WXFileObject*)mediaObject).fileData = [self getNSDataFromURL:[content objectForKey:@"filePath"]];
            ((WXFileObject*)mediaObject).fileExtension = [content objectForKey:@"fileExtension"];
            break;
            
        case 4:
            mediaObject = [WXImageObject object];
            ((WXImageObject*)mediaObject).imageData = [self getNSDataFromURL:[content objectForKey:@"dataUrl"]];
            break;
            
        case 5:
            mediaObject = [WXMusicObject object];
            ((WXMusicObject*)mediaObject).musicUrl = [content objectForKey:@"link"];
            ((WXMusicObject*)mediaObject).musicDataUrl = [content objectForKey:@"dataUrl"];
            break;
            
        case 6:
            mediaObject = [WXVideoObject object];
            ((WXVideoObject*)mediaObject).videoUrl = [content objectForKey:@"dataUrl"];
            break;
            
        case 7:
        default:
            mediaObject = [WXWebpageObject object];
            ((WXWebpageObject *)mediaObject).webpageUrl = [content objectForKey:@"link"];
    }
    
    wxMediaMessage.mediaObject = mediaObject;
    return wxMediaMessage;
}

- (NSData *)getNSDataFromURL:(NSString *)url
{
    NSData *data = nil;
    
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"])
    {
        data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    }
    else if ([url hasPrefix:@"data:image"])
    {
        // a base 64 string
        NSURL *base64URL = [NSURL URLWithString:url];
        data = [NSData dataWithContentsOfURL:base64URL];
    }
    else if ([url rangeOfString:@"temp:"].length != 0)
    {
        url =  [NSTemporaryDirectory() stringByAppendingPathComponent:[url componentsSeparatedByString:@"temp:"][1]];
        data = [NSData dataWithContentsOfFile:url];
    }
    else
    {
        // local file
        url = [[NSBundle mainBundle] pathForResource:[url stringByDeletingPathExtension] ofType:[url pathExtension]];
        data = [NSData dataWithContentsOfFile:url];
    }
    
    return data;
}

- (UIImage *)getUIImageFromURL:(NSString *)url
{
    NSData *data = [self getNSDataFromURL:url];
    UIImage *image = [UIImage imageWithData:data];
    
    if (image.size.width > MAX_THUMBNAIL_SIZE || image.size.height > MAX_THUMBNAIL_SIZE)
    {
        CGFloat width = 0;
        CGFloat height = 0;
        
        // calculate size
        if (image.size.width > image.size.height)
        {
            width = MAX_THUMBNAIL_SIZE;
            height = width * image.size.height / image.size.width;
        }
        else
        {
            height = MAX_THUMBNAIL_SIZE;
            width = height * image.size.width / image.size.height;
        }
        
        // scale it
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
        [image drawInRect:CGRectMake(0, 0, width, height)];
        UIImage *scaled = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return scaled;
    }
    
    return image;
}

- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark "WXApiDelegate"

/**
 * Not implemented
 */
- (void)onReq:(BaseReq *)req
{
    NSLog(@"%@", req);
}

- (void)onResp:(BaseResp *)resp
{
    BOOL success = NO;
    NSString *message = @"Unknown";
    NSDictionary *result = nil;
    NSNotification * notification = nil;
    
    switch (resp.errCode) {
        case WXSuccess:
            success = YES;
            break;
            
        case WXErrCodeCommon:
            message = @"普通错误";
            break;
            
        case WXErrCodeUserCancel:
            message = @"用户取消";
            break;
            
        case WXErrCodeSentFail:
            message = @"发送失败";
            break;
            
        case WXErrCodeAuthDeny:
            message = @"授权失败";
            break;
            
        case WXErrCodeUnsupport:
            message = @"微信不支持";
            break;
            
        default:
            message = @"未知错误";
    }
    
    if (!success) {
        result = @{
                   @"status": @(resp.errCode),
                   @"error": @{
                           @"msg": resp.errStr != nil ? resp.errStr : message,
                           @"code": @(resp.errCode)
                           }
                   };
    }
    
    // share
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        if (success) {
            result = @{@"status": @0};
        }
        
        notification = [NSNotification notificationWithName:WXResTypeShare object:nil userInfo:result];
    }
    // auth
    else if ([resp isKindOfClass:[SendAuthResp class]]) {
        if (success) {
            SendAuthResp* authResp = (SendAuthResp*)resp;
            result = @{
                       @"status": @0,
                       @"code": authResp.code != nil ? authResp.code : @"",
                       @"state": authResp.state != nil ? authResp.state : @"",
                       @"lang": authResp.lang != nil ? authResp.lang : @"",
                       @"country": authResp.country != nil ? authResp.country : @""
                       };
        }
        
        notification = [NSNotification notificationWithName:WXResTypeAuth object:nil userInfo:result];
    }
    // pay
    else if([resp isKindOfClass:[PayResp class]]){
        if (success) {
            result = @{@"status": @0};
        }
        
        notification = [NSNotification notificationWithName:WXResTypePay object:nil userInfo:result];
    }
    // add card
    else if ([resp isKindOfClass:[AddCardToWXCardPackageResp class]]) {
        if (success) {
            result = @{@"status": @0};
        }
        
        notification = [NSNotification notificationWithName:WXResTypeAddCard object:nil userInfo:result];
    }
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
}

@end

