#import <objc/runtime.h>
#import "WidPlayer.h"


@implementation WidPlayerWindow
@synthesize isLandscape, panGesture, stopTouch, WidthMax, HeightMax, orientationNow;
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
			}
			if(stopTouch) {
				return;
			}
			[UIView animateWithDuration:0.2/2 animations:^{
				[[self.panGesture view] setCenter:CGPointMake([[self.panGesture view] center].x + directionX, [[self.panGesture view] center].y + directionY)];
				[self.panGesture setTranslation:CGPointZero inView:[self.panGesture view]];
				
				int pointX = [[self.panGesture view] center].x + translation.x;
				int pointY = [[self.panGesture view] center].y + translation.y;
				if(isLandscape) {
					if (pointY >= HeightMax-30) {
						if(self.alpha >= 1) {
							[[WidPlayer sharedInstance] hideWidPlayer:nil];
						} else {
							[[WidPlayer sharedInstance] showWidPlayer];
							stopTouch = YES;
						}
					} else if (pointY <= 30) {
						if(self.alpha >= 1) {
							[[WidPlayer sharedInstance] hideWidPlayer:nil];
						} else {
							[[WidPlayer sharedInstance] showWidPlayer]; 
							stopTouch = YES;
						}
					} else {
						if(self.alpha < 1) {
							[[WidPlayer sharedInstance] showWidPlayer];
							stopTouch = YES;
						}
					}
				} else {
					if (pointX >= WidthMax-30) {
						if(self.alpha >= 1) {
							[[WidPlayer sharedInstance] hideWidPlayer:nil];
						} else {
							[[WidPlayer sharedInstance] showWidPlayer];
							stopTouch = YES;
						}
					} else if (pointX <= 30) {
						if(self.alpha >= 1) {
							[[WidPlayer sharedInstance] hideWidPlayer:nil];
						} else {
							[[WidPlayer sharedInstance] showWidPlayer]; 
							stopTouch = YES;
						}
					} else {
						if(self.alpha < 1) {
							[[WidPlayer sharedInstance] showWidPlayer];
							stopTouch = YES;
						}
					}
				}
			}];
			if (state == UIGestureRecognizerStateBegan) {
				@autoreleasepool {
					NSMutableDictionary *CydiaEnablePrefsCheck = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSMutableDictionary dictionary];
					[CydiaEnablePrefsCheck setObject:[NSNumber numberWithFloat:[self.panGesture view].frame.origin.x] forKey:isLandscape?@"xl":@"x"];
					[CydiaEnablePrefsCheck setObject:[NSNumber numberWithFloat:[self.panGesture view].frame.origin.y] forKey:isLandscape?@"yl":@"y"];
					[CydiaEnablePrefsCheck writeToFile:@PLIST_PATH_Settings atomically:YES];
				}
			}
			
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
					if (pointX > WidthMax-([self.panGesture view].frame.size.width/2)) {
						pointX = WidthMax-([self.panGesture view].frame.size.width/2);
					} else if (pointX < ([self.panGesture view].frame.size.width/2)) {
						pointX = ([self.panGesture view].frame.size.width/2);
					}
					if (pointY >= HeightMax-100) {
						pointY = HeightMax+(Borda);
						self.alpha = 0.3;
					} else if (pointY <= 100) {
						pointY = 0-(Borda);
						self.alpha = 0.3;
					} else {
						self.alpha = 1.0;
					}
				} else {
					if (pointX >= WidthMax-100) {
						pointX = WidthMax+(Borda);
						self.alpha = 0.3;
					} else if (pointX <= 100) {
						pointX = 0-(Borda);
						self.alpha = 0.3;
					} else {
						self.alpha = 1.0;
					}
					if (pointY <= ([self.panGesture view].frame.size.height/2) ) {
						pointY = [self.panGesture view].frame.size.height/2;
					} else if (pointY >= (HeightMax-([self.panGesture view].frame.size.height/2)) ) {
						pointY = (HeightMax-([self.panGesture view].frame.size.height/2));
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

- (void)statusBarDidChangeFrame:(NSNotification *)__unused notification
{
	@autoreleasepool {
    orientationNow = [[UIDevice currentDevice] orientation];
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
		
		if(isLandscape) {
			if ([self.panGesture view].frame.origin.y >= HeightMax-30) {
				self.alpha = 0.3;
			} else if ([self.panGesture view].frame.origin.y <= 0) {
				self.alpha = 0.3;
			} else {
				self.alpha = 1.0;
			}
		} else {
			if ([self.panGesture view].frame.origin.x >= WidthMax-30) {
				self.alpha = 0.3;
			} else if ([self.panGesture view].frame.origin.x <= 0) {
				self.alpha = 0.3;
			} else {
				self.alpha = 1.0;
			}
		}
	} completion:nil];
	}
}
- (void)enableDragging
{
	orientationNow = [[UIDevice currentDevice] orientation];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarDidChangeFrame:) name:UIDeviceOrientationDidChangeNotification object:nil];
    WidthMax = [[UIScreen mainScreen] bounds].size.width;
	HeightMax = [[UIScreen mainScreen] bounds].size.height;
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan)];
    [self.panGesture setMaximumNumberOfTouches:1];
    [self.panGesture setMinimumNumberOfTouches:1];
    [self.panGesture setCancelsTouchesInView:YES];
	[self addGestureRecognizer:self.panGesture];
}

@end