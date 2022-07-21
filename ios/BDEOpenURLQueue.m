#import "BDEOpenURLQueue.h"

#import "array_map.h"

@implementation BDEOpenURLQueue

+ (instancetype)sharedQueue
{
    static BDEOpenURLQueue *sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = [[BDEOpenURLQueue alloc] init];
    });
    return sharedQueue;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _queue = @[];
    }
    
    return self;
}

- (void)add:(NSURL *)url
{
    _queue = [_queue arrayByAddingObject:url];
}

- (void)flush
{
    _queue = @[];
}

- (NSArray<NSString *> *)stringQueue
{
    return array_map(_queue, ^id _Nonnull(NSURL *url, NSUInteger idx) {
        return url.absoluteString;
    });
}

@end