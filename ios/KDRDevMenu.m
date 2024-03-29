#import "KDRDevMenu.h"

#import "KDRDevHelper.h"
#import "array_map.h"
#import "KDRMainWindowHandler.h"
#import "KDRBundleURLProvider.h"

#import <React/RCTBridge.h>
#import <React/RCTDevSettings.h>

#if __has_include(<React/RCTDevMenu.h>)
#import <React/RCTDevMenu.h>
#endif

#if KOMONDOR_ENABLED

@interface RCTDevMenu ()
- (NSArray<RCTDevMenuItem *> *)_menuItemsToPresent;
@end

@interface MenuResponder : UIResponder

@property (weak, nonatomic) UIResponder *_nextResponder;
@property (strong, nonatomic, readonly) NSMutableArray<dispatch_block_t> *handlers;

- (SEL)generateSelector:(dispatch_block_t)handler;

@end

@implementation MenuResponder

- (instancetype)init
{
    self = [super init];
    if (self) {
        _handlers = [NSMutableArray array];
    }
    return self;
}

- (UIResponder *)nextResponder
{
    return __nextResponder;
}

- (SEL)generateSelector:(dispatch_block_t)handler
{
    NSString *stringSelector = [NSString stringWithFormat:@"handler_%lu", _handlers.count];
    SEL selector = NSSelectorFromString(stringSelector);
    
    [_handlers addObject:handler];
    
    return selector;
}

#define _handler(index) \
- (void)handler_##index \
{                       \
_handlers[index]();   \
}

_handler(0);
_handler(1);
_handler(2);
_handler(3);
_handler(4);
_handler(5);
_handler(6);
_handler(7);
_handler(8);
_handler(9);
_handler(10);
_handler(11);
_handler(12);
_handler(13);
_handler(14);
_handler(15);
_handler(16);
_handler(17);
_handler(18);
_handler(19);

@end

@interface KDRDevMenu (MenuGenerators)
- (UIMenuElement *)resizeMenuForTitle:(NSString *)title size:(CGSize)size;
- (UIMenuElement *)alphaMenuForTitle:(NSString *)title alpha:(CGFloat)alpha;
@end


@interface KDRDevMenu ()

@property (strong, nonatomic) UIMenu *devMenu NS_AVAILABLE_IOS(13.0);
@property (strong, nonatomic) MenuResponder *menuResponder;
@property (weak, nonatomic, readonly) RCTBridge *bridge;

+ (BOOL)devSettingsEnabledForBridge:(RCTBridge *)bridge;
+ (NSArray<RCTDevMenuItem *> *)devMenuItemsForBridge:(RCTBridge *)bridge;

@end

@interface RCTDevMenuItem ()

- (void)callHandler;
- (NSString *)title;

@end

@implementation KDRDevMenu

+ (BOOL)isRunningOnMac
{
    if (@available(iOS 14.0, *)) {
        return [NSProcessInfo processInfo].isiOSAppOnMac;
    } else {
        return false;
    }
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}

- (void)setupWithBuilder:(id<UIMenuBuilder>)builder NS_AVAILABLE_IOS(13.0);
{
    _menuResponder = [[MenuResponder alloc] init];
    
    SEL floatOnTopAction = [_menuResponder generateSelector:^{
        [[KDRDevHelper sharedHelper] toggleFloatOnTopOfEverything];
        [[UIMenuSystem mainSystem] setNeedsRebuild];
    }];
    
    UICommand *stayOnTop = [UICommand commandWithTitle:@"Float On Top"
                                                 image:nil
                                                action:floatOnTopAction
                                          propertyList:nil];
    
    stayOnTop.state = [KDRDevHelper sharedHelper].floatsOnTopOfEverything ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    SEL floatOnTopOfEditorsAction = [_menuResponder generateSelector:^{
        [[KDRDevHelper sharedHelper] toggleFloatOnTopOfEditors];
        [[UIMenuSystem mainSystem] setNeedsRebuild];
    }];
    
    UICommand *stayOnTopOfEditors = [UICommand commandWithTitle:@"Float On Top of VSCode"
                                                          image:nil
                                                         action:floatOnTopOfEditorsAction
                                                   propertyList:nil];
    
    stayOnTopOfEditors.state = [KDRDevHelper sharedHelper].floatsOnTopOfEditors ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    
    SEL packagePickerMenuAction = [_menuResponder generateSelector:^{
        [[KDRBundleURLProvider sharedProvider] switchToInternalPicker];
    }];
    
    UICommand *packagePickerMenu = [UICommand commandWithTitle:@"Show Package Picker 🐶"
                                                         image:nil
                                                        action:packagePickerMenuAction
                                                  propertyList:nil];
    
    packagePickerMenu.attributes = [KDRBundleURLProvider sharedProvider].showsInternalPicker ? UIMenuElementAttributesDisabled : 0;
    
    __weak KDRDevMenu *weakSelf = self;
    SEL showDevMenuAction = [_menuResponder generateSelector:^{
        [weakSelf.bridge.devMenu show];
    }];
    
    UICommand *showDevMenu = [UIKeyCommand commandWithTitle:@"Show RN Dev Menu"
                                                      image:nil
                                                     action:showDevMenuAction
                                                      input:@"Z"
                                              modifierFlags:UIKeyModifierCommand | UIKeyModifierControl
                                               propertyList:nil];
    
    showDevMenu.attributes =  [KDRDevMenu devSettingsEnabledForBridge:weakSelf.bridge] ? 0 : UIMenuElementAttributesDisabled;
    
    NSArray *devMenuItems = array_map([KDRDevMenu devMenuItemsForBridge:_bridge], ^id _Nonnull(RCTDevMenuItem *item, NSUInteger idx) {
        NSString *keyEquivalent = nil;
        NSString *title = [item title];
        if ([title isEqualToString:@"Reload"]) {
            keyEquivalent = @"r";
        } else if([title isEqualToString:@"Stop Debugging"] | [title isEqualToString:@"Debug with Chrome"]) {
            keyEquivalent = @"d";
        } else if([title isEqualToString:@"Show Perf Monitor"] | [title isEqualToString:@"Hide Perf Monitor"]) {
            keyEquivalent = @"p";
        } else if([title isEqualToString:@"Show Inspector"] | [title isEqualToString:@"Hide Inspector"]) {
            keyEquivalent = @"i";
        }
        
        SEL action = [self.menuResponder generateSelector:^{
            [item callHandler];
            [[UIMenuSystem mainSystem] setNeedsRebuild];
        }];
        
        if (keyEquivalent == nil) {
            return [UICommand commandWithTitle:title
                                         image:nil
                                        action:action
                                  propertyList:nil];
        } else {
            return [UIKeyCommand commandWithTitle:title
                                            image:nil
                                           action:action
                                            input:keyEquivalent
                                    modifierFlags:UIKeyModifierCommand | UIKeyModifierControl
                                     propertyList:nil];
        }
    }).mutableCopy ;
    
    UIMenu *resizeMenu = [UIMenu menuWithTitle:@"Resize"
                                      children:@[
        [self resizeMenuForTitle:@"iPhone 12" size:CGSizeMake(390, 844)],
        [self resizeMenuForTitle:@"iPhone 12 mini" size:CGSizeMake(375, 812)],
        [self resizeMenuForTitle:@"iPhone 12 max" size:CGSizeMake(428, 926)],
        [self resizeMenuForTitle:@"iPhone SE" size:CGSizeMake(375, 667)]
    ]];
    
    SEL ignoresClicksAction = [self.menuResponder generateSelector:^{
        [KDRDevHelper sharedHelper].backgroundIgnoresClicks = ![KDRDevHelper sharedHelper].backgroundIgnoresClicks;
        [[UIMenuSystem mainSystem] setNeedsRebuild];
    }];
    
    UICommand *ignoresClicksMenu = [UICommand commandWithTitle:@"Ignores Clicks"
                                                         image:nil
                                                        action:ignoresClicksAction
                                                  propertyList:nil];
    ignoresClicksMenu.state = [KDRDevHelper sharedHelper].backgroundIgnoresClicks ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    UIMenu *windowAlphaMenu = [UIMenu menuWithTitle:@"Inactive Window"
                                           children:@[
        ignoresClicksMenu,
        [self alphaMenuForTitle:@"Alpha 100%" alpha:1.0],
        [self alphaMenuForTitle:@"Alpha 75%" alpha:0.75],
        [self alphaMenuForTitle:@"Alpha 50%" alpha:0.5],
        [self alphaMenuForTitle:@"Alpha 25%" alpha:0.25]
    ]];
    
    NSArray *menuItems = [@[
        stayOnTop,
        stayOnTopOfEditors,
        resizeMenu,
        windowAlphaMenu,
        packagePickerMenu,
        showDevMenu,
    ] arrayByAddingObjectsFromArray:devMenuItems];
    
    _devMenu = [UIMenu menuWithTitle:@"Komondor" children:menuItems];
    
    [builder insertSiblingMenu:_devMenu beforeMenuForIdentifier:UIMenuHelp];
}

- (id)nextResponderInsteadOfResponder:(id)nextResponder
{
    _menuResponder._nextResponder = nextResponder;
    return _menuResponder;
}

+ (BOOL)devSettingsEnabledForBridge:(RCTBridge *)bridge
{
    return bridge.devSettings != nil;
}

#if __has_include(<React/RCTDevMenu.h>)
+ (NSArray<RCTDevMenuItem *> *)devMenuItemsForBridge:(RCTBridge *)bridge
{
    if ([self devSettingsEnabledForBridge:bridge]) {
        return [bridge.devMenu _menuItemsToPresent];
    } else {
        return @[];
    }
}

#else
+ (NSArray<RCTDevMenuItem *> *)devMenuItemsForBridge:(RCTBridge *)bridge
{
    return @[];
}
#endif

@end

@implementation KDRDevMenu (MenuGenerators)

- (UIMenuElement *)resizeMenuForTitle:(NSString *)title size:(CGSize)size
{
    SEL action = [_menuResponder generateSelector:^{
        [[KDRDevHelper sharedHelper].windowHandler setWindowSize:size animated:YES];
    }];
    
    return [UICommand commandWithTitle:title
                                 image:nil
                                action:action
                          propertyList:nil];
}

- (UIMenuElement *)alphaMenuForTitle:(NSString *)title alpha:(CGFloat)alpha
{
    SEL action = [_menuResponder generateSelector:^{
        [KDRDevHelper sharedHelper].backgroundAlpha = alpha;
        [[UIMenuSystem mainSystem] setNeedsRebuild];
    }];
    
    UICommand *command = [UICommand commandWithTitle:title
                                               image:nil
                                              action:action
                                        propertyList:nil];
    
    command.state = [KDRDevHelper sharedHelper].backgroundAlpha == alpha ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return command;
}


@end

#endif
