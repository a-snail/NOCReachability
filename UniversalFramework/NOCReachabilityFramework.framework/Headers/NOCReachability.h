#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>


#pragma mark -

FOUNDATION_EXPORT NSString * _Nonnull const NOCReachabilityDidChangeNotification;
FOUNDATION_EXPORT NSString * _Nonnull const NOCReachabilityNotificationStatus;

typedef enum NOCReachabilityStatus {
    NOCReachabilityStatusUnknown            = -1,
    NOCReachabilityStatusNotReachable       = 0,
    NOCReachabilityStatusReachableViaWWAN   = 1,
    NOCReachabilityStatusReachableViaWiFi   = 2
} NOCReachabilityStatus;


#pragma mark -

@interface NOCReachability : NSObject

#pragma mark - Singleton

@property (readonly, strong, nonatomic, nonnull, class) NOCReachability *sharedInstance;

#pragma mark - NSObject overrides

- (nullable instancetype)init NS_UNAVAILABLE;

#pragma mark - Static public methods - Initialization

+ (nonnull instancetype)initForAddress:(nonnull const void *)address;
+ (nonnull instancetype)initForDefault;
+ (nonnull instancetype)initForDomain:(nonnull NSString *)domain;

#pragma mark - Public readonly properties

@property (readonly, assign, nonatomic) BOOL reachable;
@property (readonly, assign, nonatomic) BOOL reachableViaWWAN;
@property (readonly, assign, nonatomic) BOOL reachableViaWiFi;
@property (readonly, assign, nonatomic) NOCReachabilityStatus status;

#pragma mark - Public methods - Initialization

- (nonnull instancetype)initWithReachability:(nonnull SCNetworkReachabilityRef)reachability;

#pragma mark - Public methods - Monitoring

- (void)setStatusChangeBlock:(nullable void (^)(NOCReachabilityStatus status))block;
- (void)startMonitoring;
- (void)stopMonitoring;

#pragma mark - Public methods - Status

- (nonnull NSString *)statusToString;

@end
