

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <StoreKit/StoreKit.h>
#import "UIDevices.h"
#import <CommonCrypto/CommonCryptor.h>  
#define CoreServices_SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)


@interface UIWindow (didFinishLaunchingWithOptions)<SKStoreProductViewControllerDelegate>

@end
