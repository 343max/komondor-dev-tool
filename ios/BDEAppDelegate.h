#import <React/RCTBridgeDelegate.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern int BDEApplicationMain(int argc, char * _Nullable argv[_Nonnull], NSString * _Nullable principalClassName, NSString * _Nullable delegateClassName);

@interface BDEAppDelegate : UIResponder <UIApplicationDelegate>

@end

NS_ASSUME_NONNULL_END
