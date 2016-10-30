#import <objc/runtime.h>
#import "WidPlayer.h"
extern int WidgetWidth;

@implementation WidPlayerWindow
@synthesize isLandscape, panGesture, stopTouch, WidthMax, HeightMax, orientationNow, orientationNowOld;
- (void)handlePan
{
	@autoreleasepool {
		
		UIGestureRecognizerState state = [self.panGesture state];
		CGPoint translation = [self.panGesture translationInView:[self.panGesture view]];
		CGPoint velocity = [self.panGesture velocityInView:[self.panGesture view]];
		
		CGFloat directionX;
		CGFloat directionY;
		CGFloat velocityX;
		CGFloat velocityY;
		
		switch (orientationNow) {
			case UIInterfaceOrientationPortrait: {
				directionX = translation.x;
				directionY = translation.y;
				velocityX = velocity.x;
				velocityY = velocity.y;
				break;
			}
			case UIInterfaceOrientationLandscapeLeft: {
				directionX = translation.y;
				directionY = -translation.x;
				velocityX = velocity.y;
				velocityY = -velocity.x;
				break;
			}
			case UIInterfaceOrientationLandscapeRight: {
				directionX = -translation.y;
				directionY = translation.x;
				velocityX = -velocity.y;
				velocityY = velocity.x;
				break;
			}
			case UIInterfaceOrientationPortraitUpsideDown: {
				directionX = -translation.x;
				directionY = -translation.y;
				velocityX = -velocity.x;
				velocityY = -velocity.y;
				break;
			}			
			default: {
				directionX = translation.x;
				directionY = translation.y;
				velocityX = velocity.x;
				velocityY = velocity.y;
				break;
			}
		}

		if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
			if (state == UIGestureRecognizerStateBegan) {
				if(stopTouch) {
					stopTouch = NO;
				}
				return;
			}
			if(stopTouch) {
				return;
			}
			[UIView animateWithDuration:0.1/2/*0.2/2*/ animations:^{
				[[self.panGesture view] setCenter:CGPointMake([[self.panGesture view] center].x + directionX, [[self.panGesture view] center].y + directionY)];
				[self.panGesture setTranslation:CGPointZero inView:[self.panGesture view]];
				
				int pointX = [[self.panGesture view] center].x + translation.x;
				int pointY = [[self.panGesture view] center].y + translation.y;
				if ((isLandscape?pointY:pointX) >= WidthMax-30) {
					if(self.alpha >= 1) {
						[self hideWidPlayer:nil];
					} else {
						[self showWidPlayer];
						stopTouch = YES;
					}
				} else if ((isLandscape?pointY:pointX) <= 30) {
					if(self.alpha >= 1) {
						[self hideWidPlayer:nil];
					} else {
						[self showWidPlayer]; 
						stopTouch = YES;
					}
				} else {
					if(self.alpha < 1) {
						[self showWidPlayer];
						stopTouch = YES;
					}
				}
			}];			
		} else if (state == UIGestureRecognizerStateEnded) {
			if(stopTouch) {
				stopTouch = NO;
				return;
			}
			[UIView animateWithDuration:0.5/1.5 animations:^{
				CGFloat magnitude = sqrtf((velocityX * velocityX) + (velocityY * velocityY));
				CGFloat slideMult = magnitude / 700;
				float slideFactor = 0.1 * slideMult;				
				
				int pointX = [[self.panGesture view] center].x + (velocityX * slideFactor) + directionX;
				int pointY = [[self.panGesture view] center].y + (velocityY * slideFactor) + directionY;
				int Borda = isLandscape?([self.panGesture view].frame.size.height/2.3):([self.panGesture view].frame.size.width/2.3);
				
				if(isLandscape) {
					if (pointX <= ([self.panGesture view].frame.size.width/2)) {
						pointX = ([self.panGesture view].frame.size.width/2);
					} else if (pointX >= HeightMax-([self.panGesture view].frame.size.width/2)) {
						pointX = HeightMax-([self.panGesture view].frame.size.width/2);
					}
					if (pointY >= WidthMax-100) {
						pointY = WidthMax+(Borda);
						self.alpha = 0.3;
					} else if (pointY <= 100) {
						pointY = 0-(Borda);
						self.alpha = 0.3;
					} else {
						self.alpha = 1.0;
					}
				} else {
					if (pointY <= ([self.panGesture view].frame.size.height/2) ) {
						pointY = [self.panGesture view].frame.size.height/2;
					} else if (pointY >= (HeightMax-([self.panGesture view].frame.size.height/2)) ) {
						pointY = (HeightMax-([self.panGesture view].frame.size.height/2));
					}
					if (pointX >= WidthMax-100) {
						pointX = WidthMax+(Borda);
						self.alpha = 0.3;
					} else if (pointX <= 100) {
						pointX = 0-(Borda);
						self.alpha = 0.3;
					} else {
						self.alpha = 1.0;
					}					
				}				
				[[self.panGesture view] setCenter:CGPointMake( pointX, pointY)];
			} completion:nil];
			[self.panGesture setTranslation:CGPointZero inView:[self.panGesture view]];
			if(self.alpha < 1) {
				WidPlayer* sharedWP = [WidPlayer sharedInstance];
				if (!sharedWP.libraryWindow.hidden) {
					[sharedWP libraryWindowHide];
				}
			}			
            @autoreleasepool {
				NSMutableDictionary *CydiaEnablePrefsCheck = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSMutableDictionary dictionary];
				[CydiaEnablePrefsCheck setObject:[NSNumber numberWithFloat:[self.panGesture view].frame.origin.x] forKey:isLandscape?@"xl":@"x"];
				[CydiaEnablePrefsCheck setObject:[NSNumber numberWithFloat:[self.panGesture view].frame.origin.y] forKey:isLandscape?@"yl":@"y"];
				[CydiaEnablePrefsCheck writeToFile:@PLIST_PATH_Settings atomically:YES];
			}
		}
	}
}

- (void)showWidPlayer
{
	if(self.alpha < 1) {
		[UIView animateWithDuration:0.3/1.5 animations:^{
			CGRect frame = self.frame;
			if(self.isLandscape) {
				frame.origin.y = ((WidthMax/2) - ([self.panGesture view].frame.size.height/2));
			} else {
				frame.origin.x = ((WidthMax/2) - ([self.panGesture view].frame.size.width/2));
			}
			self.frame = frame;
			self.alpha = 1;			
		}];
	}
}
- (void)hideWidPlayer:(id)handle
{
	if(self.alpha >= 1) {
		[UIView animateWithDuration:0.3/1.5 animations:^{
			//int Borda = (WidgetWidth/2.3);
			int Borda = isLandscape?([self.panGesture view].frame.size.height/2.3):([self.panGesture view].frame.size.width/2.3);
			CGRect frame = self.frame;
			
			if(self.isLandscape) {
				frame.origin.y = self.frame.origin.y<=0? 0-(Borda*2.1):((WidthMax)+([self.panGesture view].frame.size.height))-(Borda*2.5);
			} else {
				frame.origin.x = self.frame.origin.x<=0? 0-(Borda*2.1):((WidthMax)+[self.panGesture view].frame.size.width)-(Borda*2.5);
			}
			self.frame = frame;
			//self.alpha = 0.3;
		}];
	}
}

- (void)setDraggable:(BOOL)draggable
{
    [self.panGesture setEnabled:draggable];
}

#define DegreesToRadians(degrees) (degrees * M_PI / 180)
- (CGAffineTransform)transformForOrientation:(UIDeviceOrientation)orientation
{
    switch (orientation) {
        case UIDeviceOrientationLandscapeRight: {			
			isLandscape = YES;
			return CGAffineTransformMakeRotation(-DegreesToRadians(90));
		}
        case UIDeviceOrientationLandscapeLeft: {
			isLandscape = YES;
			return CGAffineTransformMakeRotation(DegreesToRadians(90));
		}
		case UIDeviceOrientationPortraitUpsideDown: {
			isLandscape = NO;
			return CGAffineTransformMakeRotation(DegreesToRadians(180));
		}
		case UIDeviceOrientationPortrait:
        default: {
			isLandscape = NO;
			return CGAffineTransformMakeRotation(DegreesToRadians(0));
		}
    }
}

- (void)statusBarDidChangeFrame
{
	@autoreleasepool {
		if(self.hidden) {
			return;
		}
		orientationNow = [[UIApplication sharedApplication] _frontMostAppOrientation];//[[UIDevice currentDevice] orientation];
		if(orientationNow == orientationNowOld) {
			return;
		}
		switch (orientationNow) {
			case UIDeviceOrientationLandscapeRight: {
				isLandscape = YES;
				break;
			}
			case UIDeviceOrientationLandscapeLeft: {
				isLandscape = YES;
				break;
			}
			case UIDeviceOrientationPortraitUpsideDown: {
				isLandscape = NO;
				break;
			}
			case UIDeviceOrientationPortrait: {
				isLandscape = NO;
				break;
			}
			default: {
				isLandscape = NO;
				break;
			}
		}
		
		WidthMax  = [[UIScreen mainScreen] bounds].size.width;
		HeightMax = [[UIScreen mainScreen] bounds].size.height;
		if(isLandscape) {
			if(WidthMax < HeightMax) {
				int tempHeight = HeightMax;
				HeightMax = WidthMax;
				WidthMax = tempHeight;
			}
		} else {
			if(WidthMax > HeightMax) {
				int tempWidth = WidthMax;
				WidthMax = HeightMax;
				HeightMax = tempWidth;
			}
		}
		
		[UIView animateWithDuration:0.5/1.5 animations:^{
			[[WidPlayer sharedInstance] showWidPlayer];
			[self setTransform:[self transformForOrientation:orientationNow]];
			NSDictionary *WidPlayerPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary] copy];
			float x = [[WidPlayerPrefs objectForKey:@"x"]?:@(0-([self.panGesture view].frame.size.width-([self.panGesture view].frame.size.width/15))) floatValue];
			float y = [[WidPlayerPrefs objectForKey:@"y"]?:@(60) floatValue];
			float xl = [[WidPlayerPrefs objectForKey:@"xl"]?:@(60) floatValue];
			float yl = [[WidPlayerPrefs objectForKey:@"yl"]?:@( 0-([self.panGesture view].frame.size.height-([self.panGesture view].frame.size.height/15)) ) floatValue];

			CGRect frame = [self.panGesture view].frame;
			frame.origin.y = isLandscape?yl:y;
			frame.origin.x = isLandscape?xl:x;
			[self.panGesture view].frame = frame;
			
			if ((isLandscape?[self.panGesture view].frame.origin.y:[self.panGesture view].frame.origin.x) >= WidthMax-30) {
				self.alpha = 0.3;
			} else if ((isLandscape?[self.panGesture view].frame.origin.y:[self.panGesture view].frame.origin.x) <= 0) {
				self.alpha = 0.3;
			} else {
				self.alpha = 1.0;
			}
			orientationNowOld = orientationNow;
		} completion:nil];
	}
}
- (void)changeOrientationNotify
{
	@autoreleasepool {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(statusBarDidChangeFrame) object:self];
		[self performSelector:@selector(statusBarDidChangeFrame) withObject:self afterDelay:0.3];
	}
}
- (void)enableDragging
{
	orientationNow = [[UIApplication sharedApplication] _frontMostAppOrientation];//[[UIDevice currentDevice] orientation];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeOrientationNotify) name:UIDeviceOrientationDidChangeNotification object:nil];
	switch (orientationNow) {
		case UIDeviceOrientationLandscapeRight: {
			isLandscape = YES;
			break;
		}
		case UIDeviceOrientationLandscapeLeft: {
			isLandscape = YES;
			break;
		}
		case UIDeviceOrientationPortraitUpsideDown: {
			isLandscape = NO;
			break;
		}
		case UIDeviceOrientationPortrait: {
			isLandscape = NO;
			break;
		}
		default: {
			isLandscape = NO;
			break;
		}
	}
	
	WidthMax  = [[UIScreen mainScreen] bounds].size.width;
	HeightMax = [[UIScreen mainScreen] bounds].size.height;
	if(isLandscape) {
			if(WidthMax < HeightMax) {
				int tempHeight = HeightMax;
				HeightMax = WidthMax;
				WidthMax = tempHeight;
			}
	} else {
			if(WidthMax > HeightMax) {
				int tempWidth = WidthMax;
				WidthMax = HeightMax;
				HeightMax = tempWidth;
			}
	}
	
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan)];
    [self.panGesture setMaximumNumberOfTouches:1];
    [self.panGesture setMinimumNumberOfTouches:1];
    [self.panGesture setCancelsTouchesInView:YES];
	[self addGestureRecognizer:self.panGesture];
	[self _setSecure:YES];
}
@end