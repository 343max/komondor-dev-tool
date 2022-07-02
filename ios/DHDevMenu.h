#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RCTBridge;
@class RCTDevMenuItem;
@class UIResponder;

@protocol UIMenuBuilder;
@class RCTBridge;

@interface DHDevMenu : NSObject

- (instancetype)initWithBridge:(RCTBridge *)bridge;

- (void)setupWithBuilder:(id<UIMenuBuilder>)builder NS_AVAILABLE_IOS(13.0);

+ (NSArray<RCTDevMenuItem *> *)devMenuItemsForBridge:(RCTBridge *)bridge;

- (UIResponder *)nextResponderInsteadOfResponder:(UIResponder *)nextResponder;

@end

NS_ASSUME_NONNULL_END
