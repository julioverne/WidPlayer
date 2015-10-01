#import <objc/runtime.h>
#import "UIWindow.h"

static int WidthMax;

@implementation UIWindow (draggable)
- (void)setPanGesture:(UIPanGestureRecognizer*)panGesture
{
    objc_setAssociatedObject(self, @selector(panGesture), panGesture, OBJC_ASSOCIATION_RETAIN);
}
- (UIPanGestureRecognizer*)panGesture
{
    return objc_getAssociatedObject(self, @selector(panGesture));
}
- (void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer
{
@autoreleasepool {
    UIGestureRecognizerState state = [gestureRecognizer state];
	UIView* View = [gestureRecognizer view];
	self.alpha = 1.0;
	
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
	
		if (state == UIGestureRecognizerStateBegan) {
			[UIView animateWithDuration:0.3/1.5 animations:^{
			View.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
			} completion:nil];	
		}
        CGPoint translation = [gestureRecognizer translationInView:View];
		[View setCenter:CGPointMake([View center].x + translation.x, [View center].y + translation.y)];
		[gestureRecognizer setTranslation:CGPointZero inView:View];
		
	} else if (state == UIGestureRecognizerStateEnded) {
	CGPoint translation = [gestureRecognizer translationInView:View];
		[UIView animateWithDuration:0.3/2 animations:^{
			View.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:0.3/2 animations:^{
				View.transform = CGAffineTransformIdentity;
			}];
			[UIView animateWithDuration:0.3/1.5 animations:^{
				int pointX = [View center].x + translation.x;
				int pointY = [View center].y + translation.y;
				int Borda = View.frame.size.width/2.3;
				if (pointX >= WidthMax-100) {
					pointX = WidthMax+(Borda);
					self.alpha = 0.3;
				} else if (pointX <= 100) {
				    pointX = 0-(Borda);
					self.alpha = 0.3;
				}
				[View setCenter:CGPointMake( pointX, pointY)];
			} completion:nil];	
			[gestureRecognizer setTranslation:CGPointZero inView:View];			
		}];
	}
	
}
}
- (void)setDraggable:(BOOL)draggable
{
    [self.panGesture setEnabled:draggable];
}
- (void)enableDragging
{
    WidthMax = [[UIScreen mainScreen] bounds].size.width;
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.panGesture setMaximumNumberOfTouches:1];
    [self.panGesture setMinimumNumberOfTouches:1];
    [self.panGesture setCancelsTouchesInView:NO];
	[self addGestureRecognizer:self.panGesture];

}
@end