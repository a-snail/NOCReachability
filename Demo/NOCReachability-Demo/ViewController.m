#import "ViewController.h"
#import "NOCReachability.h"
#define LOGLEVEL 31
#import "NOCLog.h"


@interface ViewController ()

@property (strong, nonatomic, nullable) NOCReachability *reachable;

@end


@implementation ViewController {
    NSArray *itemsTest;
}

#pragma mark - UIViewController overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initTable];

    if (!_reachable) {
        _reachable = NOCReachability.sharedInstance;
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDelegate overrides

- (void)tableView:(nonnull UITableView *)tableView
didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];

    switch (indexPath.row) {
        case 0:
            [self test01];
            break;
        case 1:
            [self test02];
            break;
        case 2:
            [self test03];
            break;
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource overrides

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView
                 cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *idReuse = @"TestItemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:idReuse];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:idReuse];
    }

    [cell.textLabel setText:[itemsTest objectAtIndex:indexPath.row]];

    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return itemsTest.count;
}

#pragma mark - Table initialize

- (void)initTable {
    itemsTest = @[
        @"check current reachable",
        @"start monitoring",
        @"stop monitoring"
    ];

    [_tblTestItems setAllowsSelection:YES];
    [_tblTestItems setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
}

#pragma mark - Tests

- (void)test01 {
    [self checkReachable];
}

- (void)test02 {
    __block ViewController *bSelf = self;
    [_reachable setStatusChangeBlock:^(NOCReachabilityStatus status) {
        [bSelf checkReachable];
    }];

    [_reachable startMonitoring];
}

- (void)test03 {
    if (_reachable) {
        [_reachable stopMonitoring];
    }
}

- (void)checkReachable {
    NSString *strStatus = [_reachable statusToString];
    NOCLogI(@"Reachability status : %@", strStatus);
}

@end
