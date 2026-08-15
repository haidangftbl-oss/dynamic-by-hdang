#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

// --- Overlay Window Xuyên Thấu Cảm Ứng ---
@interface DynamicIslandWindow : UIWindow
@end

@implementation DynamicIslandWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *subview in self.subviews) {
        if (!subview.hidden && subview.alpha > 0 && subview.userInteractionEnabled) {
            CGPoint convertedPoint = [subview convertPoint:point fromView:self];
            if ([subview pointInside:convertedPoint withEvent:event]) {
                return YES;
            }
        }
    }
    return NO;
}
@end

// --- Dynamic Island View Central Engine ---
@interface DynamicIslandView : UIView
@property (nonatomic, strong) UIImageView *appIconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, strong) NSTimer *autoCollapseTimer;

+ (instancetype)sharedInstance;
- (void)triggerEventWithTitle:(NSString *)title subtitle:(NSString *)subtitle systemImage:(NSString *)systemImage customImage:(UIImage *)customImage duration:(NSTimeInterval)duration;
- (void)collapseIsland;
- (void)updateLayoutForOrientation:(UIInterfaceOrientation)orientation;
@end

@implementation DynamicIslandView

+ (instancetype)sharedInstance {
    static DynamicIslandView *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[DynamicIslandView alloc] initWithFrame:CGRectMake(0, 0, 115, 22)];
    });
    return shared;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.layer.cornerRadius = frame.size.height / 2.0;
        self.layer.masksToBounds = YES;
        self.userInteractionEnabled = YES;
        self.isExpanded = NO;

        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [UIColor colorWithWhite:0.25 alpha:1.0].CGColor;

        // Biểu tượng / Icon
        self.appIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 3, 16, 16)];
        self.appIconImageView.layer.cornerRadius = 8;
        self.appIconImageView.clipsToBounds = YES;
        self.appIconImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.appIconImageView.tintColor = [UIColor whiteColor];
        [self addSubview:self.appIconImageView];

        // Tiêu đề
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 3, 85, 16)];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
        self.titleLabel.alpha = 0.0;
        [self addSubview:self.titleLabel];

        // Phụ đề
        self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 22, 200, 14)];
        self.subtitleLabel.textColor = [UIColor lightGrayColor];
        self.subtitleLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightRegular];
        self.subtitleLabel.alpha = 0.0;
        [self addSubview:self.subtitleLabel];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)handleTap {
    if (self.isExpanded) {
        [self collapseIsland];
    }
}

// Hiệu ứng Spring Animation mượt chuẩn iOS 14 Pro
- (void)triggerEventWithTitle:(NSString *)title subtitle:(NSString *)subtitle systemImage:(NSString *)systemImage customImage:(UIImage *)customImage duration:(NSTimeInterval)duration {
    self.isExpanded = YES;
    [self.autoCollapseTimer invalidate];

    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;

    if (customImage) {
        self.appIconImageView.image = customImage;
    } else if (systemImage && @available(iOS 13.0, *)) {
        self.appIconImageView.image = [UIImage systemImageNamed:systemImage];
    }

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;

    [UIView animateWithDuration:0.50
                          delay:0
         usingSpringWithDamping:0.68
          initialSpringVelocity:0.85
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.frame = CGRectMake(0, 0, screenWidth - 24, 60);
        self.center = CGPointMake(screenWidth / 2.0, 36);
        self.layer.cornerRadius = 28;

        self.appIconImageView.frame = CGRectMake(12, 10, 22, 22);
        self.titleLabel.frame = CGRectMake(42, 8, screenWidth - 85, 18);
        self.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        self.titleLabel.alpha = 1.0;

        self.subtitleLabel.frame = CGRectMake(42, 28, screenWidth - 85, 16);
        self.subtitleLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (duration > 0) {
            self.autoCollapseTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(collapseIsland) userInfo:nil repeats:NO];
        }
    }];
}

- (void)collapseIsland {
    self.isExpanded = NO;
    [self.autoCollapseTimer invalidate];

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;

    [UIView animateWithDuration:0.40
                          delay:0
         usingSpringWithDamping:0.80
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.frame = CGRectMake(0, 0, 115, 22);
        self.center = CGPointMake(screenWidth / 2.0, 11);
        self.layer.cornerRadius = 11;

        self.appIconImageView.frame = CGRectMake(4, 3, 16, 16);
        self.titleLabel.frame = CGRectMake(24, 3, 85, 16);
        self.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
        self.titleLabel.alpha = 0.0;
        self.subtitleLabel.alpha = 0.0;
    } completion:nil];
}

- (void)updateLayoutForOrientation:(UIInterfaceOrientation)orientation {
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 0.0;
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 1.0;
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            self.center = CGPointMake(screenWidth / 2.0, 11);
        }];
    }
}

@end

static DynamicIslandWindow *islandWindow = nil;

// ==========================================
// --- HOOK HỆ THỐNG TỰ ĐỘNG BẮT SỰ KIỆN ---
// ==========================================

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIScreen *mainScreen = [UIScreen mainScreen];
        islandWindow = [[DynamicIslandWindow alloc] initWithFrame:mainScreen.bounds];
        islandWindow.windowLevel = UIWindowLevelStatusBar + 999;
        islandWindow.backgroundColor = [UIColor clearColor];
        islandWindow.hidden = NO;

        DynamicIslandView *island = [DynamicIslandView sharedInstance];
        island.center = CGPointMake(mainScreen.bounds.size.width / 2.0, 11);
        [islandWindow addSubview:island];

        // Lắng nghe trạng thái PIN / CẮM SẠC
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            int level = (int)([UIDevice currentDevice].batteryLevel * 100);
            UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
            if (state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull) {
                NSString *batteryText = [NSString stringWithFormat:@"Đang sạc %d%%", level];
                [[DynamicIslandView sharedInstance] triggerEventWithTitle:@"Đã kết nối nguồn điện" subtitle:batteryText systemImage:@"bolt.fill" customImage:nil duration:3.0];
            }
        }];
    });
}

// Bắt xoay màn hình khi chơi game
- (void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)orientation duration:(double)duration logClassName:(id)arg3 {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DynamicIslandView sharedInstance] updateLayoutForOrientation:orientation];
    });
}

%end

// 1. Hook CUỘC GỌI TỚI (CallKit / Telephony)
%hook TUCall
- (void)setCallStatus:(int)status {
    %orig;
    if (status == 1) { // Inbound Call
        NSString *callerName = [self performSelector:@selector(displayName)] ?: @"Cuộc gọi đến";
        [[DynamicIslandView sharedInstance] triggerEventWithTitle:@"Cuộc gọi thoại" subtitle:callerName systemImage:@"phone.fill" customImage:nil duration:5.0];
    }
}
%end

// 2. Hook XÁC THỰC TOUCH ID / FACE ID
%hook BiometricKit
- (void)statusMessage:(unsigned int)message {
    %orig;
    if (message == 1) { // Success
        [[DynamicIslandView sharedInstance] triggerEventWithTitle:@"Đã xác thực" subtitle:@"Face ID / Touch ID thành công" systemImage:@"checkmark.circle.fill" customImage:nil duration:2.0];
    }
}
%end

// 3. Hook SIRI ACTIVATION
%hook SiriUICommandViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [[DynamicIslandView sharedInstance] triggerEventWithTitle:@"Siri" subtitle:@"Đang lắng nghe..." systemImage:@"mic.fill" customImage:nil duration:3.0];
}
%end

// 4. Hook ĐỒNG HỒ ĐẾM GIỜ (Timer/Stopwatch)
%hook MTTimer
- (void)setState:(unsigned long long)state {
    %orig;
    if (state == 2) { // Running
        [[DynamicIslandView sharedInstance] triggerEventWithTitle:@"Đồng hồ đếm giờ" subtitle:@"Đang đếm ngược..." systemImage:@"timer" customImage:nil duration:3.0];
    }
}
%end
