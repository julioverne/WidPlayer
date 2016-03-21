#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <notify.h>
#import <substrate.h>
#import <libactivator/libactivator.h>
#import <CommonCrypto/CommonCrypto.h>

#import <MediaPlayer/MediaPlayer.h>

#import "MediaRemote.h"

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.widplayer.plist"


@interface WidPlayerActivator : NSObject
+ (id)sharedInstance;
- (void)RegisterActions;
@end

@interface MPUTransportControlsView : UIView
@property (nonatomic) unsigned int minimumNumberOfTransportButtonsForLayout;
@end


@interface MPUMediaControlsVolumeView : UIView
{
    UISlider *_slider;
}
@end
@interface MPUNowPlayingTitlesView : UIView
{
    UILabel *_detailLabel;
    UILabel *_titleLabel;
}
- (void)setTextMargin:(float)arg1;
- (void)setTitleLeading:(float)arg1;
@end
@interface MPUSystemMediaControlsView : UIView
{
    MPUMediaControlsVolumeView *_volumeView;
	MPUNowPlayingTitlesView *_trackInformationView;
}
@property (nonatomic, readonly) MPUTransportControlsView *transportControlsView;
@end

@interface MPUNowPlayingController : NSObject
@property (nonatomic, readonly) NSDictionary *currentNowPlayingInfo;
@end

@interface MPUSystemMediaControlsViewController : UIViewController
{
	MPUSystemMediaControlsView *_mediaControlsView;
}
- (id)alloc;
- (id)initWithStyle:(int)arg1;
- (void)nowPlayingController:(id)arg1 elapsedTimeDidChange:(double)arg2;
- (void)nowPlayingController:(id)arg1 nowPlayingApplicationDidChange:(id)arg2;
- (void)nowPlayingController:(id)arg1 nowPlayingInfoDidChange:(id)arg2;
- (void)nowPlayingController:(id)arg1 playbackStateDidChange:(BOOL)arg2;
@end



@interface SBApplication : NSObject
- (id)bundleIdentifier;
- (id)displayName;
@end
@interface SBUIController : NSObject
+ (id)sharedInstance;
- (void)activateApplicationAnimated:(SBApplication *)appID;
- (void)activateApplication:(SBApplication *)appID;
@end
@interface SBApplicationIcon : NSObject
-(id)initWithApplication:(id)application;
-(id)icon;
-(id)generateIconImage:(int)image;
@end
@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (SBApplication *)applicationWithPid:(int)pid;
@end


@interface UIImage (Private)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier roleIdentifier:(NSString *)roleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface UIImage (PlayerImage)
- (UIImage *)imageWithSize:(CGSize)size;
- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage;
+ (UIImage *)iconWithSBApplication:(SBApplication *)app;
@end

@protocol FLEXWindowEventDelegate;

@interface WidPlayerWindow : UIWindow
{
	UIPanGestureRecognizer *panGesture;
	BOOL isLandscape;
	BOOL stopTouch;
	int WidthMax;
	int HeightMax;
	UIDeviceOrientation orientationNow;
}
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) BOOL isLandscape;
@property (nonatomic, assign) BOOL stopTouch;
@property (nonatomic, assign) int WidthMax;
@property (nonatomic, assign) int HeightMax;
@property (nonatomic, assign) UIDeviceOrientation orientationNow;
@property (nonatomic, strong) id <FLEXWindowEventDelegate> eventDelegate;
- (void)enableDragging;
- (void)setDraggable:(BOOL)draggable;
@end

@protocol FLEXWindowEventDelegate <NSObject>
- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow;
- (BOOL)canBecomeKeyWindow;
@end

@interface WidPlayer : NSObject
{
	WidPlayerWindow* springboardWindow;
	UIView* libraryWindow;
	UIBezierPath *shadowPath;
	UIViewController* controller;
	UIView* blurView;
	UIView* lyricView;
	UIImageView *artworkViewBlur;
	UIVisualEffectView *effectView;
	UIVisualEffectView* effectViewLiryc;
	UIImageView *artworkView;
	UIImage* kNoArtwork;
	SBApplication *isPlayingSBApp;
	MPUSystemMediaControlsViewController* controlsView;
	UIView* mediaPlay;
	MPMediaPickerController *mediaPicker;
	NSArray* lirycTimeArray;
	UILabel* lirycLabel;
	int indexNextTimeLiryc;
	NSTimeInterval nextTimeLiryc;
}
@property (nonatomic, strong) WidPlayerWindow* springboardWindow;
@property (nonatomic, strong) UIView* libraryWindow;
@property (nonatomic, strong) UIBezierPath *shadowPath;
@property (nonatomic, strong) UIViewController* controller;
@property (nonatomic, strong) UIView* blurView;
@property (nonatomic, strong) UIView* lyricView;
@property (nonatomic, strong) UIVisualEffectView *effectView;
@property (nonatomic, strong) UIVisualEffectView* effectViewLiryc;
@property (nonatomic, strong) UIImageView *artworkView;
@property (nonatomic, strong) UIImage* kNoArtwork;
@property (nonatomic, strong) SBApplication* isPlayingSBApp;
@property (nonatomic, strong) MPUSystemMediaControlsViewController* controlsView;
@property (nonatomic, strong) UIView* mediaPlay;
@property (nonatomic, strong) MPMediaPickerController *mediaPicker;
@property (nonatomic, strong) NSArray* lirycTimeArray;
@property (nonatomic, strong) UILabel* lirycLabel;
@property (nonatomic, assign) int indexNextTimeLiryc;
@property (nonatomic, assign) NSTimeInterval nextTimeLiryc;

+ (id)sharedInstance;
+ (BOOL)sharedInstanceExist;
- (void)fixTransportControls;
- (void)firstload;
- (void)UpdateFrame;
- (void)showWidPlayer;
- (void)libraryWindowHide;
- (void)hideWidPlayer:(id)handle;
@end


