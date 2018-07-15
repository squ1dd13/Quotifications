#include "SQDRootListController.h"
#import <QuartzCore/QuartzCore.h>
#include <spawn.h>
#import <AudioToolbox/AudioToolbox.h>

#define kWidth [[UIApplication sharedApplication] keyWindow].frame.size.width

@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(id)arg1;

@optional
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1;
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 inTableView:(id)arg2;
@end

@interface SQDPrefBannerView : UITableViewCell <PreferencesTableCustomView> {
    UILabel *label;
}

@end
//banner
@implementation SQDPrefBannerView

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    if (self) {

        CGRect labelFrame = CGRectMake(0, -15, kWidth, 120);



        label = [[UILabel alloc] initWithFrame:labelFrame];

        [label.layer setMasksToBounds:YES];
        [label setNumberOfLines:1];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:40];

        label.textColor = [UIColor colorWithRed:90/255.0 green:151/255.0 blue:188/255.0 alpha:1.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"“Quotifications”";
        label.alpha = 0.0;
        [self addSubview:label];

        //fade in
        [UIView animateWithDuration:1.3 animations:^() {
            label.alpha = 1.0;
        }];

    }
    return self;
}
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    CGFloat prefHeight = 100.0;
    return prefHeight;
}
@end

@implementation SQDRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

-(void)viewDidLoad {
    [super viewDidLoad];

	[self.view setBackgroundColor:[UIColor whiteColor]];

    //add respring button to nav bar
    UIBarButtonItem *respringButton = [[UIBarButtonItem alloc]  initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respring)];
    respringButton.tintColor=[UIColor colorWithRed:90/255.0 green:151/255.0 blue:188/255.0 alpha:1.0];

    [self.navigationItem setRightBarButtonItem:respringButton];

    self.navigationController.navigationController.navigationBar.tintColor = [UIColor colorWithRed:90/255.0 green:151/255.0 blue:188/255.0 alpha:1.0];

    [UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = [UIColor colorWithRed:90/255.0 green:151/255.0 blue:188/255.0 alpha:1.0];
}


- (void)graduallyAdjustBrightnessToValue:(CGFloat)endValue
{
    CGFloat startValue = [[UIScreen mainScreen] brightness];

    CGFloat fadeInterval = 0.01;
    double delayInSeconds = 0.005;
    if (endValue < startValue)
        fadeInterval = -fadeInterval;

    CGFloat brightness = startValue;
    while (fabs(brightness-endValue)>0) {

        brightness += fadeInterval;

        if (fabs(brightness-endValue) < fabs(fadeInterval))
            brightness = endValue;

        dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[UIScreen mainScreen] setBrightness:brightness];
        });
    }
    UIView *finalDarkScreen = [[UIView alloc] initWithFrame:[[UIApplication sharedApplication] keyWindow].bounds];
    finalDarkScreen.backgroundColor = [UIColor blackColor];
    finalDarkScreen.alpha = 0.3;

    //add it to the main window, but with no alpha
    [[[UIApplication sharedApplication] keyWindow] addSubview:finalDarkScreen];

    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         finalDarkScreen.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             //DIE
					    AudioServicesPlaySystemSound(1521);
					    sleep(1);
                             pid_t pid;
                             const char* args[] = {"killall", "-9", "backboardd", NULL};
                             posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
                         }
                     }];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

//beautiful and gentle respring effect
- (void)respring {
    //make a visual effect view to fade in for the blur
    [self.view endEditing:YES]; //save changes to text fields and dismiss keyboard

    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];

    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

    visualEffectView.frame = [[UIApplication sharedApplication] keyWindow].bounds;
    visualEffectView.alpha = 0.0;

    //add it to the main window, but with no alpha
    [[[UIApplication sharedApplication] keyWindow] addSubview:visualEffectView];

    //animate in the alpha
    [UIView animateWithDuration:3.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         visualEffectView.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             //call the animation here for the screen fade and respring
                             [self graduallyAdjustBrightnessToValue:0.0f];
                         }
                     }];

    //sleep(15);

    //[[UIScreen mainScreen] setBrightness:0.0f]; //so the screen fades back in when the respringing is done
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    // un-tint navbar
    self.navigationController.navigationController.navigationBar.tintColor = nil;

    // un-tint dark navbar return to white
    self.navigationController.navigationController.navigationBar.barTintColor = nil;


    //set status bar back to default
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

    [super viewWillDisappear:NO];
}

@end
