#import "NOCReachability.h"
#import <netinet/in.h>
#import <netinet6/in6.h>
#import "NOCLog.h"


#pragma mark - Extern strings

NSString * const NOCReachabilityDidChangeNotification = @"com.nuliapp.nocreachability.change";
NSString * const NOCReachabilityNotificationStatus    = @"NOCReachabilityNotificationStatus";


#pragma mark - Type

typedef void (^NOCReachabilityStatusBlock)(NOCReachabilityStatus status);


#pragma mark - Static Functions

static NOCReachabilityStatus NOCReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL reachable =
            ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL connectNeeds =
            ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL connectAutomatically =
            (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
             ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL connectWithoutUser =
            (connectAutomatically &&
             (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isReachable = (reachable && (!connectNeeds || connectWithoutUser));

    NOCReachabilityStatus status = NOCReachabilityStatusUnknown;
    if (isReachable == NO) {
        status = NOCReachabilityStatusNotReachable;
    }
#if TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = NOCReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = NOCReachabilityStatusReachableViaWiFi;
    }
    return status;
}

static void NOCReachabilityStatusChange(SCNetworkReachabilityFlags flags,
                                        NOCReachabilityStatusBlock block) {
    NOCReachabilityStatus status = NOCReachabilityStatusForFlags(flags);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block(status);
        }
        NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
        NSDictionary *info = @{NOCReachabilityNotificationStatus:@(status)};
        [nc postNotificationName:NOCReachabilityDidChangeNotification
                          object:nil
                        userInfo:info];
    });
}

static void NOCReachabilityCallback(SCNetworkReachabilityRef __unused target,
                                    SCNetworkReachabilityFlags flags,
                                    void *info) {
    NOCReachabilityStatusChange(flags,
                                (__bridge NOCReachabilityStatusBlock)info);
}

static void NOCReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

static const void *NOCReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}


@interface NOCReachability ()

#pragma mark - Private properties

@property (readonly, assign, nonatomic) SCNetworkReachabilityRef refReachability;
@property (readwrite, nonatomic, assign) NOCReachabilityStatus status;
@property (readwrite, nonatomic, copy) NOCReachabilityStatusBlock statusBlock;

@end


@implementation NOCReachability

#pragma mark - Singleton

+ (nonnull instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self initForDefault];
    });
    return sharedInstance;
}

#pragma mark - NSObject overrides

- (void)dealloc {
    NOCLogV(@"");
    [self stopMonitoring];

    if (_refReachability) {
        CFRelease(_refReachability);
    }
}

- (nullable instancetype)init NS_UNAVAILABLE {
    return nil;
}

#pragma mark - NSKeyValueObserving overrides

+ (nonnull NSSet *)keyPathsForValuesAffectingValueForKey:(nonnull NSString *)key {
    if ([key isEqualToString:@"reachable"] ||
        [key isEqualToString:@"reachableViaWWAN"] ||
        [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"NOCReachabilityStatus"];
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
}

#pragma mark - Static public methods - Initialization

+ (nonnull instancetype)initForAddress:(nonnull const void *)address {
    SCNetworkReachabilityRef reachability =
    SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault,
                                           (const struct sockaddr *)address);
    NOCReachability *instance = [[self alloc] initWithReachability:reachability];
    CFRelease(reachability);
    return instance;
}

+ (nonnull instancetype)initForDefault {
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || \
    (defined(__MAC_OS_X_VERSION_MIN_REQUIRED)  && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len    = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif
    return [self initForAddress:&address];
}

+ (nonnull instancetype)initForDomain:(nonnull NSString *)domain {
    SCNetworkReachabilityRef reachability =
    SCNetworkReachabilityCreateWithName(kCFAllocatorDefault,
                                        [domain UTF8String]);
    NOCReachability *instance = [[self alloc] initWithReachability:reachability];
    CFRelease(reachability);
    return instance;
}

#pragma mark - Public readonly properties

- (BOOL)reachable {
    return ([self reachableViaWWAN] || [self reachableViaWiFi]);
}

- (BOOL)reachableViaWWAN {
    return (self.status == NOCReachabilityStatusReachableViaWWAN);
}

- (BOOL)reachableViaWiFi {
    return (self.status == NOCReachabilityStatusReachableViaWiFi);
}

- (NOCReachabilityStatus)status {
    _status = NOCReachabilityStatusUnknown;
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(_refReachability, &flags)) {
        _status = NOCReachabilityStatusForFlags(flags);
    }
    return _status;
}

#pragma mark - Public methods - Initialization

- (nonnull instancetype)initWithReachability:(nonnull SCNetworkReachabilityRef)reachability {
    NOCLogV(@"reachability : %@", reachability);
    if ((self = [super init])) {
        _refReachability = CFRetain(reachability);
    }
    else {
        CFRelease(reachability);
    }
    return self;
}

#pragma mark - Public methods - Monitoring

- (void)setStatusChangeBlock:(nullable void (^)(NOCReachabilityStatus status))block {
    NOCLogV(@"block : %@", block);
    _statusBlock = block;
}

- (void)startMonitoring {
    NOCLogV(@"");
    [self stopMonitoring];

    if (!_refReachability) {
        return;
    }

    __block NOCReachability *bSelf = self;
    NOCReachabilityStatusBlock callback = ^(NOCReachabilityStatus status) {
        bSelf.status = status;
        if (bSelf.statusBlock) {
            bSelf.statusBlock(status);
        }
    };

    SCNetworkReachabilityContext context = {
        0,
        (__bridge void *)callback,
        NOCReachabilityRetainCallback,
        NOCReachabilityReleaseCallback,
        NULL
    };
    SCNetworkReachabilitySetCallback(_refReachability,
                                     NOCReachabilityCallback,
                                     &context);
    SCNetworkReachabilityScheduleWithRunLoop(_refReachability,
                                             CFRunLoopGetMain(),
                                             kCFRunLoopCommonModes);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(bSelf.refReachability, &flags)) {
            NOCReachabilityStatusChange(flags, callback);
        }
    });
}

- (void)stopMonitoring {
    NOCLogV(@"");
    if (!_refReachability) {
        return;
    }

    SCNetworkReachabilityUnscheduleFromRunLoop(_refReachability,
                                               CFRunLoopGetMain(),
                                               kCFRunLoopCommonModes);
}

#pragma mark - Public methods - Status

- (nonnull NSString *)statusToString {
    NOCLogV(@"");
    switch (self.status) {
        case NOCReachabilityStatusNotReachable:
            return NSLocalizedString(@"NotReachable", nil);
        case NOCReachabilityStatusReachableViaWWAN:
            return NSLocalizedString(@"ReachableViaWWAN", nil);
        case NOCReachabilityStatusReachableViaWiFi:
            return NSLocalizedString(@"ReachableViaWiFi", nil);
        case NOCReachabilityStatusUnknown:
        default:
            return NSLocalizedString(@"Unknown", nil);
    }
}

@end
