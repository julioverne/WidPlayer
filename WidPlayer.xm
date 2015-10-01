#include <mach-o/dyld.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <notify.h>
#import <substrate.h>
#import <libactivator/libactivator.h>
#import "MediaRemote.h"
#include <Celestial/AVSystemController.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPVolumeSlider.h>


#import "CBAutoScrollLabel.h"
#import "UIWindow.h"

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.widplayer.plist"

static BOOL WidPlayerEnabled;
static BOOL WidPlayerHideNoPlaying;
static BOOL WidPlayerHideLockScreen;
static int Blur;
static int WidgetWidth;
static int WidgetRadius;
static int ArtworkRadius;

@interface SBMediaController : NSObject
+(id)sharedInstance;
- (void)setVolume:(float)fp8;
- (float)volume;
- (BOOL)muted;
- (BOOL)stop;
- (BOOL)togglePlayPause;
- (BOOL)pause;
- (BOOL)play;
@end

@interface SBUIController : NSObject
+ (id)sharedInstance;
- (void)activateApplicationAnimated:(id)animated;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)applicationWithPid:(int)pid;
@end


@interface WidPlayer : NSObject
{
	UIWindow* springboardWindow;
	UIBezierPath *shadowPath;
	UIViewController* controller;
	UIView* blurView;
	UIImageView *artworkViewBlur;
	UIVisualEffectView *effectView;
	
	MPVolumeView *volumeView;
	
	UIImageView *artworkView;
	UIImage* kNoArtwork;
	CBAutoScrollLabel *artistLabel;
	CBAutoScrollLabel *titleLabel;
	UIProgressView *progressBar;

	UIButton *playPauseButton;
    UIButton *nextTrackButton;
    UIButton *prevTrackButton;
	UIButton *SoundButton;
    UISlider *trackProgress;
	
	NSTimer *progressUpdateTimer;
	NSTimeInterval duration;
	NSTimeInterval nowSec;
	NSTimeInterval timeIntervalifPause;
	
	BOOL isPlaying;
	CFAbsoluteTime MusicStarted;
}
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) CFAbsoluteTime MusicStarted;
@property (nonatomic, strong) UIWindow* springboardWindow;
@property (nonatomic, strong) UIBezierPath *shadowPath;
@property (nonatomic, strong) UIViewController* controller;
@property (nonatomic, strong) UIView* blurView;
@property (nonatomic, strong) UIVisualEffectView *effectView;
@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UIImageView *artworkView;
@property (nonatomic, strong) CBAutoScrollLabel *artistLabel;
@property (nonatomic, strong) CBAutoScrollLabel *titleLabel;
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *nextTrackButton;
@property (nonatomic, strong) UIButton *prevTrackButton;
@property (nonatomic, strong) UIButton *SoundButton;
@property (nonatomic, strong) UISlider *trackProgress;
//@property (nonatomic, strong) NSArray *playlists;
@property (nonatomic, strong) NSTimer *progressUpdateTimer;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval nowSec;
@property (nonatomic, assign) NSTimeInterval timeIntervalifPause;
@property (nonatomic, strong) UIImage* kNoArtwork;

+ (id)sharedInstance;
- (void)firstload;

@end

@interface UIImage (PlayerImage)
- (UIImage *)imageWithSize:(CGSize)size;
@end

%group WidPlayerHooks
@implementation UIImage (PlayerImage)
- (UIImage *)imageWithSize:(CGSize)size
{
	@autoreleasepool {
		if (NULL != UIGraphicsBeginImageContextWithOptions) {
			UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
		} else {
			UIGraphicsBeginImageContext(size);
		}
		UIImage *sel = (UIImage *)self;
		[sel drawInRect:CGRectMake(0, 0, size.width, size.height)];
		UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		return newImage;
	}
}
@end

@implementation WidPlayer
@synthesize springboardWindow, controller, blurView, effectView, shadowPath;
@synthesize artworkView, artistLabel, titleLabel, nextTrackButton, prevTrackButton, trackProgress, playPauseButton, progressBar, progressUpdateTimer, duration, nowSec, timeIntervalifPause, SoundButton, volumeView;
@synthesize kNoArtwork, isPlaying, MusicStarted;
__strong static id _sharedObject;
+ (id)sharedInstance
{
	if (!_sharedObject) {
		_sharedObject = [[self alloc] init];
	}
	return _sharedObject;
}
+ (BOOL)sharedInstanceExist
{
	if (_sharedObject) {
		return YES;
	}
	return NO;
}
- (void)firstload
{
	return;
}
- (UIWindow*)widgetWindow
{
	return springboardWindow;
}
-(id)init
{
	self = [super init];
	if(self != nil) {
		springboardWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0-(WidgetWidth-(WidgetWidth/15)), 60, WidgetWidth, WidgetWidth/2.5)];
		springboardWindow.alpha = 0.3;
		springboardWindow.windowLevel = 999999;
		[springboardWindow setHidden:NO];
		[springboardWindow enableDragging];
		[springboardWindow.layer setCornerRadius:WidgetRadius];
		shadowPath = [UIBezierPath bezierPathWithRoundedRect:springboardWindow.bounds cornerRadius:WidgetRadius];
		springboardWindow.layer.masksToBounds = NO;
		springboardWindow.layer.shadowColor = [UIColor blackColor].CGColor;
		springboardWindow.layer.shadowOffset = CGSizeMake(3.0f, 3.0f);
		springboardWindow.layer.shadowOpacity = 0.4f;
		springboardWindow.layer.shadowPath = shadowPath.CGPath;
		
		controller = [UIViewController new];
		controller.view.frame = CGRectMake(0, 0, springboardWindow.frame.size.width, springboardWindow.frame.size.height);
		controller.view.layer.masksToBounds = YES;
		controller.view.layer.cornerRadius = springboardWindow.layer.cornerRadius;
		
		blurView = [UIView new];
		blurView.frame = controller.view.frame;
		[controller.view addSubview:blurView];
		
		artworkViewBlur = [UIImageView new];
		artworkViewBlur.frame = blurView.frame;
		
		UIView *add = (UIView *)springboardWindow;
		[add addSubview:controller.view];
		[springboardWindow makeKeyAndVisible];
		

		
		UIBlurEffect *blur = [UIBlurEffect effectWithStyle:(UIBlurEffectStyle)Blur];
		effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
		effectView.alpha = 1.0f;
		effectView.frame = controller.view.frame;
		[blurView addSubview:effectView];
		

		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
		tapGesture.numberOfTapsRequired = 2;
		[blurView addGestureRecognizer:tapGesture];
		
		


		
	artworkView = [UIImageView new];
	artworkView.frame = CGRectMake((springboardWindow.frame.size.width/36), (springboardWindow.frame.size.width/36), springboardWindow.frame.size.height-(springboardWindow.frame.size.width/19), springboardWindow.frame.size.height-(springboardWindow.frame.size.width/19));
	artworkView.layer.cornerRadius = ArtworkRadius;
	artworkView.layer.masksToBounds = YES;
	[artworkView setUserInteractionEnabled:YES];
	UITapGestureRecognizer *tapOpenGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlayingApplication:)];
	tapOpenGesture.numberOfTapsRequired = 1;
	[artworkView addGestureRecognizer:tapOpenGesture];
	[controller.view addSubview:artworkView];

	titleLabel = [[CBAutoScrollLabel alloc] initWithFrame:CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19), (springboardWindow.frame.size.height/(springboardWindow.frame.size.height/3)), springboardWindow.frame.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), springboardWindow.frame.size.height/6)];
	titleLabel.textColor = Blur<=1?[UIColor blackColor]:[UIColor lightGrayColor];
	titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:springboardWindow.frame.size.height/6];
	titleLabel.labelSpacing = 30; // distance between start and end labels
	titleLabel.pauseInterval = 0; // seconds of pause before scrolling starts again
	titleLabel.scrollSpeed = 30; // pixels per second
	titleLabel.textAlignment = NSTextAlignmentCenter; // centers text when no auto-scrolling is applied
	titleLabel.fadeLength = 20.f;
	titleLabel.scrollDirection = CBAutoScrollDirectionLeft;
	[titleLabel observeApplicationNotifications];
	[controller.view addSubview:titleLabel];

	artistLabel = [[CBAutoScrollLabel alloc] initWithFrame:CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19), titleLabel.frame.origin.y+titleLabel.frame.size.height, springboardWindow.frame.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), springboardWindow.frame.size.height/6)];
	artistLabel.textColor = Blur<=1?[UIColor blackColor]:[UIColor lightGrayColor];
	artistLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:springboardWindow.frame.size.height/6];
	artistLabel.labelSpacing = 30; // distance between start and end labels
	artistLabel.pauseInterval = 0; // seconds of pause before scrolling starts again
	artistLabel.scrollSpeed = 30; // pixels per second
	artistLabel.textAlignment = NSTextAlignmentCenter; // centers text when no auto-scrolling is applied
	artistLabel.fadeLength = 20.f;
	artistLabel.scrollDirection = CBAutoScrollDirectionLeft;
	[artistLabel observeApplicationNotifications];
	[controller.view addSubview:artistLabel];

	trackProgress = [[UISlider alloc] initWithFrame:CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19), artistLabel.frame.origin.y+artistLabel.frame.size.height, springboardWindow.frame.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), springboardWindow.frame.size.height/7)];
	[trackProgress setThumbImage:[[UIImage alloc] init] forState:UIControlStateNormal];
	[trackProgress setMinimumTrackImage:nil forState:UIControlStateNormal];
	[trackProgress setMaximumTrackImage:nil forState:UIControlStateNormal];
	trackProgress.userInteractionEnabled = NO;
	[controller.view addSubview:trackProgress];
	
	SoundButton = [[UIButton alloc] initWithFrame:CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19), trackProgress.frame.origin.y+trackProgress.frame.size.height, springboardWindow.frame.size.height/7, springboardWindow.frame.size.height/7)];
	[self statusSoundButton];
	[SoundButton addTarget:self action:@selector(SoundButton:) forControlEvents:UIControlEventTouchUpInside];
	[controller.view addSubview:SoundButton];
	
	volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake((artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+SoundButton.frame.size.width), trackProgress.frame.origin.y+trackProgress.frame.size.height, springboardWindow.frame.size.width-(SoundButton.frame.origin.x+SoundButton.frame.size.width+(springboardWindow.frame.size.width/35)), springboardWindow.frame.size.height/7)];
	//[volumeView sizeToFit];
	MPVolumeSlider* volumeSlider = MSHookIvar<MPVolumeSlider*>(volumeView, "_volumeSlider");
	[volumeSlider setThumbImage:[[UIImage alloc] init] forState:UIControlStateNormal];
	[volumeSlider setTintColor:[UIColor colorWithRed:0.37 green:0.33 blue:0.32 alpha:1.0]];
	volumeSlider.userInteractionEnabled = NO;
	[controller.view addSubview:volumeView];

	int rest = (springboardWindow.frame.size.width - (((springboardWindow.frame.size.height/3)+(springboardWindow.frame.size.width/36))*5.5) )/2;

	prevTrackButton = [[UIButton alloc] initWithFrame:CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19)+rest, volumeView.frame.origin.y+volumeView.frame.size.height, springboardWindow.frame.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), springboardWindow.frame.size.height/6)];
	[prevTrackButton setImage:[[[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"prev" ofType:@"png"]] imageWithSize:CGSizeMake((springboardWindow.frame.size.height/3), (springboardWindow.frame.size.height/3))] forState:UIControlStateNormal];
	[prevTrackButton sizeToFit];
	[prevTrackButton addTarget:self action:@selector(prevTrack:) forControlEvents:UIControlEventTouchUpInside];
	UILongPressGestureRecognizer *prevlongPress= [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(prevlongPressForward:)];
	[prevTrackButton addGestureRecognizer:prevlongPress];
	[controller.view addSubview:prevTrackButton];
	
	playPauseButton = [[UIButton alloc] initWithFrame:CGRectMake(prevTrackButton.frame.origin.x+prevTrackButton.frame.size.width+(springboardWindow.frame.size.width/36), volumeView.frame.origin.y+volumeView.frame.size.height, springboardWindow.frame.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), springboardWindow.frame.size.height/6)];
	[playPauseButton setImage:[[[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"play" ofType:@"png"]] imageWithSize:CGSizeMake((springboardWindow.frame.size.height/3), (springboardWindow.frame.size.height/3))] forState:UIControlStateNormal];
	[playPauseButton sizeToFit];
	[playPauseButton addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchUpInside];
	[controller.view addSubview:playPauseButton];
	
	nextTrackButton = [[UIButton alloc] initWithFrame:CGRectMake(playPauseButton.frame.origin.x+playPauseButton.frame.size.width+(springboardWindow.frame.size.width/36), volumeView.frame.origin.y+volumeView.frame.size.height, springboardWindow.frame.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), springboardWindow.frame.size.height/6)];
	[nextTrackButton setImage:[[[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"next" ofType:@"png"]] imageWithSize:CGSizeMake((springboardWindow.frame.size.height/3), (springboardWindow.frame.size.height/3))] forState:UIControlStateNormal];
	[nextTrackButton sizeToFit];
	[nextTrackButton addTarget:self action:@selector(nextTrack:) forControlEvents:UIControlEventTouchUpInside];
	UILongPressGestureRecognizer *nextlongPress= [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(nextlongPressForward:)];
	[nextTrackButton addGestureRecognizer:nextlongPress];
	[controller.view addSubview:nextTrackButton];
	

	[self registerForMusicPlayerNotifications];
	[self performSelectorInBackground:@selector(updateNowPlaying) withObject:nil];
	[self UpdateBlur];
	}
	return self;
}
- (void)UpdateFrame
{
	[UIView animateWithDuration:0.3/2 animations:^{
	springboardWindow.alpha = 1.0;
	springboardWindow.frame = CGRectMake(20, 60, WidgetWidth, WidgetWidth/2.5);
	CGRect WidSize = CGRectMake(0, 0, springboardWindow.frame.size.width, springboardWindow.frame.size.height);
	controller.view.frame = WidSize;
	blurView.frame = WidSize;
	artworkViewBlur.frame = WidSize;
	effectView.frame = WidSize;
	shadowPath = [UIBezierPath bezierPathWithRoundedRect:springboardWindow.bounds cornerRadius:WidgetRadius];
	springboardWindow.layer.shadowPath = shadowPath.CGPath;
	artworkView.frame = CGRectMake((springboardWindow.frame.size.width/36), (springboardWindow.frame.size.width/36), WidSize.size.height-(springboardWindow.frame.size.width/19), WidSize.size.height-(springboardWindow.frame.size.width/19));
	titleLabel.frame = CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19), (WidSize.size.height/(WidSize.size.height/3)), WidSize.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), WidSize.size.height/6);
	[titleLabel sizeToFit];
	titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:WidSize.size.height/6];
	artistLabel.frame = CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19), titleLabel.frame.origin.y+titleLabel.frame.size.height, WidSize.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), WidSize.size.height/6);
	[artistLabel sizeToFit];
	artistLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:WidSize.size.height/6];
	trackProgress.frame = CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19), artistLabel.frame.origin.y+artistLabel.frame.size.height, WidSize.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), WidSize.size.height/7);
	SoundButton.frame = CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19), trackProgress.frame.origin.y+trackProgress.frame.size.height, WidSize.size.height/7, WidSize.size.height/7);
	[SoundButton sizeToFit];
	
	volumeView.frame = CGRectMake((artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+SoundButton.frame.size.width), trackProgress.frame.origin.y+trackProgress.frame.size.height, WidSize.size.width-(SoundButton.frame.origin.x+SoundButton.frame.size.width+(WidSize.size.width/35)), WidSize.size.height/7);
	//[volumeView sizeToFit];
	//volumeView.frame = CGRectMake(SoundButton.frame.origin.x+SoundButton.frame.size.width, trackProgress.frame.origin.y+trackProgress.frame.size.height, WidSize.size.width-(SoundButton.frame.origin.x+SoundButton.frame.size.width+(springboardWindow.frame.size.width/19)), WidSize.size.height/7);
	
	
	int rest = (WidSize.size.width - (((WidSize.size.height/3)+(springboardWindow.frame.size.width/36))*5.5) )/2;
	CGSize imageBtSize = CGSizeMake((WidSize.size.height/3), (WidSize.size.height/3));
	prevTrackButton.frame = CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/19)+rest, volumeView.frame.origin.y+volumeView.frame.size.height, WidSize.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), WidSize.size.height/6);
	static __strong UIImage* kPrevBTImg = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"prev" ofType:@"png"]];
	[prevTrackButton setImage:[kPrevBTImg imageWithSize:imageBtSize] forState:UIControlStateNormal];
	[prevTrackButton sizeToFit];
	playPauseButton.frame = CGRectMake(prevTrackButton.frame.origin.x+prevTrackButton.frame.size.width+(springboardWindow.frame.size.width/36), volumeView.frame.origin.y+volumeView.frame.size.height, WidSize.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), WidSize.size.height/6);
	static __strong UIImage* kPlayBTImg = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"play" ofType:@"png"]];
	static __strong UIImage* kPauseBTImg = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"pause" ofType:@"png"]];
	[playPauseButton setImage:isPlaying?[kPauseBTImg imageWithSize:imageBtSize]:[kPlayBTImg imageWithSize:imageBtSize] forState:UIControlStateNormal];
	[playPauseButton sizeToFit];
	nextTrackButton.frame = CGRectMake(playPauseButton.frame.origin.x+playPauseButton.frame.size.width+(springboardWindow.frame.size.width/36), volumeView.frame.origin.y+volumeView.frame.size.height, WidSize.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/25)+(springboardWindow.frame.size.width/19)), WidSize.size.height/6);
	static __strong UIImage* kNextBTImg = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"next" ofType:@"png"]];
	[nextTrackButton setImage:[kNextBTImg imageWithSize:imageBtSize] forState:UIControlStateNormal];
	[nextTrackButton sizeToFit];
	} completion:nil];
}
- (void)UpdateRadius
{
	[springboardWindow.layer setCornerRadius:WidgetRadius];
	shadowPath = [UIBezierPath bezierPathWithRoundedRect:springboardWindow.bounds cornerRadius:WidgetRadius];
	springboardWindow.layer.shadowPath = shadowPath.CGPath;
	[controller.view.layer setCornerRadius:WidgetRadius];
	[artworkView.layer setCornerRadius:ArtworkRadius];
}
- (void)UpdateBlur
{
	[effectView removeFromSuperview];
	UIBlurEffect *blur = [UIBlurEffect effectWithStyle:Blur==4?UIBlurEffectStyleLight:(UIBlurEffectStyle)Blur];
	effectView = [UIVisualEffectView new];
	
	if (Blur == 4) {
		artworkViewBlur.image = artworkView.image;
		[effectView addSubview:artworkViewBlur];
	}
	
	effectView = [effectView initWithEffect:blur];
	effectView.alpha = 1.0;
	effectView.frame = blurView.frame;
	[blurView addSubview:effectView];
	
	artistLabel.textColor = Blur<=1||Blur==4?[UIColor blackColor]:[UIColor lightGrayColor];
	titleLabel.textColor  = Blur<=1||Blur==4?[UIColor blackColor]:[UIColor lightGrayColor];
}
- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
	if (sender.state == UIGestureRecognizerStateRecognized) {
		Blur++;
		if (Blur >= 5) {
			Blur = 0;
		}
		[self UpdateBlur];
		@autoreleasepool {
			NSMutableDictionary* WidPlayerPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary] mutableCopy];
			[WidPlayerPrefs setObject:@(Blur) forKey:@"Blur"];
			[WidPlayerPrefs writeToFile:@PLIST_PATH_Settings atomically:YES];
		}
	}
}
#pragma mark Actions
-(void) nextlongPressForward:(UILongPressGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		MRMediaRemoteSendCommand(kMRStartForwardSeek, nil);
	} 
	if (recognizer.state == UIGestureRecognizerStateEnded) {
		MRMediaRemoteSendCommand(kMREndForwardSeek, nil);
	}
}
-(void) prevlongPressForward:(UILongPressGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		MRMediaRemoteSendCommand(kMRStartBackwardSeek, nil);
	} 
	if (recognizer.state == UIGestureRecognizerStateEnded) {
		MRMediaRemoteSendCommand(kMREndBackwardSeek, nil);
	}
}
-(void)nextTrack:(id)__unused sender
{
	MRMediaRemoteSendCommand(kMRNextTrack, nil);
}
-(void)prevTrack:(id)__unused sender
{
	MRMediaRemoteSendCommand(kMRPreviousTrack, nil);
}
-(void)playPause:(id)__unused sender
{
	MRMediaRemoteSendCommand(kMRTogglePlayPause, nil);
}
-(void)SoundButton:(id)__unused sender
{
	[[AVSystemController sharedAVSystemController] toggleActiveCategoryMuted];
	[self statusSoundButton];
}
- (void)openPlayingApplication:(id)__unused sender
{
    MRMediaRemoteGetNowPlayingApplicationPID(dispatch_get_main_queue(), ^(int PID) {
        [[%c(SBUIController) sharedInstance] activateApplicationAnimated:[[%c(SBApplicationController) sharedInstance] applicationWithPid:PID]];
	});
}

- (void)registerForMusicPlayerNotifications
{
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(updateNowPlaying) name:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(updateNowPlayingStatus) name:(__bridge NSString *)kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification object:nil];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), lockScreenState, CFSTR("com.apple.springboard.lockstate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
void lockScreenState(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	if (!WidPlayerHideLockScreen){return;}
	int token;
	uint64_t state;
	notify_register_check("com.apple.springboard.lockstate", &token);
	notify_get_state(token, &state);
	notify_cancel(token);	
	[[[WidPlayer sharedInstance] widgetWindow] setHidden:(BOOL)state];
}
- (void)updateNowPlaying
{
	if (!kNoArtwork) {
		unsigned char MaskForBlurData[] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x01, 0x90, 0x00, 0x00, 0x01, 0x90, 0x04, 0x03, 0x00, 0x00, 0x00, 0x72, 0x91, 0x2B, 0xFF, 0x00, 0x00, 0x00, 0x18, 0x50, 0x4C, 0x54, 0x45, 0xFF, 0xFF, 0xFF, 0xEF, 0xEF, 0xEF, 0xF9, 0xF9, 0xF9, 0xF5, 0xF5, 0xF5, 0xFB, 0xFB, 0xFB, 0xFD, 0xFD, 0xFD, 0xF3, 0xF3, 0xF3, 0xF7, 0xF7, 0xF7, 0x95, 0x78, 0xF6, 0xDC, 0x00, 0x00, 0x04, 0x99, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0xEC, 0xDD, 0x41, 0x4F, 0xDB, 0x30, 0x18, 0xC6, 0xF1, 0x77, 0x59, 0xDC, 0x5E, 0xF7, 0xAE, 0x23, 0x5C, 0x29, 0x6C, 0xE3, 0xBA, 0x54, 0x1B, 0x5C, 0xCB, 0x50, 0xD7, 0x6B, 0x8A, 0x58, 0x7B, 0xC5, 0x42, 0x13, 0x57, 0x3A, 0x58, 0x3F, 0xFF, 0x6A, 0x18, 0x52, 0xC9, 0x90, 0x83, 0x1C, 0x08, 0xF6, 0xC3, 0xF3, 0xBF, 0x73, 0xF8, 0x91, 0xFA, 0x8D, 0x63, 0x44, 0x2A, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x9E, 0xAE, 0x9F, 0x95, 0x00, 0x64, 0xF6, 0x54, 0x8B, 0x1D, 0x49, 0x3D, 0x33, 0xB5, 0xBA, 0xAE, 0x90, 0xC4, 0x3B, 0x29, 0xF5, 0xB6, 0x33, 0x49, 0xB9, 0xAC, 0xD4, 0xBB, 0xDE, 0x4B, 0xBA, 0xE5, 0x2B, 0xBD, 0x2D, 0xED, 0xCF, 0x96, 0xD9, 0xD3, 0x7B, 0xA5, 0x3A, 0xB8, 0xA6, 0x5A, 0x6B, 0x2C, 0x29, 0x36, 0xB5, 0x5A, 0x2F, 0xC5, 0x01, 0x7C, 0xB2, 0x66, 0x00, 0x40, 0xF2, 0x03, 0x55, 0x00, 0x88, 0x59, 0xA9, 0x02, 0x40, 0xDC, 0xA8, 0x42, 0x80, 0x1C, 0x5B, 0x45, 0x80, 0x2C, 0xD6, 0x0C, 0x00, 0x88, 0xDB, 0x55, 0x01, 0x40, 0x4E, 0x57, 0xAA, 0x00, 0x10, 0x37, 0xAA, 0x00, 0x20, 0x66, 0xCF, 0x2A, 0x00, 0xE4, 0xE6, 0xC9, 0x09, 0x00, 0xE2, 0xD6, 0x38, 0x00, 0x24, 0x5B, 0x33, 0x00, 0x20, 0xEE, 0xC9, 0x09, 0x00, 0xE2, 0xB6, 0x23, 0x08, 0x90, 0xA9, 0x2A, 0x02, 0x64, 0x6A, 0x15, 0x01, 0xE2, 0x9E, 0x9C, 0x00, 0x20, 0xEE, 0xC9, 0x09, 0x00, 0xE2, 0xB6, 0x23, 0x00, 0x10, 0x37, 0xAA, 0x10, 0x20, 0xC7, 0x56, 0x11, 0x20, 0x8B, 0x35, 0x03, 0x00, 0xE2, 0x16, 0x07, 0x04, 0x64, 0xA9, 0x18, 0x90, 0xB9, 0x62, 0x40, 0x8C, 0x82, 0x40, 0xE6, 0x28, 0x10, 0x0B, 0x02, 0xC9, 0x14, 0x04, 0xF2, 0x06, 0x05, 0x32, 0x44, 0x81, 0x58, 0x14, 0x88, 0x82, 0x40, 0x0C, 0x0A, 0x24, 0x47, 0x81, 0x64, 0x84, 0x10, 0x72, 0x13, 0x21, 0x84, 0x10, 0xE2, 0x8F, 0x10, 0x42, 0x08, 0xF1, 0x47, 0x08, 0x21, 0xE0, 0x90, 0xC3, 0xDD, 0x15, 0x02, 0xE4, 0x62, 0x2C, 0x22, 0xF3, 0xE4, 0x21, 0xDB, 0x63, 0x71, 0x19, 0x9B, 0x36, 0x64, 0xF0, 0x49, 0xFE, 0xD5, 0x4B, 0x19, 0x52, 0x5C, 0x6F, 0xFC, 0x68, 0xC2, 0x90, 0x91, 0x6C, 0x96, 0x2C, 0x64, 0x54, 0xC9, 0xBD, 0x6C, 0x9A, 0x90, 0x8B, 0x89, 0xD4, 0x2A, 0x53, 0x84, 0x0C, 0x76, 0x44, 0x00, 0x20, 0x6E, 0x54, 0x01, 0x40, 0x8A, 0xEB, 0x4A, 0x00, 0x20, 0x85, 0x5B, 0xE3, 0x00, 0x90, 0x8B, 0x35, 0x03, 0x00, 0xE2, 0x46, 0x15, 0x00, 0xC4, 0xAD, 0x71, 0x00, 0x48, 0xF1, 0x47, 0x04, 0x00, 0xE2, 0x76, 0x55, 0x08, 0x90, 0x51, 0x25, 0x08, 0x10, 0x37, 0xAA, 0x00, 0x20, 0xE7, 0x63, 0x11, 0x00, 0x88, 0x1B, 0x55, 0x00, 0x10, 0x37, 0xAA, 0x00, 0x20, 0xC5, 0x57, 0x11, 0x04, 0xC8, 0xA8, 0x12, 0x04, 0x48, 0x31, 0x11, 0x41, 0x80, 0x14, 0x63, 0xC1, 0x80, 0xFC, 0x12, 0x0C, 0x48, 0x51, 0xA5, 0x0D, 0xE9, 0xDF, 0x41, 0xCE, 0x04, 0x04, 0x52, 0x81, 0x40, 0xB6, 0x25, 0x71, 0x48, 0xA6, 0xB7, 0x6D, 0xA1, 0x40, 0x2E, 0x51, 0x20, 0x63, 0x14, 0x88, 0x10, 0x12, 0x17, 0xA4, 0x20, 0x84, 0x10, 0x42, 0x08, 0x21, 0xC4, 0x1B, 0x21, 0xAF, 0xE4, 0x86, 0x48, 0x08, 0x21, 0xC2, 0xC5, 0xFE, 0x3A, 0xAE, 0x08, 0x21, 0x84, 0x10, 0x42, 0x08, 0x21, 0xFE, 0x08, 0x21, 0x84, 0x10, 0x7F, 0x84, 0x10, 0x42, 0x88, 0x3F, 0x42, 0x08, 0x21, 0xC4, 0x1F, 0x21, 0xAF, 0x05, 0x52, 0xA1, 0x40, 0x60, 0xAE, 0x48, 0x10, 0x24, 0xA6, 0x2F, 0x89, 0x20, 0x24, 0x56, 0x48, 0x45, 0x08, 0x21, 0x84, 0x10, 0x42, 0x88, 0x2F, 0x42, 0x08, 0x21, 0xC4, 0x1F, 0x21, 0x84, 0x10, 0xE2, 0x8F, 0x90, 0x06, 0xC8, 0x98, 0x10, 0x42, 0x08, 0x21, 0x84, 0x90, 0x80, 0x3A, 0x81, 0x98, 0xFD, 0x03, 0x5D, 0x77, 0x7E, 0x5D, 0x25, 0x0D, 0x31, 0x9F, 0x37, 0xDF, 0xF9, 0x92, 0x2E, 0x24, 0xB3, 0xBA, 0xD1, 0x60, 0x9C, 0x2A, 0x64, 0xF1, 0xDF, 0x3F, 0xF0, 0xA7, 0x09, 0x71, 0x8E, 0x5A, 0x97, 0x29, 0x42, 0x32, 0x7D, 0xA0, 0x9D, 0x04, 0x21, 0xA5, 0x3E, 0x50, 0x61, 0x93, 0x83, 0xFC, 0xD0, 0xCD, 0xE2, 0xFC, 0x36, 0xF0, 0xC7, 0x40, 0x16, 0x9A, 0x00, 0x24, 0x7F, 0xC4, 0x3B, 0x0A, 0x4B, 0x10, 0x48, 0x4F, 0x31, 0x20, 0xC6, 0x82, 0x40, 0xFA, 0x0A, 0x02, 0x19, 0x82, 0x40, 0x8C, 0x82, 0x40, 0x7A, 0x28, 0x90, 0x25, 0x08, 0xC4, 0x28, 0x08, 0xE4, 0x2D, 0x0A, 0x64, 0x86, 0x02, 0x59, 0xA2, 0x40, 0x14, 0x04, 0x92, 0x47, 0x0D, 0x39, 0xFD, 0xBE, 0xFB, 0x71, 0xF2, 0x38, 0x48, 0x3F, 0x5E, 0x48, 0x7E, 0xA5, 0xB7, 0x1D, 0x4E, 0x1E, 0x01, 0xE9, 0x45, 0x0B, 0xD9, 0xAB, 0xBD, 0x1F, 0x33, 0xF7, 0xBF, 0x3B, 0x68, 0x16, 0x29, 0x24, 0x2F, 0x75, 0xB3, 0x62, 0x27, 0x51, 0x48, 0x6E, 0xB5, 0xD6, 0x65, 0x03, 0x64, 0x18, 0x25, 0xC4, 0x39, 0xEA, 0x5D, 0xA7, 0x08, 0x29, 0xF5, 0x81, 0xFC, 0x90, 0x65, 0x8C, 0x90, 0xB9, 0x62, 0x40, 0x32, 0x05, 0x81, 0x94, 0xCF, 0x05, 0xA9, 0xA4, 0xD3, 0xE6, 0x1A, 0x02, 0x19, 0x46, 0x07, 0x31, 0x36, 0x08, 0x72, 0xA4, 0xCD, 0x49, 0xA7, 0xF5, 0xD4, 0x5F, 0xF8, 0x0D, 0xB1, 0x90, 0x4E, 0x2B, 0xC3, 0x20, 0x6F, 0xB4, 0xB1, 0x81, 0x74, 0x59, 0x5F, 0xC3, 0x20, 0x3D, 0x6D, 0xEC, 0xBD, 0x74, 0xD9, 0x51, 0x20, 0x24, 0xD3, 0xC6, 0xB6, 0xA4, 0xCB, 0x34, 0x10, 0x62, 0xB4, 0xB1, 0x33, 0xE9, 0xB0, 0xBE, 0x36, 0xF5, 0x45, 0x1E, 0xCE, 0xC6, 0xF5, 0x55, 0x6F, 0xB3, 0x60, 0xC8, 0x30, 0xAE, 0xE9, 0xBB, 0x6C, 0x86, 0x84, 0xFE, 0x0A, 0xB6, 0xA5, 0xCB, 0x34, 0x18, 0x92, 0x45, 0xB5, 0xD6, 0x33, 0x0D, 0x5D, 0xEC, 0x62, 0x6C, 0x4C, 0x4B, 0xA4, 0x17, 0x7A, 0x45, 0x9A, 0x07, 0x77, 0x51, 0x49, 0x87, 0xCD, 0x5A, 0x40, 0xFA, 0x11, 0x7D, 0xB2, 0x64, 0xD8, 0xE6, 0x6E, 0x60, 0xE3, 0xF9, 0x64, 0x49, 0xD9, 0x06, 0x32, 0x8B, 0x67, 0x66, 0x89, 0xB6, 0x81, 0xE4, 0xEA, 0xE9, 0x9B, 0xF8, 0x8A, 0x0B, 0x22, 0xC3, 0x68, 0xB6, 0xF0, 0xA6, 0x1D, 0x24, 0xF3, 0x8D, 0x88, 0x4E, 0xCB, 0xB5, 0xB9, 0x77, 0x21, 0x5B, 0xE7, 0xED, 0x4A, 0xBC, 0xC5, 0x06, 0x31, 0x36, 0x92, 0xF3, 0x93, 0xAC, 0x25, 0x44, 0x16, 0x51, 0xAC, 0xF4, 0xB6, 0x57, 0xC4, 0x75, 0xF4, 0xF2, 0x8F, 0x86, 0xA1, 0x90, 0xE6, 0xED, 0xF3, 0xA0, 0x92, 0xAE, 0x33, 0xED, 0x21, 0xA6, 0x8C, 0xC0, 0x11, 0x76, 0x1F, 0xA9, 0x4B, 0x96, 0x11, 0x38, 0x6A, 0x90, 0xB0, 0x3B, 0x82, 0x39, 0xD6, 0x8D, 0x46, 0xF2, 0x22, 0x95, 0x41, 0xCF, 0x23, 0xF5, 0xF2, 0x95, 0xDD, 0xF8, 0xF3, 0xE3, 0x8B, 0x34, 0x7C, 0xAA, 0x03, 0xDC, 0xD3, 0xFD, 0xAB, 0xC3, 0xDF, 0x13, 0x79, 0xB1, 0x66, 0xB1, 0x1D, 0xE0, 0x86, 0xD6, 0x8B, 0xEC, 0xDC, 0xF3, 0x19, 0x6F, 0xED, 0x1F, 0x24, 0x8D, 0xE2, 0x3A, 0x2E, 0x6C, 0x51, 0x19, 0xD5, 0x71, 0x61, 0xAB, 0xD5, 0x1E, 0xD3, 0x59, 0xC8, 0xDF, 0x76, 0xEE, 0x18, 0x05, 0x61, 0x20, 0x88, 0x02, 0xE8, 0x20, 0xA8, 0xB5, 0x4D, 0x7A, 0x8F, 0x90, 0xC6, 0x13, 0x08, 0xD6, 0x16, 0x89, 0xB5, 0x82, 0xBD, 0xF7, 0xAF, 0x44, 0x08, 0x16, 0x42, 0x6C, 0x36, 0x81, 0x9D, 0xE5, 0xBD, 0x1B, 0x0C, 0x3B, 0x33, 0xB0, 0x7F, 0x61, 0x0B, 0xEC, 0x1B, 0x19, 0x91, 0x29, 0x0A, 0xA9, 0xE6, 0xA6, 0x57, 0xE0, 0x5A, 0xD3, 0x7B, 0x66, 0x89, 0x4D, 0x23, 0x9D, 0x15, 0xD1, 0xB7, 0xB0, 0xB3, 0x3E, 0xC6, 0x7A, 0x52, 0xB6, 0xF5, 0xC6, 0xFD, 0x15, 0x99, 0xEC, 0x1A, 0x39, 0x90, 0x88, 0xBE, 0x85, 0x09, 0xF9, 0x17, 0x41, 0x3C, 0x23, 0x9B, 0xB1, 0x8A, 0xB4, 0x70, 0x09, 0xC7, 0x1A, 0xD2, 0xC2, 0x25, 0x6C, 0xFB, 0xFC, 0x03, 0x32, 0x53, 0x49, 0x97, 0x6B, 0xF3, 0xCE, 0xA6, 0x53, 0x5D, 0xC6, 0xBE, 0x9A, 0xDC, 0xEE, 0x87, 0xAF, 0x47, 0xA4, 0x76, 0x39, 0x4D, 0xDF, 0x1D, 0x24, 0x5C, 0x57, 0xBF, 0x86, 0xF3, 0xD0, 0x40, 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x35, 0x79, 0x03, 0xE4, 0x9B, 0xC4, 0xE4, 0x4C, 0x1C, 0x87, 0x37, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82};
		__autoreleasing NSData* noArt_data = [NSData dataWithBytes:MaskForBlurData length:sizeof(MaskForBlurData)];
		kNoArtwork = [[[UIImage imageWithData:noArt_data] imageWithSize:CGSizeMake(springboardWindow.frame.size.height, springboardWindow.frame.size.height)] copy];
	}	
	static __strong NSString* kMus = @"Music";
	static __strong NSString* kIfem = @" – ";
	static __strong NSString* kArt = @"Artist";
	static __strong NSString* kAlb = @"Album";
	[self performSelectorInBackground:@selector(updateNowPlayingStatus) withObject:nil];
	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
	    MusicStarted = CFDateGetAbsoluteTime((CFDateRef)[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTimestamp]);
		timeIntervalifPause = (NSTimeInterval)[[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime] doubleValue];
		duration = (NSTimeInterval)[[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDuration] doubleValue];
		
		__autoreleasing NSData* artwork = [(__bridge NSDictionary *)result objectForKey:(NSData *)(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
		artworkView.image = [[[UIImage imageWithData:artwork] imageWithSize:CGSizeMake(springboardWindow.frame.size.height, springboardWindow.frame.size.height)] copy]?:kNoArtwork;
		titleLabel.text = [[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle] copy]?:kMus;
		artistLabel.text = [[[[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist]?:kArt stringByAppendingString:kIfem] stringByAppendingString:[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoAlbum]?:kAlb] copy];
		if (Blur == 4) {
			artworkViewBlur.image = artworkView.image;
		}
	});
}
- (void)updateNowPlayingStatus
{
	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
		timeIntervalifPause = (NSTimeInterval)[[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime] doubleValue];
		if (WidPlayerHideNoPlaying&&WidPlayerEnabled) {
			[[[WidPlayer sharedInstance] widgetWindow] setHidden:!result];
		}
	});
	MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_main_queue(), ^(Boolean isPlay) {
	    isPlaying = isPlay;
	    static __strong UIImage* kPause = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"pause" ofType:@"png"]];
		static __strong UIImage* kPlay = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"play" ofType:@"png"]];
		CGSize BTSize = CGSizeMake((springboardWindow.frame.size.height/3), (springboardWindow.frame.size.height/3));
        [playPauseButton setImage:isPlaying?[kPause imageWithSize:BTSize]:[kPlay imageWithSize:BTSize] forState:UIControlStateNormal];	
		[playPauseButton sizeToFit];
        [self stop_timer:!isPlaying];
	});
	[self statusSoundButton];
}
-(void) statusSoundButton
{
	BOOL mute;
	[[AVSystemController sharedAVSystemController] getActiveCategoryMuted:&mute];
	static __strong UIImage* kSoundOn = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"soundOn" ofType:@"png"]];
	static __strong UIImage* kSoundOff = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:@"soundOff" ofType:@"png"]];
	CGSize BTSize = CGSizeMake((springboardWindow.frame.size.height/4), (springboardWindow.frame.size.height/4));
	[SoundButton setImage:mute?[kSoundOff imageWithSize:BTSize]:[kSoundOn imageWithSize:BTSize] forState:UIControlStateNormal];
	[SoundButton sizeToFit];
}
-(void)stop_timer:(BOOL)stop
{
	if(progressUpdateTimer != nil) {
		if([progressUpdateTimer isValid]) {
			[progressUpdateTimer invalidate];
		}
		progressUpdateTimer = nil;
	}
	if (stop) {
		[trackProgress setValue:0 animated:NO];
		return;
	}
	progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
}
- (void)updateProgress:(NSTimer *)timer
{
	@autoreleasepool {
		if (!isPlaying) {
		    if([progressUpdateTimer isValid]) {
				[timer invalidate];
			}
			progressUpdateTimer = nil;
			[trackProgress setValue:0 animated:NO];
			return;
		}
		nowSec = (CFAbsoluteTimeGetCurrent() - MusicStarted) + (timeIntervalifPause>1?timeIntervalifPause:0);
		[trackProgress setValue:duration?(nowSec/duration):0 animated:NO];
	}
}
@end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application
{
    %orig;
    [[WidPlayer sharedInstance] firstload];
}
%end

%end
@interface WidPlayerActivator : NSObject
+ (id)sharedInstance;
- (void)RegisterActions;
@end
@implementation WidPlayerActivator
+ (id)sharedInstance
{
    __strong static id _sharedObject;
	if (!_sharedObject) {
		_sharedObject = [[self alloc] init];
	}
	return _sharedObject;
}
- (void)RegisterActions
{
    if (access("/usr/lib/libactivator.dylib", F_OK) == 0) {
        dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	    Class la = %c(LAActivator);
	    if (la) {
        	[[la sharedInstance] registerListener:(id<LAListener>)self forName:@"com.julioverne.widplayer"];
		}
	}
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName
{
	return @"WidPlayer";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName
{
	return @"Show/Hide WidPlayer";
}
- (UIImage *)activator:(LAActivator *)activator requiresIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale
{
    static __strong UIImage* listenerIcon;
    if (!listenerIcon) {
		listenerIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:scale==2.0f?@"icon@2x":@"icon" ofType:@"png"]];
	}
    return listenerIcon;
}
- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale
{
    static __strong UIImage* listenerIcon;
    if (!listenerIcon) {
		listenerIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/WidPlayer.bundle"] pathForResource:scale==2.0f?@"icon@2x":@"icon" ofType:@"png"]];
	}
    return listenerIcon;
}
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	if ([WidPlayer sharedInstanceExist]) {
		[[[WidPlayer sharedInstance] widgetWindow] setHidden:![[WidPlayer sharedInstance] widgetWindow].hidden];
		[[WidPlayer sharedInstance] widgetWindow].alpha = 1.0;
		[[WidPlayer sharedInstance] widgetWindow].frame = CGRectMake(20, 60, WidgetWidth, WidgetWidth/2.5);
	}
}
@end
static void settingsChangedWidPlayer(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@autoreleasepool {
		NSDictionary *WidPlayerPrefs;
		if (access(PLIST_PATH_Settings, F_OK) == 0) {
			WidPlayerPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings] copy];
		} else {
			NSDictionary* Pref = @{
				   @"Enabled": @YES,
				   @"Blur": @4,
		   };
		   [Pref writeToFile:@PLIST_PATH_Settings atomically:YES];
		   WidPlayerPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings] copy];
		}
		WidPlayerEnabled = (BOOL)[[WidPlayerPrefs objectForKey:@"Enabled"]?:@YES boolValue];
		WidPlayerHideLockScreen = (BOOL)[[WidPlayerPrefs objectForKey:@"WidPlayerHideLockScreen"]?:@NO boolValue];
		int newWidPlayerHideNoPlaying = (BOOL)[[WidPlayerPrefs objectForKey:@"HideNoPlaying"]?:@NO boolValue];
		Blur = (int)[[WidPlayerPrefs objectForKey:@"Blur"]?:@4 intValue];
		int newWidgetWidth = (int)[[WidPlayerPrefs objectForKey:@"WidgetWidth"]?:@([[UIScreen mainScreen] bounds].size.width/1.6) intValue];
		int newWidgetRadius = (int)[[WidPlayerPrefs objectForKey:@"WidgetRadius"]?:@15 intValue];
		int newArtworkRadius = (int)[[WidPlayerPrefs objectForKey:@"ArtworkRadius"]?:@10 intValue];
		if ([WidPlayer sharedInstanceExist]) {
			[[[WidPlayer sharedInstance] widgetWindow] setHidden:!WidPlayerEnabled];
			if (newWidgetWidth != WidgetWidth || newWidPlayerHideNoPlaying != WidPlayerHideNoPlaying) {
				WidgetWidth = newWidgetWidth;
				WidPlayerHideNoPlaying = newWidPlayerHideNoPlaying;
				[[WidPlayer sharedInstance] UpdateFrame];
				[[WidPlayer sharedInstance] updateNowPlayingStatus];
			}
			if (newWidgetRadius != WidgetRadius || newArtworkRadius != ArtworkRadius) {
				WidgetRadius = newWidgetRadius;
				ArtworkRadius = newArtworkRadius;
				[[WidPlayer sharedInstance] UpdateRadius];
			}
			[[WidPlayer sharedInstance] UpdateBlur];
		} else {
			WidgetWidth = newWidgetWidth;
			WidgetRadius = newWidgetRadius;
			ArtworkRadius = newArtworkRadius;
			WidPlayerHideNoPlaying = newWidPlayerHideNoPlaying;
		}
	}
}
__attribute__((constructor)) static void initialize_WidPlayer()
{
	@autoreleasepool {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChangedWidPlayer, CFSTR("com.julioverne.widplayer/Settings"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		settingsChangedWidPlayer(NULL, NULL, NULL, NULL, NULL);
		if (WidPlayerEnabled) {
			%init(WidPlayerHooks);
			[[WidPlayerActivator sharedInstance] RegisterActions];
		}
	}
}