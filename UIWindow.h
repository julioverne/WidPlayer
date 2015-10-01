@interface UIWindow (draggable)
@property (nonatomic) UIPanGestureRecognizer *panGesture;
- (void)enableDragging;
- (void)setDraggable:(BOOL)draggable;
@end