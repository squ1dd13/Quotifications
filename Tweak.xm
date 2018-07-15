#include <stdlib.h>
#import <dlfcn.h>
#import <stdio.h>
#import <sys/stat.h>
#import <sys/types.h>
#import "SQKit.h"
#include <string.h>
#include <errno.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "funcs.h"

#pragma mark Interfaces
@interface SBUILegibilityLabel : UIView
@property (nonatomic, copy, readwrite) NSString *string;
@property (nonatomic, strong, readwrite) UIFont *font;
@property (nonatomic, copy, readwrite) UIColor *textColor;
@end

@interface NCNotificationListSectionRevealHintView : UIView
@property (nonatomic, assign, readwrite) SBUILegibilityLabel *revealHintTitle;
@property (nonatomic, assign) BOOL invisible;
-(BOOL)connectedToInternet;
-(NSString *)quote;
-(void)_updateHintTitle;
-(void)animateBackIn;
-(BOOL)muted;
-(void)shake;
-(void)addShineAnimation;
-(void)removeShineAnimation;
@end

@interface SBSUIWallpaperPreviewViewController : UIViewController
@end

@interface SBFStaticWallpaperView : UIView
-(void)setContentView:(id)arg1;
-(UIColor *)_computeAverageColor;
@end
#pragma mark End Interfaces



#pragma mark Prefs helpers
#define PLIST_PATH @"/var/mobile/Library/Preferences/com.squ1dd13.ncquote.plist"
#define prefsDict [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH]


#pragma mark Pref loading
static BOOL allowFunny = GetPrefBool(@"allowMovie");
static BOOL useWallpaperColor = GetPrefBool(@"useWallCol");
static BOOL addShadow = GetPrefBool(@"addShadow");
static BOOL brightenDarkCols = GetPrefBool(@"brightenDarkCols");
static BOOL doubleTapNew = GetPrefBool(@"doubleTapNew");
static BOOL longPressSpeak = GetPrefBool(@"longPressSpeak");
#pragma mark End pref loading



#pragma mark Hooks
%hook SBFStaticWallpaperView

//hackiest method known to any developer ever
-(void)setContentView:(id)arg1 {
	if(useWallpaperColor) {
		CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
		[[self _computeAverageColor] getRed:&red green:&green blue:&blue alpha:&alpha];
		//so we can save the colour more easily
		NSString *colorString = [NSString stringWithFormat:@"%f|%f|%f|%f", red, green, blue, alpha];
		writeToFile(@"/var/mobile/.hscolor.rgb", colorString);
	}
	%orig;
}
%end

//now for something completely different
%hook NCNotificationListSectionRevealHintView
%property (nonatomic, assign) BOOL invisible;
//we can't have safemode if there is no internet, UNNNAAACCCCEEEEPPPPPTTTTAAAABBBBLLLLEEEE
//yeah what he said
%new
- (BOOL)connectedToInternet {
	NSString *urlString = @"https://www.google.com/";
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"HEAD"];
	NSHTTPURLResponse *response;

	[NSURLConnection sendSynchronousRequest:request returningResponse:&response error: NULL];

	return ([response statusCode] == 200) ? YES : NO;
}

%new
-(BOOL)muted {
	CFStringRef state;
	UInt32 propertySize = sizeof(CFStringRef);
	AudioSessionInitialize(NULL, NULL, NULL, NULL);
	AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
	return (CFStringGetLength(state) > 0) ? NO : YES;
}

//this method actually gets the quotes
%new
-(NSString *)quote {
	//any quote you get is completely random
	NSString *chosenQuote = @"";
	NSError *error;
	NSString *recentlyUsedPath = @"/var/mobile/.recentlyused.txt";
	NSString *separatorString = @"\n@@@@@@@@@@@@@@@@@@\n";

	if(GetPrefBool(@"useCustom")) {
		chosenQuote = [NSString stringWithFormat:@"“%@” - %@", prefsString(@"customBody"), prefsString(@"customAuthor")];
		goto custom; //skip to the end, don't waste time and memory on getting web stuff
		//more efficient than checking in the if statements and doing an else if
	}

	if([self connectedToInternet]) {
		//lovely little algorythm
		if(allowFunny) {
			//randommmmmmmmmmmmmmmmmmmmm
			//gotta get a variety
			int r = arc4random_uniform(3);
			if(r == 0) {
				chosenQuote = quoteFromSourceTwo();
			} else if(r == 1){
				chosenQuote = quoteFromSourceOne();
			} else {
				chosenQuote = quoteFromSourceThree();
			}

			//we could use a while loop and get from the same source but we need this to be quick
			//if it is too long, switch to the other source
			if([chosenQuote length] > 180) {
				//if it is too long twice, for the sake of speed, it continues
				chosenQuote = quoteFromSourceOne(); //source one is always shorter
			}
			NSLog(@"%llu", [chosenQuote length]);
			//the R. S bug is gone thanks to removing the cache on requests
		} else {
			int r = arc4random_uniform(2);
			if(r == 0) {
				chosenQuote = quoteFromSourceTwo();
			} else {
				chosenQuote = quoteFromSourceThree();
			}
		}
		NSLog(@"%@", chosenQuote);


		BOOL hasUsedQuoteRecently = NO;

		if(file_exist([recentlyUsedPath UTF8String])) {
			NSArray<NSString *> *usedQuotes = [[NSString stringWithContentsOfFile:recentlyUsedPath] componentsSeparatedByString:separatorString];
			for(NSString *quoteText in usedQuotes) {
				if([quoteText isEqualToString:chosenQuote]) {
					hasUsedQuoteRecently = YES;
					chosenQuote = quoteFromSourceTwo();
				}

			}
			if([usedQuotes count] >= 5) {
				clearFile(recentlyUsedPath);
			}
		}


		NSString *chQToWrite = [chosenQuote stringByAppendingString:separatorString];
		[chQToWrite writeToFile:recentlyUsedPath atomically:!file_exist([recentlyUsedPath UTF8String]) encoding:NSUTF8StringEncoding error:&error];

	} else {

		if(GetPrefBool(@"saveQuotes")) {
			NSLog(@"Searching for saved quotes...");
			NSArray<NSString *> *usedQuotes = [[NSString stringWithContentsOfFile:recentlyUsedPath] componentsSeparatedByString:separatorString];
			if([usedQuotes count] != 0) {
				chosenQuote = usedQuotes[0];
			} else {
				//if usedQuotes[0] doesn't exist because the count is 0, default to this
				chosenQuote = [NSString stringWithFormat:@"Couldn't get last quote - %@", [[UIDevice currentDevice] name]];
			}


		} else {
			//something like No internet - Squid's iPhone
			chosenQuote = deviceNameQuote();
		}

	}

	if([chosenQuote length] > 180) {
		chosenQuote = quoteUnderLimit(180); //last resort, make sure it is within the limit by only returning when it is
	}

	if([chosenQuote isEqualToString:recentlyUsedPath]) {
		chosenQuote = quoteUnderLimit(180);
	}

	chosenQuote = removeStr(chosenQuote, @"  "); //final bit of cleaning up, replace random double spaces

	custom: //this is where the goto from earlier leads to

	if(useWallpaperColor) {
		//get the wallpaper colour from the hook
		NSString *homeScreenColor = [NSString stringWithContentsOfFile:@"/var/mobile/.hscolor.rgb"];
		NSArray *colorValues = [homeScreenColor componentsSeparatedByString:@"|"];

		CGFloat red = [colorValues[0] floatValue];
		CGFloat green = [colorValues[1] floatValue];
		CGFloat blue = [colorValues[2] floatValue];
		CGFloat alpha = [colorValues[3] floatValue];
		UIColor *calculatedColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
		if(isDark(calculatedColor) && brightenDarkCols) {
			NSLog(@"Colour is dark, will brighten.");
			calculatedColor = lighterColor(calculatedColor);
			if(addShadow) {
				self.revealHintTitle.layer.shadowOffset = CGSizeMake(0, 0);
				self.revealHintTitle.layer.shadowOpacity = 1.0;
			}
		}
		self.revealHintTitle.textColor = calculatedColor;
	}
	return chosenQuote;
}

//this is only called once
- (void)_updateHintTitle {
	%orig;
	//all the quote picking work has moved to [self quote] for organization and the ability to call
	self.revealHintTitle.string = [self quote];
	if(self.invisible) {
		[self animateBackIn];
	}
}



%new
-(void)speakFromGesture:(UILongPressGestureRecognizer *)gesture {
	if(gesture.state == UIGestureRecognizerStateBegan) {
		BOOL isZeroVolume = [[AVAudioSession sharedInstance] outputVolume] == 0.0;
		if(!([self muted] || isZeroVolume)) {
			[self addShineAnimation];
			NSLog(@"Speaking quote. Take it away, Siri!"); //i've said it before and i'll say it again: fun is good
			AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:self.revealHintTitle.string];
			AVSpeechSynthesizer *syn = [[AVSpeechSynthesizer alloc] init];

			[syn speakUtterance:utterance];
		} else {
			[self shake];
		}
		[self removeShineAnimation];
	}
}

%new
-(void)newQuote:(UITapGestureRecognizer *)gesture {
	//this method indirectly calls animateBackIn through _updateHintTitle, but calling it here would show before the quote
	if(gesture.state == UIGestureRecognizerStateRecognized) {
		[UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
			self.revealHintTitle.alpha = 0.0;
		} completion:^(BOOL finished) {
			self.invisible = YES;
			[self _updateHintTitle];
		}];
	}
}

%new
-(void)animateBackIn {
	[UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
		self.revealHintTitle.alpha = 1.0;
	} completion:^(BOOL finished) {
		self.invisible = NO;
	}];
}

%new
-(void)shake {
	CABasicAnimation *shakeanimation = [CABasicAnimation animationWithKeyPath:@"position"];
	[shakeanimation setDuration:0.05];
	[shakeanimation setRepeatCount:4];
	[shakeanimation setAutoreverses:YES];
	[shakeanimation setFromValue:[NSValue valueWithCGPoint:CGPointMake(self.revealHintTitle.center.x - 10, self.revealHintTitle.center.y)]];
	[shakeanimation setToValue:[NSValue valueWithCGPoint:CGPointMake(self.revealHintTitle.center.x + 10, self.revealHintTitle.center.y)]];
	[[self.revealHintTitle layer] addAnimation:shakeanimation forKey:@"position"];
}

-(void)setFrame:(CGRect)frame {
	//add 10px padding so the text doesn't hit the edges of the screen
	frame.size.width = frame.size.width - 15;
	frame.origin.y = frame.origin.y - 50;
	NSLog(@"Width: %f", frame.size.width);
	%orig(frame);

	//we couldn't possibly stop there, we need a little bit of speech
	if(longPressSpeak) {
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(speakFromGesture:)];
		longPress.minimumPressDuration = 2.0;
		[self addGestureRecognizer:longPress];
	}

	//and the ability to get a new quote on double tap
	if(doubleTapNew) {
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(newQuote:)];
		tapGesture.numberOfTapsRequired = 2;
		[self addGestureRecognizer:tapGesture];
	}
}

%new
- (void)addShineAnimation {
	CAGradientLayer *gradient = [CAGradientLayer layer];
	[gradient setStartPoint:CGPointMake(0, 0)];
	[gradient setEndPoint:CGPointMake(1, 0)];
	gradient.frame = CGRectMake(0, 0, self.revealHintTitle.bounds.size.width*3, self.revealHintTitle.bounds.size.height);
	float lowerAlpha = 0.78;
	gradient.colors = [NSArray arrayWithObjects:
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:1.0] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:1.0] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:1.0] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   nil];
	gradient.locations = [NSArray arrayWithObjects:
						  [NSNumber numberWithFloat:0.0],
						  [NSNumber numberWithFloat:0.4],
						  [NSNumber numberWithFloat:0.45],
						  [NSNumber numberWithFloat:0.5],
						  [NSNumber numberWithFloat:0.55],
						  [NSNumber numberWithFloat:0.6],
						  [NSNumber numberWithFloat:1.0],
						  nil];

	CABasicAnimation *theAnimation;
	theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
	theAnimation.duration = 2;
	theAnimation.repeatCount = INFINITY;
	theAnimation.autoreverses = NO;
	theAnimation.removedOnCompletion = NO;
	theAnimation.fillMode = kCAFillModeForwards;
	theAnimation.fromValue=[NSNumber numberWithFloat:-self.revealHintTitle.frame.size.width*2];
	theAnimation.toValue=[NSNumber numberWithFloat:0];
	[gradient addAnimation:theAnimation forKey:@"animateLayer"];

	self.revealHintTitle.layer.mask = gradient;
}
%new
- (void)removeShineAnimation {
	self.revealHintTitle.layer.mask = nil;
}

%end
