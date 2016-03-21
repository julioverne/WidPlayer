#import "WidPlayer.h"

static BOOL WidPlayerEnabled;
static BOOL WidPlayerHideNoPlaying;
static BOOL WidPlayerLyrics;
static int Blur;
static int WidgetWidth;
static int WidgetRadius;
static int ArtworkRadius;
static float WidgetOriginX;
static float WidgetOriginY;

%group WidPlayerHooks


@implementation UIImage (PlayerImage)
- (UIImage *)imageWithSize:(CGSize)size
{
	@autoreleasepool {
		if (NULL != &UIGraphicsBeginImageContextWithOptions) {
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
- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage
{
   @autoreleasepool {
	   CIContext *context = [objc_getClass("CIContext") contextWithOptions:nil];
	   CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];
	   CIFilter *filter = [objc_getClass("CIFilter") filterWithName:@"CIGaussianBlur"];
	   [filter setValue:inputImage forKey:kCIInputImageKey];
	   [filter setValue:[NSNumber numberWithFloat:15.0f] forKey:@"inputRadius"];
	   CIImage *result = [filter valueForKey:kCIOutputImageKey];
	   CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
	   UIImage *retVal = [UIImage imageWithCGImage:cgImage];
	   return retVal;
   }
}
+ (UIImage *)iconWithSBApplication:(SBApplication *)app
{
	@autoreleasepool {
		if (!app) {
			return nil;
		}
		UIImage* retImage = nil;
		@try {
			retImage = [[[objc_getClass("SBApplicationIcon") alloc] initWithApplication:app] generateIconImage:[UIScreen mainScreen].scale];
		} @catch (NSException * e) {
			
			@try {
			if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
				retImage = [UIImage _applicationIconImageForBundleIdentifier:[app bundleIdentifier] format:0 scale:[UIScreen mainScreen].scale];
			} else if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:roleIdentifier:format:scale:)]) {
				retImage = [UIImage _applicationIconImageForBundleIdentifier:[app bundleIdentifier] roleIdentifier:nil format:0 scale:[UIScreen mainScreen].scale];
			}
			} @catch (NSException * e) {
				
			}			
		}
		return retImage;
	}
}
@end
#define FRAME_CONTROLVIEW CGRectMake(artworkView.frame.size.width+(springboardWindow.frame.size.width/40), -15, springboardWindow.frame.size.width-(artworkView.frame.size.width+(springboardWindow.frame.size.width/40)), (WidgetWidth/2.5)+(32))
@implementation WidPlayer
@synthesize springboardWindow, libraryWindow, controller, blurView, effectView, shadowPath;
@synthesize artworkView, kNoArtwork, isPlayingSBApp, controlsView, mediaPlay, mediaPicker;
@synthesize lyricView, effectViewLiryc, lirycTimeArray, lirycLabel, indexNextTimeLiryc, nextTimeLiryc;
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
- (WidPlayerWindow*)widgetWindow
{
	return springboardWindow;
}
-(id)init
{
	self = [super init];
	if(self != nil) {
		springboardWindow = [[WidPlayerWindow alloc] initWithFrame:CGRectMake(WidgetOriginX, WidgetOriginY, WidgetWidth, WidgetWidth/2.5)];
		//springboardWindow.windowLevel = 9999999999;
		[springboardWindow setHidden:YES];
		[springboardWindow enableDragging];
		
		if(springboardWindow.isLandscape) {
			if (WidgetOriginY >= springboardWindow.HeightMax-30) {
				springboardWindow.alpha = 0.3;
			} else if (WidgetOriginY <= 0) {
				springboardWindow.alpha = 0.3;
			} else {
				springboardWindow.alpha = 1.0;
			}
		} else {
			if (WidgetOriginX >= springboardWindow.WidthMax-30) {
				springboardWindow.alpha = 0.3;
			} else if (WidgetOriginX <= 0) {
				springboardWindow.alpha = 0.3;
			} else {
				springboardWindow.alpha = 1.0;
			}
		}
		
		[springboardWindow.layer setCornerRadius:WidgetRadius];
		//shadowPath = [UIBezierPath bezierPathWithRoundedRect:springboardWindow.bounds cornerRadius:WidgetRadius];
		springboardWindow.layer.masksToBounds = NO;
		//springboardWindow.layer.shadowColor = [UIColor blackColor].CGColor;
		//springboardWindow.layer.shadowOffset = CGSizeMake(3.0f, 3.0f);
		//springboardWindow.layer.shadowOpacity = 0.4f;
		//springboardWindow.layer.shadowPath = shadowPath.CGPath;
		springboardWindow.layer.shouldRasterize  = NO;
		
		UIView *add = (UIView *)springboardWindow;
		
		controller = [UIViewController new];
		controller.view.frame = CGRectMake(0, 0, springboardWindow.frame.size.width, (WidgetWidth/2.5));
		controller.view.layer.masksToBounds = YES;
		controller.view.layer.cornerRadius = springboardWindow.layer.cornerRadius;

		//libraryWindow = [[UIWindow alloc] initWithFrame:CGRectMake(springboardWindow.frame.origin.x+(springboardWindow.frame.size.width/20), ((WidgetWidth/2.5)+springboardWindow.frame.origin.y)-(springboardWindow.frame.size.width/36), springboardWindow.frame.size.width-((springboardWindow.frame.size.width/20)*2), ((WidgetWidth/2.5)*2.5) )];
		libraryWindow = [UIView new];
		[libraryWindow setHidden:YES];
		
		[libraryWindow.layer setCornerRadius:WidgetRadius];
		libraryWindow.layer.masksToBounds = YES;
		libraryWindow.layer.borderColor = [UIColor blackColor].CGColor;
		libraryWindow.layer.borderWidth = 0.4f;
		[add addSubview:libraryWindow];

		blurView = [UIView new];
		blurView.frame = CGRectMake(0, 0, springboardWindow.frame.size.width + 5, (WidgetWidth/2.5) + 5);
		[controller.view addSubview:blurView];
		
		artworkViewBlur = [UIImageView new];
		artworkViewBlur.frame = blurView.frame;
		
		
		[add addSubview:controller.view];
		[springboardWindow makeKeyAndVisible];
		
		if( (objc_getClass("UIBlurEffect") != nil && objc_getClass("UIVisualEffectView") != nil)) {
			UIBlurEffect *blur = [objc_getClass("UIBlurEffect") effectWithStyle:(UIBlurEffectStyle)Blur];
			effectView = [[objc_getClass("UIVisualEffectView") alloc]initWithEffect:blur];
		} else {
			effectView = (UIVisualEffectView *)[UIView new];
		}
		effectView.alpha = 1.0f;
		effectView.frame = blurView.frame;
		[blurView addSubview:effectView];

		artworkView = [UIImageView new];
		artworkView.frame = CGRectMake((springboardWindow.frame.size.width/36), (springboardWindow.frame.size.width/36), (WidgetWidth/2.5)-(springboardWindow.frame.size.width/19), (WidgetWidth/2.5)-(springboardWindow.frame.size.width/19));
		artworkView.layer.cornerRadius = ArtworkRadius;
		artworkView.layer.masksToBounds = YES;
		[artworkView setUserInteractionEnabled:YES];
		
		UITapGestureRecognizer *tapGestureLibrary = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlayingApplication:)];
		tapGestureLibrary.numberOfTapsRequired = 2;
		[artworkView addGestureRecognizer:tapGestureLibrary];
		
		UITapGestureRecognizer *artWorkTapOpenGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(libraryWindowToggle)];
		artWorkTapOpenGesture.numberOfTapsRequired = 1;
		[artworkView addGestureRecognizer:artWorkTapOpenGesture];
		
		
		
		if(objc_getClass("MPUSystemMediaControlsViewController") != nil) {
			controlsView = (MPUSystemMediaControlsViewController *)[objc_getClass("MPUSystemMediaControlsViewController") new];
		} else {
			controlsView = (MPUSystemMediaControlsViewController *)[UIViewController new];
		}
		
		controlsView.view.frame = FRAME_CONTROLVIEW;//CGRectMake(0, -15, mediaPlay.frame.size.width,  mediaPlay.frame.size.height);
		[controller.view addSubview:controlsView.view];
		
		[controller.view addSubview:artworkView];
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
		tapGesture.numberOfTapsRequired = 2;
		[controller.view addGestureRecognizer:tapGesture];
		
		
		
		
		UITapGestureRecognizer *tapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showWidPlayer)];
		tapGestureRecognizer2.numberOfTouchesRequired = 1;
		[controller.view addGestureRecognizer:tapGestureRecognizer2];
		
		//UILongPressGestureRecognizer* touchAndHoldRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hideWidPlayer:)]; 
		//touchAndHoldRecognizer.minimumPressDuration = 1.0;
		//[controller.view addGestureRecognizer:touchAndHoldRecognizer];
		
		
		lyricView = [UIView new];
		lyricView.frame = CGRectMake(springboardWindow.frame.size.width/20, springboardWindow.frame.size.height, springboardWindow.frame.size.width-((springboardWindow.frame.size.width/20)*2), 0);
		if( (objc_getClass("UIBlurEffect") != nil && objc_getClass("UIVisualEffectView") != nil)) {
			UIBlurEffect *blur = [objc_getClass("UIBlurEffect") effectWithStyle:(UIBlurEffectStyle)Blur];
			effectViewLiryc = [[objc_getClass("UIVisualEffectView") alloc]initWithEffect:blur];
		} else {
			effectViewLiryc = (UIVisualEffectView *)[UIView new];
		}
		effectViewLiryc.frame = CGRectMake(0, 0, springboardWindow.frame.size.width-((springboardWindow.frame.size.width/20)*2), 0);
		effectViewLiryc.alpha = 1.0f;
		[lyricView addSubview:effectViewLiryc];
		[lyricView.layer setCornerRadius:WidgetRadius];
		lyricView.layer.masksToBounds = YES;
		
		lirycLabel = [[UILabel alloc] initWithFrame:effectViewLiryc.frame];
		lirycLabel.textAlignment =  NSTextAlignmentCenter;
		lirycLabel.numberOfLines = 0;
		lirycLabel.lineBreakMode = (NSLineBreakMode)UILineBreakModeWordWrap;
		lirycLabel.textColor = [UIColor whiteColor];
		lirycLabel.backgroundColor = [UIColor clearColor];
		lirycLabel.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:(12.0)];
		[lyricView addSubview:lirycLabel];
		[add addSubview:lyricView];
	
        libraryWindow.frame = CGRectMake((WidgetWidth/20), (((WidgetWidth/2.5))-(WidgetWidth/36))+lyricView.frame.size.height, WidgetWidth, 0);
		
		
		[self registerForMusicPlayerNotifications];
		[self performSelectorInBackground:@selector(updateNowPlaying) withObject:nil];
		[self UpdateBlur];
		
		controlsView.view.frame = FRAME_CONTROLVIEW;
		
		if (MPUSystemMediaControlsView *MediaC = (MPUSystemMediaControlsView *)object_getIvar(controlsView, class_getInstanceVariable(objc_getClass("MPUSystemMediaControlsViewController"), "_mediaControlsView")) ) {
			
			[self fixTransportControls];
			
			if (MPUMediaControlsVolumeView* ControlsVolumeView1 = (MPUMediaControlsVolumeView *)object_getIvar(MediaC, class_getInstanceVariable(objc_getClass("MPUSystemMediaControlsView"), "_volumeView")) ) {
				if (UISlider* volumeSlider = (UISlider *)object_getIvar(ControlsVolumeView1, class_getInstanceVariable(objc_getClass("MPUMediaControlsVolumeView"), "_slider")) ) {
					[volumeSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];
				}
			} else if(UISlider* ControlsVolumeView2 = (UISlider *)object_getIvar(MediaC, class_getInstanceVariable(objc_getClass("MPUSystemMediaControlsView"), "_volumeSliderView")) ) {
				[ControlsVolumeView2 setThumbImage:[UIImage new] forState:UIControlStateNormal];
			}
			
			if (MPUNowPlayingTitlesView* TrackInfo = (MPUNowPlayingTitlesView *)object_getIvar(MediaC, class_getInstanceVariable(objc_getClass("MPUSystemMediaControlsView"), "_trackInformationView")) ) {
				if (UILabel *_titleLabel = (UILabel *)object_getIvar(TrackInfo, class_getInstanceVariable(objc_getClass("MPUNowPlayingTitlesView"), "_titleLabel")) ) {
					_titleLabel.font = [_titleLabel.font fontWithSize:((WidgetWidth/2.5)/8)];
				}
				if (UILabel *_detailLabel = (UILabel *)object_getIvar(TrackInfo, class_getInstanceVariable(objc_getClass("MPUNowPlayingTitlesView"), "_detailLabel")) ) {
					_detailLabel.font = [_detailLabel.font fontWithSize:((WidgetWidth/2.5)/10)];
				} else if (UILabel *_artistAlbumLabel = (UILabel *)object_getIvar(TrackInfo, class_getInstanceVariable(objc_getClass("MPUNowPlayingTitlesView"), "_artistAlbumLabel")) ) {
					_artistAlbumLabel.font = [_artistAlbumLabel.font fontWithSize:((WidgetWidth/2.5)/10)];
				}
				if ([TrackInfo respondsToSelector:@selector(setTitleLeading:)]) {
					[TrackInfo setTitleLeading:((WidgetWidth/2.5)/7)];
				}
			}
        }
	}
	return self;
}
- (NSString*)encodeBase64WithData:(NSData*)theData
{
	@autoreleasepool {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;

            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	}
}
-(NSString *)urlEncodeUsingEncoding:(NSString*)encoding
{
	static __strong NSString* kCodes = @"!*'\"();:@&=+$,/?%#[]% ";
	return (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)encoding, NULL, (CFStringRef)kCodes, CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
}
- (NSString *)hmacSHA1BinBase64:(NSString *)data withKey:(NSString *)key 
{
	@autoreleasepool {
		const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
		const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
		unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
		CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
		NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
		NSString *hash = [self encodeBase64WithData:HMAC];
		return hash;
	}
}
- (void)parseLirycs
{
	if(!WidPlayerLyrics) {
		lyricView.alpha = 0;
		return;
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	lyricView.alpha = 1;
	lirycLabel.text = @"Loading...";
	lirycTimeArray = nil;
	

	__block NSString* artist = [NSString string];
	__block	NSString* album = [NSString string];
	__block	NSString* album_artist = [NSString string];
	__block	NSString* track = [NSString string];
	__block	NSString* duration = [NSString string];

	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
		
	@try {
		
		@autoreleasepool {
			__autoreleasing NSData* artwork = [(__bridge NSDictionary *)result objectForKey:(NSData *)(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData]?:[NSData data];
			artworkView.image = [[[UIImage imageWithData:artwork] imageWithSize:CGSizeMake((WidgetWidth/2.5), (WidgetWidth/2.5))]?:isPlayingSBApp?[UIImage iconWithSBApplication:isPlayingSBApp]:kNoArtwork copy];
		}
		if (Blur == 4) {
			@autoreleasepool {
				artworkViewBlur.image = [[[UIImage new] blurredImageWithImage:artworkView.image] copy];
			}
		}
		
		if(result) {
			artist = [[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist]?:[NSString string] copy];
			album = [[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoAlbum]?:[NSString string] copy];
			album_artist = [[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist]?:[NSString string] copy];
			track = [[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle]?:[NSString string] copy];
			duration = [[[(__bridge NSDictionary *)result objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoDuration] stringValue]?:[NSString string] copy];
		
		
		static __strong NSString* token = @"160203df69efabfaf0b50f2b7b82aaad0206ce701d1c55895ec22f";
		static __strong NSString* sigFormat = @"&signature=%@&signature_protocol=sha1";
		static __strong NSString* urlFormat = @"https://apic.musixmatch.com/ws/1.1/macro.subtitles.get?app_id=mac-ios-v2.0&usertoken=%@&q_duration=%@&tags=playing&q_album_artist=%@&q_track=%@&q_album=%@&page_size=1&subtitle_format=mxm&f_subtitle_length_max_deviation=1&user_language=pt&f_tracking_url=html&f_subtitle_length=%@&track_fields_set=ios_track_list&q_artist=%@&format=json";
		
		NSString* prepareString = [NSString stringWithFormat:urlFormat, token, duration, [self urlEncodeUsingEncoding:album_artist], [self urlEncodeUsingEncoding:track], [self urlEncodeUsingEncoding:album], duration, [self urlEncodeUsingEncoding:artist]];
		
		__block NSURL* UrlString = [NSURL URLWithString:[prepareString stringByAppendingString:[NSString stringWithFormat:sigFormat, [self urlEncodeUsingEncoding:[self hmacSHA1BinBase64:[prepareString stringByAppendingString:@"20160203"] withKey:@"secretsuper"]]]]];
		
		if(UrlString != nil) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		@try {
		NSError *error = nil;
		NSHTTPURLResponse *responseCode = nil;
		NSMutableURLRequest *Request = [[NSMutableURLRequest alloc]	initWithURL:UrlString cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
		[Request setHTTPMethod:@"GET"];
		[Request setValue:@"default" forHTTPHeaderField:@"Cookie"];
		[Request setValue:@"default" forHTTPHeaderField:@"x-mxm-endpoint"];
		[Request setValue:@"Musixmatch/6.0.1 (iPhone; iOS 9.2.1; Scale/2.00)" forHTTPHeaderField:@"User-Agent"];
		NSData *receivedData = [NSURLConnection sendSynchronousRequest:Request returningResponse:&responseCode error:&error];
		if(receivedData && !error) {
			NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:receivedData?:[NSData data] options:NSJSONReadingMutableContainers error:nil];
			NSArray* subtitle = [[[[[[[JSON objectForKey:@"message"] objectForKey:@"body"] objectForKey:@"macro_calls"] objectForKey:@"track.subtitles.get"] objectForKey:@"message"] objectForKey:@"body"] objectForKey:@"subtitle_list"];
			NSString* subtitle_body = [[subtitle[0] objectForKey:@"subtitle"] objectForKey:@"subtitle_body"];
			subtitle_body = [subtitle_body stringByReplacingOccurrencesOfString:@"\\\"" withString:@""]; /* " */
			NSData* liry = [subtitle_body dataUsingEncoding:NSUTF8StringEncoding];
			id Lyric_here = [NSJSONSerialization JSONObjectWithData:liry?:[NSData data] options:NSJSONReadingMutableContainers error:nil];
			if(Lyric_here) {
				lirycTimeArray = [Lyric_here copy];
				dispatch_async(dispatch_get_main_queue(), ^(){
					[NSObject cancelPreviousPerformRequestsWithTarget:self];
					lirycLabel.text = @"...";
					lyricView.alpha = 1;
					[self playbackStatus];
				});
			} else {
				dispatch_async(dispatch_get_main_queue(), ^(){
					[NSObject cancelPreviousPerformRequestsWithTarget:self];
					lirycLabel.text = @"...";
					lyricView.alpha = 0;
					[self playbackStatus];
				});
			}
		}
		if(error != nil) {
			dispatch_async(dispatch_get_main_queue(), ^(){
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				lirycLabel.text = [error localizedDescription];
				lyricView.alpha = 1;
			});
		}
		} @catch (NSException * e) {
			dispatch_async(dispatch_get_main_queue(), ^(){
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				lirycLabel.text = [NSString string];
				lyricView.alpha = 0;
			});
		}
		});
		}
	
	} else {
		dispatch_async(dispatch_get_main_queue(), ^(){
		lyricView.alpha = 0;
		lirycLabel.text = [NSString string];
		lirycTimeArray = nil;
		});
	}
    } @catch (NSException * e) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		lirycLabel.text = [NSString string];
		lyricView.alpha = 0;
	}		
	});
}
static __strong NSString* kTimeString = @"time";
static __strong NSString* kTotalString = @"total";
static __strong NSString* kTextString = @"text";
- (void)mapTimeLyric
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
		if(!lirycTimeArray || (lirycTimeArray&&[lirycTimeArray count]==0) ){
			lirycLabel.text = [NSString string];
			lyricView.alpha = 0;
			return;
		}
		
		MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
		@try {
		@autoreleasepool {
		double timeCurrent = [[(__bridge NSDictionary *)result objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoElapsedTime] doubleValue];
		int getIndexNextTimeLiryc = 0;
		for(NSDictionary* subtitle in lirycTimeArray) {
			getIndexNextTimeLiryc++;
			if(timeCurrent < [[[subtitle objectForKey:kTimeString] objectForKey:kTotalString] doubleValue]) {
				getIndexNextTimeLiryc--;
				indexNextTimeLiryc = getIndexNextTimeLiryc;
				if(indexNextTimeLiryc == 0) {
					nextTimeLiryc = [[[lirycTimeArray[indexNextTimeLiryc] objectForKey:kTimeString] objectForKey:kTotalString] doubleValue]-timeCurrent;
					lirycLabel.text = [lirycTimeArray[indexNextTimeLiryc] objectForKey:kTextString];
					[self performSelector:@selector(updateNextLiryc) withObject:self afterDelay:nextTimeLiryc];
					return;
				}
				nextTimeLiryc = [[[subtitle objectForKey:kTimeString] objectForKey:kTotalString] doubleValue]-timeCurrent;
				lirycLabel.text = [lirycTimeArray[indexNextTimeLiryc-1] objectForKey:kTextString];
				[self performSelector:@selector(updateNextLiryc) withObject:self afterDelay:nextTimeLiryc];
				return;
			}
		}
		}
		} @catch (NSException * e) {
			lirycLabel.text = [NSString string];
			lyricView.alpha = 0;
			return;
		}
		});
	
}

- (void)updateNextLiryc
{
	@try {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(!lirycTimeArray||!WidPlayerLyrics||(lirycTimeArray&&[lirycTimeArray count]==0)) {
		lyricView.alpha = 0;
		return;
	}
	
	lyricView.alpha = 1;
	lirycLabel.text = [lirycTimeArray[indexNextTimeLiryc] objectForKey:kTextString];
	
	CGRect currentFrame = lirycLabel.frame;
	CGSize max = CGSizeMake(lirycLabel.frame.size.width, 500);
	CGSize expected = [lirycLabel.text sizeWithFont:lirycLabel.font constrainedToSize:max lineBreakMode:lirycLabel.lineBreakMode]; 
	currentFrame.size.height = expected.height+10;
	
	//[UIView animateWithDuration:0.2/1.5 animations:^{
	lyricView.frame = CGRectMake(lyricView.frame.origin.x, lyricView.frame.origin.y, lyricView.frame.size.width, currentFrame.size.height);
	effectViewLiryc.frame = currentFrame;
	lirycLabel.frame = currentFrame;
	//} completion:nil];
	
	indexNextTimeLiryc++;
	
	if(indexNextTimeLiryc > [lirycTimeArray count]-1) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		lirycLabel.text = [NSString string];
		lyricView.alpha = 0;
		return;
	}
	
	nextTimeLiryc = [[[lirycTimeArray[indexNextTimeLiryc] objectForKey:kTimeString] objectForKey:kTotalString]  doubleValue]-[[[lirycTimeArray[indexNextTimeLiryc-1] objectForKey:kTimeString] objectForKey:kTotalString] doubleValue];
	[self performSelector:@selector(updateNextLiryc) withObject:self afterDelay:nextTimeLiryc];
	
	} @catch (NSException * e) {
		lirycLabel.text = [NSString string];
		lyricView.alpha = 0;
	}
}
- (void)playbackStatus
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	if(YES) {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
		if(result) {
			MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_main_queue(), ^(Boolean isPlayingNow){
				if(isPlayingNow) {
					[self mapTimeLyric];
				} else {
					[NSObject cancelPreviousPerformRequestsWithTarget:self];
				}
				dispatch_semaphore_signal(semaphore);
			});			
		} else {
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			indexNextTimeLiryc = 0;
			dispatch_semaphore_signal(semaphore);
		}
	});
	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)));
	});
	}
}

- (void)libraryWindowShow
{
	if (!mediaPicker) {
		if(objc_getClass("MPMediaPickerController") != nil) {
			mediaPicker = [[objc_getClass("MPMediaPickerController") alloc] initWithMediaTypes:MPMediaTypeAny];
			mediaPicker.delegate = (id<MPMediaPickerControllerDelegate>)self;
			mediaPicker.allowsPickingMultipleItems = YES;
		} else {
			mediaPicker = (MPMediaPickerController *)[UIViewController new];
		}		
		mediaPicker.view.frame =  CGRectMake(0, 0, libraryWindow.frame.size.width, (libraryWindow.frame.size.height*2.5) );
		mediaPicker.view.layer.masksToBounds = YES;
		UIView *addLibrary = (UIView *)libraryWindow;
		[addLibrary addSubview:mediaPicker.view];
	}
	libraryWindow.frame = CGRectMake((WidgetWidth/20), (((WidgetWidth/2.5))- (WidgetWidth/36))+lyricView.frame.size.height, WidgetWidth-((WidgetWidth/20)*2), 0 );
	mediaPicker.view.layer.cornerRadius = springboardWindow.layer.cornerRadius;
	[UIView animateWithDuration:0.5/1.5 animations:^{
		[libraryWindow setHidden:NO];
		libraryWindow.frame = CGRectMake((WidgetWidth/20), (((WidgetWidth/2.5))- (WidgetWidth/36))+lyricView.frame.size.height, WidgetWidth-((WidgetWidth/20)*2), ((WidgetWidth/2.5)*2.5) );//CGRectMake(/*springboardWindow.frame.origin.x+*/(springboardWindow.frame.size.width/20), (((WidgetWidth/2.5)/*+springboardWindow.frame.origin.y*/)-(springboardWindow.frame.size.width/36))+lyricView.frame.size.height, springboardWindow.frame.size.width-((springboardWindow.frame.size.width/20)*2), ((WidgetWidth/2.5)*2.5) );
	} completion:nil];
}
- (void)libraryWindowHide
{
	if(libraryWindow.hidden) {
		return;
	}
	[UIView animateWithDuration:0.5/1.5 animations:^{
		libraryWindow.frame = CGRectMake((WidgetWidth/20), (((WidgetWidth/2.5))- (WidgetWidth/36))+lyricView.frame.size.height, WidgetWidth-((WidgetWidth/20)*2), 0 );
	} completion:^(BOOL finished) {
		[libraryWindow setHidden:YES];
	}];
}
- (void)libraryWindowToggle
{
	if(springboardWindow.alpha < 1) {
		[self showWidPlayer];
		return;
	}
	if(libraryWindow.hidden) {
		[self libraryWindowShow];
	} else {
		[self libraryWindowHide];
	}
}

- (void)showWidPlayer
{
	if(springboardWindow.alpha < 1) {
		[UIView animateWithDuration:0.3/1.5 animations:^{
			CGRect frame = springboardWindow.frame;
			if(springboardWindow.isLandscape) {
				frame.origin.y = ( (springboardWindow.HeightMax/2) - ( WidgetWidth/2) );
			} else {
				frame.origin.x = ( (springboardWindow.WidthMax/2) - (WidgetWidth/2) );
			}
			springboardWindow.frame = frame;
			springboardWindow.alpha = 1;
			[self libraryWindowHide];
		}];
	}
}
- (void)hideWidPlayer:(id)handle
{
	if(springboardWindow.alpha >= 1) {
		[UIView animateWithDuration:0.3/1.5 animations:^{
			int Borda = (WidgetWidth/2.3);
			CGRect frame = springboardWindow.frame;
			
			if(springboardWindow.isLandscape) {
				frame.origin.y = springboardWindow.frame.origin.y<=0? 0-(Borda*2.1):((springboardWindow.HeightMax)+(WidgetWidth) )-(Borda*2.5);
			} else {
				frame.origin.x = springboardWindow.frame.origin.x<=0? 0-(Borda*2.1):((springboardWindow.WidthMax)+WidgetWidth)-(Borda*2.5);
			}
			springboardWindow.frame = frame;
			if(handle != nil) {
				springboardWindow.alpha = 0.3;
				[self libraryWindowHide];
			}			
		}];
	}
}
- (void)UpdateFrame
{
	@autoreleasepool {
		[UIView animateWithDuration:0.3/2 animations:^{
			springboardWindow.alpha = 1.0;
			
			springboardWindow.frame = CGRectMake(20, 60, WidgetWidth, WidgetWidth/2.5);
			
			CGRect WidSize = CGRectMake(0, 0, springboardWindow.frame.size.width, (WidgetWidth/2.5));
			controller.view.frame = WidSize;

			blurView.frame = CGRectMake(0, 0, springboardWindow.frame.size.width + 5, (WidgetWidth/2.5) + 5);

			artworkViewBlur.frame = CGRectMake(0, 0, springboardWindow.frame.size.width + 5, (WidgetWidth/2.5) + 5);

			effectView.frame = CGRectMake(0, 0, springboardWindow.frame.size.width + 5, (WidgetWidth/2.5) + 5);

			//shadowPath = [UIBezierPath bezierPathWithRoundedRect:springboardWindow.bounds cornerRadius:WidgetRadius];
			//springboardWindow.layer.shadowPath = shadowPath.CGPath;

			artworkView.frame = CGRectMake((springboardWindow.frame.size.width/36), (springboardWindow.frame.size.width/36), WidSize.size.height-(springboardWindow.frame.size.width/19), WidSize.size.height-(springboardWindow.frame.size.width/19));

			controlsView.view.frame = FRAME_CONTROLVIEW;
			
			libraryWindow.frame = CGRectMake((WidgetWidth/20), ((WidgetWidth/2.5))-(WidgetWidth/36),WidgetWidth-((WidgetWidth/20)*2), 0);
			
			lyricView.frame = CGRectMake(springboardWindow.frame.size.width/20, springboardWindow.frame.size.height, springboardWindow.frame.size.width-((springboardWindow.frame.size.width/20)*2), lyricView.frame.size.height);
			effectViewLiryc.frame = CGRectMake(0, 0, springboardWindow.frame.size.width-((springboardWindow.frame.size.width/20)*2), effectViewLiryc.frame.size.height);
			lirycLabel.frame = CGRectMake(0, 0, springboardWindow.frame.size.width-((springboardWindow.frame.size.width/20)*2), lirycLabel.frame.size.height);
			
			if (MPUSystemMediaControlsView *MediaC = (MPUSystemMediaControlsView *)object_getIvar(controlsView, class_getInstanceVariable(objc_getClass("MPUSystemMediaControlsViewController"), "_mediaControlsView")) ) {
				if (MPUNowPlayingTitlesView* TrackInfo = (MPUNowPlayingTitlesView *)object_getIvar(MediaC, class_getInstanceVariable(objc_getClass("MPUSystemMediaControlsView"), "_trackInformationView")) ) {
					if (UILabel *_titleLabel = (UILabel *)object_getIvar(TrackInfo, class_getInstanceVariable(objc_getClass("MPUNowPlayingTitlesView"), "_titleLabel")) ) {
						_titleLabel.font = [_titleLabel.font fontWithSize:((WidgetWidth/2.5)/8)];
					}
					if (UILabel *_detailLabel = (UILabel *)object_getIvar(TrackInfo, class_getInstanceVariable(objc_getClass("MPUNowPlayingTitlesView"), "_detailLabel")) ) {
						_detailLabel.font = [_detailLabel.font fontWithSize:((WidgetWidth/2.5)/10)];
					} else if (UILabel *_artistAlbumLabel = (UILabel *)object_getIvar(TrackInfo, class_getInstanceVariable(objc_getClass("MPUNowPlayingTitlesView"), "_artistAlbumLabel")) ) {
						_artistAlbumLabel.font = [_artistAlbumLabel.font fontWithSize:((WidgetWidth/2.5)/10)];
					}
					if ([TrackInfo respondsToSelector:@selector(setTitleLeading:)]) {
						[TrackInfo setTitleLeading:((WidgetWidth/2.5)/7)];
					}
				}
			}
			
		} completion:nil];
	}
}
- (void)UpdateRadius
{
	@autoreleasepool {
		[springboardWindow.layer setCornerRadius:WidgetRadius];
		//shadowPath = [UIBezierPath bezierPathWithRoundedRect:springboardWindow.bounds cornerRadius:WidgetRadius];
		//springboardWindow.layer.shadowPath = shadowPath.CGPath;
		[controller.view.layer setCornerRadius:WidgetRadius];
		[artworkView.layer setCornerRadius:ArtworkRadius];
		[libraryWindow.layer setCornerRadius:WidgetRadius];
		[lyricView.layer setCornerRadius:WidgetRadius];
	}
}
- (void)UpdateBlur
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^(){
		@autoreleasepool {
			[effectView removeFromSuperview];
			[effectViewLiryc removeFromSuperview];
			
			UIBlurEffect *blur;
			UIBlurEffect *blurLir;
			int blurArt = 1;
			if( (objc_getClass("UIBlurEffect") != nil && objc_getClass("UIVisualEffectView") != nil)) {
				blur = [objc_getClass("UIBlurEffect") effectWithStyle:Blur==4?UIBlurEffectStyleLight:(UIBlurEffectStyle)Blur];
				effectView = [objc_getClass("UIVisualEffectView") new];
				
				blurLir = [objc_getClass("UIBlurEffect") effectWithStyle:Blur==4?UIBlurEffectStyleLight:(UIBlurEffectStyle)Blur];
				effectViewLiryc = [objc_getClass("UIVisualEffectView") new];
				
				blurArt = 4;
			} else {
				effectView = (UIVisualEffectView *)[UIView new];
				effectViewLiryc = (UIVisualEffectView *)[UIView new];
			}
			//[MSHookIvar<MPUMediaControlsTitlesView *>(MSHookIvar<MPUSystemMediaControlsView *>(controlsView, "_mediaControlsView"), "_trackInformationView") setHighlighted:(Blur == 2)];
			if (Blur == blurArt) {
				artworkViewBlur.image = [[[UIImage new] blurredImageWithImage:artworkView.image] copy];
				[effectView addSubview:artworkViewBlur];
			}
			if( (objc_getClass("UIBlurEffect") != nil && objc_getClass("UIVisualEffectView") != nil)) {
				effectView = [effectView initWithEffect:blur];
				effectViewLiryc = [effectViewLiryc initWithEffect:blurLir];
			}
			effectView.alpha = 1.0;
			effectView.frame = blurView.frame;
			[blurView addSubview:effectView];
			
			effectViewLiryc.alpha = 1.0;
			effectViewLiryc.frame = lyricView.frame;
			[lyricView addSubview:effectViewLiryc];
			[lirycLabel removeFromSuperview];
			[lyricView addSubview:lirycLabel];
		}
	}];
}
- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
	if (sender.state == UIGestureRecognizerStateRecognized) {
		Blur++;
		int BlurArt = 2;
		if( (objc_getClass("UIBlurEffect") != nil && objc_getClass("UIVisualEffectView") != nil)) {
			BlurArt = 5;
		}
		if (Blur >= BlurArt) {
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
- (void)openPlayingApplication:(id)__unused sender
{
	if(springboardWindow.alpha < 1) {
		[self showWidPlayer];
		return;
	}
    MRMediaRemoteGetNowPlayingApplicationPID(dispatch_get_main_queue(), ^(int PID) {
		@try {
			SBUIController* uicontroller = [objc_getClass("SBUIController") sharedInstance];
			if ([uicontroller respondsToSelector:@selector(activateApplicationAnimated:)]) {
				[uicontroller activateApplicationAnimated:[[objc_getClass("SBApplicationController") sharedInstance] applicationWithPid:PID]];
			} else if ([uicontroller respondsToSelector:@selector(activateApplication:)]) {
				[uicontroller activateApplication:[[objc_getClass("SBApplicationController") sharedInstance] applicationWithPid:PID]];
			}
		} @catch (NSException * e) {
			
		}
	});
}
- (void)registerForMusicPlayerNotifications
{
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(updateNowPlaying) name:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification object:nil];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), lockScreenState, CFSTR("com.apple.springboard.lockstate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
void lockScreenState(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@autoreleasepool {
		int token;
		uint64_t state;
		notify_register_check("com.apple.springboard.lockstate", &token);
		notify_get_state(token, &state);
		notify_cancel(token);
		if ([WidPlayer sharedInstanceExist]) {
			if(WidPlayer *wid = [WidPlayer sharedInstance]) {
				if(!state) {
					wid.springboardWindow.windowLevel = 9999999999;
				}
				[[wid widgetWindow] setHidden:(BOOL)state];
				//[[wid widgetWindow] setHidden:NO];
				if(!wid.libraryWindow.hidden) {
					[wid libraryWindowHide];
				}
				if ( !(WidPlayerHideNoPlaying&&WidPlayerEnabled)) {
					return;
				}
				MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
					if(!result) {
						[[[WidPlayer sharedInstance] widgetWindow] setHidden:YES];
					}
				});
			}			
		}
	}
}
- (void)fixTransportControls
{
	if (MPUSystemMediaControlsView *MediaC = (MPUSystemMediaControlsView *)object_getIvar(controlsView, class_getInstanceVariable(%c(MPUSystemMediaControlsViewController), "_mediaControlsView")) ) {
		if ([MediaC respondsToSelector:@selector(transportControlsView)]) {
			if ([MediaC.transportControlsView respondsToSelector:@selector(minimumNumberOfTransportButtonsForLayout)]) {
				if(MediaC.transportControlsView.minimumNumberOfTransportButtonsForLayout < 5) {
					MediaC.transportControlsView.minimumNumberOfTransportButtonsForLayout = 5;
				}
			}
		}
	}
}
- (void)updateNowPlaying
{
	if (!kNoArtwork) {
		unsigned char MaskForBlurData[] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x01, 0x90, 0x00, 0x00, 0x01, 0x90, 0x04, 0x03, 0x00, 0x00, 0x00, 0x72, 0x91, 0x2B, 0xFF, 0x00, 0x00, 0x00, 0x18, 0x50, 0x4C, 0x54, 0x45, 0xFF, 0xFF, 0xFF, 0xEF, 0xEF, 0xEF, 0xF9, 0xF9, 0xF9, 0xF5, 0xF5, 0xF5, 0xFB, 0xFB, 0xFB, 0xFD, 0xFD, 0xFD, 0xF3, 0xF3, 0xF3, 0xF7, 0xF7, 0xF7, 0x95, 0x78, 0xF6, 0xDC, 0x00, 0x00, 0x04, 0x99, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0xEC, 0xDD, 0x41, 0x4F, 0xDB, 0x30, 0x18, 0xC6, 0xF1, 0x77, 0x59, 0xDC, 0x5E, 0xF7, 0xAE, 0x23, 0x5C, 0x29, 0x6C, 0xE3, 0xBA, 0x54, 0x1B, 0x5C, 0xCB, 0x50, 0xD7, 0x6B, 0x8A, 0x58, 0x7B, 0xC5, 0x42, 0x13, 0x57, 0x3A, 0x58, 0x3F, 0xFF, 0x6A, 0x18, 0x52, 0xC9, 0x90, 0x83, 0x1C, 0x08, 0xF6, 0xC3, 0xF3, 0xBF, 0x73, 0xF8, 0x91, 0xFA, 0x8D, 0x63, 0x44, 0x2A, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x18, 0x63, 0x8C, 0x31, 0xC6, 0x9E, 0xAE, 0x9F, 0x95, 0x00, 0x64, 0xF6, 0x54, 0x8B, 0x1D, 0x49, 0x3D, 0x33, 0xB5, 0xBA, 0xAE, 0x90, 0xC4, 0x3B, 0x29, 0xF5, 0xB6, 0x33, 0x49, 0xB9, 0xAC, 0xD4, 0xBB, 0xDE, 0x4B, 0xBA, 0xE5, 0x2B, 0xBD, 0x2D, 0xED, 0xCF, 0x96, 0xD9, 0xD3, 0x7B, 0xA5, 0x3A, 0xB8, 0xA6, 0x5A, 0x6B, 0x2C, 0x29, 0x36, 0xB5, 0x5A, 0x2F, 0xC5, 0x01, 0x7C, 0xB2, 0x66, 0x00, 0x40, 0xF2, 0x03, 0x55, 0x00, 0x88, 0x59, 0xA9, 0x02, 0x40, 0xDC, 0xA8, 0x42, 0x80, 0x1C, 0x5B, 0x45, 0x80, 0x2C, 0xD6, 0x0C, 0x00, 0x88, 0xDB, 0x55, 0x01, 0x40, 0x4E, 0x57, 0xAA, 0x00, 0x10, 0x37, 0xAA, 0x00, 0x20, 0x66, 0xCF, 0x2A, 0x00, 0xE4, 0xE6, 0xC9, 0x09, 0x00, 0xE2, 0xD6, 0x38, 0x00, 0x24, 0x5B, 0x33, 0x00, 0x20, 0xEE, 0xC9, 0x09, 0x00, 0xE2, 0xB6, 0x23, 0x08, 0x90, 0xA9, 0x2A, 0x02, 0x64, 0x6A, 0x15, 0x01, 0xE2, 0x9E, 0x9C, 0x00, 0x20, 0xEE, 0xC9, 0x09, 0x00, 0xE2, 0xB6, 0x23, 0x00, 0x10, 0x37, 0xAA, 0x10, 0x20, 0xC7, 0x56, 0x11, 0x20, 0x8B, 0x35, 0x03, 0x00, 0xE2, 0x16, 0x07, 0x04, 0x64, 0xA9, 0x18, 0x90, 0xB9, 0x62, 0x40, 0x8C, 0x82, 0x40, 0xE6, 0x28, 0x10, 0x0B, 0x02, 0xC9, 0x14, 0x04, 0xF2, 0x06, 0x05, 0x32, 0x44, 0x81, 0x58, 0x14, 0x88, 0x82, 0x40, 0x0C, 0x0A, 0x24, 0x47, 0x81, 0x64, 0x84, 0x10, 0x72, 0x13, 0x21, 0x84, 0x10, 0xE2, 0x8F, 0x10, 0x42, 0x08, 0xF1, 0x47, 0x08, 0x21, 0xE0, 0x90, 0xC3, 0xDD, 0x15, 0x02, 0xE4, 0x62, 0x2C, 0x22, 0xF3, 0xE4, 0x21, 0xDB, 0x63, 0x71, 0x19, 0x9B, 0x36, 0x64, 0xF0, 0x49, 0xFE, 0xD5, 0x4B, 0x19, 0x52, 0x5C, 0x6F, 0xFC, 0x68, 0xC2, 0x90, 0x91, 0x6C, 0x96, 0x2C, 0x64, 0x54, 0xC9, 0xBD, 0x6C, 0x9A, 0x90, 0x8B, 0x89, 0xD4, 0x2A, 0x53, 0x84, 0x0C, 0x76, 0x44, 0x00, 0x20, 0x6E, 0x54, 0x01, 0x40, 0x8A, 0xEB, 0x4A, 0x00, 0x20, 0x85, 0x5B, 0xE3, 0x00, 0x90, 0x8B, 0x35, 0x03, 0x00, 0xE2, 0x46, 0x15, 0x00, 0xC4, 0xAD, 0x71, 0x00, 0x48, 0xF1, 0x47, 0x04, 0x00, 0xE2, 0x76, 0x55, 0x08, 0x90, 0x51, 0x25, 0x08, 0x10, 0x37, 0xAA, 0x00, 0x20, 0xE7, 0x63, 0x11, 0x00, 0x88, 0x1B, 0x55, 0x00, 0x10, 0x37, 0xAA, 0x00, 0x20, 0xC5, 0x57, 0x11, 0x04, 0xC8, 0xA8, 0x12, 0x04, 0x48, 0x31, 0x11, 0x41, 0x80, 0x14, 0x63, 0xC1, 0x80, 0xFC, 0x12, 0x0C, 0x48, 0x51, 0xA5, 0x0D, 0xE9, 0xDF, 0x41, 0xCE, 0x04, 0x04, 0x52, 0x81, 0x40, 0xB6, 0x25, 0x71, 0x48, 0xA6, 0xB7, 0x6D, 0xA1, 0x40, 0x2E, 0x51, 0x20, 0x63, 0x14, 0x88, 0x10, 0x12, 0x17, 0xA4, 0x20, 0x84, 0x10, 0x42, 0x08, 0x21, 0xC4, 0x1B, 0x21, 0xAF, 0xE4, 0x86, 0x48, 0x08, 0x21, 0xC2, 0xC5, 0xFE, 0x3A, 0xAE, 0x08, 0x21, 0x84, 0x10, 0x42, 0x08, 0x21, 0xFE, 0x08, 0x21, 0x84, 0x10, 0x7F, 0x84, 0x10, 0x42, 0x88, 0x3F, 0x42, 0x08, 0x21, 0xC4, 0x1F, 0x21, 0xAF, 0x05, 0x52, 0xA1, 0x40, 0x60, 0xAE, 0x48, 0x10, 0x24, 0xA6, 0x2F, 0x89, 0x20, 0x24, 0x56, 0x48, 0x45, 0x08, 0x21, 0x84, 0x10, 0x42, 0x88, 0x2F, 0x42, 0x08, 0x21, 0xC4, 0x1F, 0x21, 0x84, 0x10, 0xE2, 0x8F, 0x90, 0x06, 0xC8, 0x98, 0x10, 0x42, 0x08, 0x21, 0x84, 0x90, 0x80, 0x3A, 0x81, 0x98, 0xFD, 0x03, 0x5D, 0x77, 0x7E, 0x5D, 0x25, 0x0D, 0x31, 0x9F, 0x37, 0xDF, 0xF9, 0x92, 0x2E, 0x24, 0xB3, 0xBA, 0xD1, 0x60, 0x9C, 0x2A, 0x64, 0xF1, 0xDF, 0x3F, 0xF0, 0xA7, 0x09, 0x71, 0x8E, 0x5A, 0x97, 0x29, 0x42, 0x32, 0x7D, 0xA0, 0x9D, 0x04, 0x21, 0xA5, 0x3E, 0x50, 0x61, 0x93, 0x83, 0xFC, 0xD0, 0xCD, 0xE2, 0xFC, 0x36, 0xF0, 0xC7, 0x40, 0x16, 0x9A, 0x00, 0x24, 0x7F, 0xC4, 0x3B, 0x0A, 0x4B, 0x10, 0x48, 0x4F, 0x31, 0x20, 0xC6, 0x82, 0x40, 0xFA, 0x0A, 0x02, 0x19, 0x82, 0x40, 0x8C, 0x82, 0x40, 0x7A, 0x28, 0x90, 0x25, 0x08, 0xC4, 0x28, 0x08, 0xE4, 0x2D, 0x0A, 0x64, 0x86, 0x02, 0x59, 0xA2, 0x40, 0x14, 0x04, 0x92, 0x47, 0x0D, 0x39, 0xFD, 0xBE, 0xFB, 0x71, 0xF2, 0x38, 0x48, 0x3F, 0x5E, 0x48, 0x7E, 0xA5, 0xB7, 0x1D, 0x4E, 0x1E, 0x01, 0xE9, 0x45, 0x0B, 0xD9, 0xAB, 0xBD, 0x1F, 0x33, 0xF7, 0xBF, 0x3B, 0x68, 0x16, 0x29, 0x24, 0x2F, 0x75, 0xB3, 0x62, 0x27, 0x51, 0x48, 0x6E, 0xB5, 0xD6, 0x65, 0x03, 0x64, 0x18, 0x25, 0xC4, 0x39, 0xEA, 0x5D, 0xA7, 0x08, 0x29, 0xF5, 0x81, 0xFC, 0x90, 0x65, 0x8C, 0x90, 0xB9, 0x62, 0x40, 0x32, 0x05, 0x81, 0x94, 0xCF, 0x05, 0xA9, 0xA4, 0xD3, 0xE6, 0x1A, 0x02, 0x19, 0x46, 0x07, 0x31, 0x36, 0x08, 0x72, 0xA4, 0xCD, 0x49, 0xA7, 0xF5, 0xD4, 0x5F, 0xF8, 0x0D, 0xB1, 0x90, 0x4E, 0x2B, 0xC3, 0x20, 0x6F, 0xB4, 0xB1, 0x81, 0x74, 0x59, 0x5F, 0xC3, 0x20, 0x3D, 0x6D, 0xEC, 0xBD, 0x74, 0xD9, 0x51, 0x20, 0x24, 0xD3, 0xC6, 0xB6, 0xA4, 0xCB, 0x34, 0x10, 0x62, 0xB4, 0xB1, 0x33, 0xE9, 0xB0, 0xBE, 0x36, 0xF5, 0x45, 0x1E, 0xCE, 0xC6, 0xF5, 0x55, 0x6F, 0xB3, 0x60, 0xC8, 0x30, 0xAE, 0xE9, 0xBB, 0x6C, 0x86, 0x84, 0xFE, 0x0A, 0xB6, 0xA5, 0xCB, 0x34, 0x18, 0x92, 0x45, 0xB5, 0xD6, 0x33, 0x0D, 0x5D, 0xEC, 0x62, 0x6C, 0x4C, 0x4B, 0xA4, 0x17, 0x7A, 0x45, 0x9A, 0x07, 0x77, 0x51, 0x49, 0x87, 0xCD, 0x5A, 0x40, 0xFA, 0x11, 0x7D, 0xB2, 0x64, 0xD8, 0xE6, 0x6E, 0x60, 0xE3, 0xF9, 0x64, 0x49, 0xD9, 0x06, 0x32, 0x8B, 0x67, 0x66, 0x89, 0xB6, 0x81, 0xE4, 0xEA, 0xE9, 0x9B, 0xF8, 0x8A, 0x0B, 0x22, 0xC3, 0x68, 0xB6, 0xF0, 0xA6, 0x1D, 0x24, 0xF3, 0x8D, 0x88, 0x4E, 0xCB, 0xB5, 0xB9, 0x77, 0x21, 0x5B, 0xE7, 0xED, 0x4A, 0xBC, 0xC5, 0x06, 0x31, 0x36, 0x92, 0xF3, 0x93, 0xAC, 0x25, 0x44, 0x16, 0x51, 0xAC, 0xF4, 0xB6, 0x57, 0xC4, 0x75, 0xF4, 0xF2, 0x8F, 0x86, 0xA1, 0x90, 0xE6, 0xED, 0xF3, 0xA0, 0x92, 0xAE, 0x33, 0xED, 0x21, 0xA6, 0x8C, 0xC0, 0x11, 0x76, 0x1F, 0xA9, 0x4B, 0x96, 0x11, 0x38, 0x6A, 0x90, 0xB0, 0x3B, 0x82, 0x39, 0xD6, 0x8D, 0x46, 0xF2, 0x22, 0x95, 0x41, 0xCF, 0x23, 0xF5, 0xF2, 0x95, 0xDD, 0xF8, 0xF3, 0xE3, 0x8B, 0x34, 0x7C, 0xAA, 0x03, 0xDC, 0xD3, 0xFD, 0xAB, 0xC3, 0xDF, 0x13, 0x79, 0xB1, 0x66, 0xB1, 0x1D, 0xE0, 0x86, 0xD6, 0x8B, 0xEC, 0xDC, 0xF3, 0x19, 0x6F, 0xED, 0x1F, 0x24, 0x8D, 0xE2, 0x3A, 0x2E, 0x6C, 0x51, 0x19, 0xD5, 0x71, 0x61, 0xAB, 0xD5, 0x1E, 0xD3, 0x59, 0xC8, 0xDF, 0x76, 0xEE, 0x18, 0x05, 0x61, 0x20, 0x88, 0x02, 0xE8, 0x20, 0xA8, 0xB5, 0x4D, 0x7A, 0x8F, 0x90, 0xC6, 0x13, 0x08, 0xD6, 0x16, 0x89, 0xB5, 0x82, 0xBD, 0xF7, 0xAF, 0x44, 0x08, 0x16, 0x42, 0x6C, 0x36, 0x81, 0x9D, 0xE5, 0xBD, 0x1B, 0x0C, 0x3B, 0x33, 0xB0, 0x7F, 0x61, 0x0B, 0xEC, 0x1B, 0x19, 0x91, 0x29, 0x0A, 0xA9, 0xE6, 0xA6, 0x57, 0xE0, 0x5A, 0xD3, 0x7B, 0x66, 0x89, 0x4D, 0x23, 0x9D, 0x15, 0xD1, 0xB7, 0xB0, 0xB3, 0x3E, 0xC6, 0x7A, 0x52, 0xB6, 0xF5, 0xC6, 0xFD, 0x15, 0x99, 0xEC, 0x1A, 0x39, 0x90, 0x88, 0xBE, 0x85, 0x09, 0xF9, 0x17, 0x41, 0x3C, 0x23, 0x9B, 0xB1, 0x8A, 0xB4, 0x70, 0x09, 0xC7, 0x1A, 0xD2, 0xC2, 0x25, 0x6C, 0xFB, 0xFC, 0x03, 0x32, 0x53, 0x49, 0x97, 0x6B, 0xF3, 0xCE, 0xA6, 0x53, 0x5D, 0xC6, 0xBE, 0x9A, 0xDC, 0xEE, 0x87, 0xAF, 0x47, 0xA4, 0x76, 0x39, 0x4D, 0xDF, 0x1D, 0x24, 0x5C, 0x57, 0xBF, 0x86, 0xF3, 0xD0, 0x40, 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x35, 0x79, 0x03, 0xE4, 0x9B, 0xC4, 0xE4, 0x4C, 0x1C, 0x87, 0x37, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82};
		__autoreleasing NSData* noArt_data = [NSData dataWithBytes:MaskForBlurData length:sizeof(MaskForBlurData)];
		kNoArtwork = [[[UIImage imageWithData:noArt_data] imageWithSize:CGSizeMake((WidgetWidth/2.5), (WidgetWidth/2.5))] copy];
	}
	[self fixTransportControls];
	[self performSelectorInBackground:@selector(updateNowPlayingStatus) withObject:nil];
	[self parseLirycs];
}
- (void)updateNowPlayingStatus
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^(){
		MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
			[self fixTransportControls];
			if (WidPlayerHideNoPlaying&&WidPlayerEnabled) {
				[[[WidPlayer sharedInstance] widgetWindow] setHidden:!result];
			}
		});
		MRMediaRemoteGetNowPlayingApplicationPID(dispatch_get_main_queue(), ^(int PID) {
			@try {
				[self fixTransportControls];
				if (SBApplicationController* sbcontroller = [objc_getClass("SBApplicationController") sharedInstance]) {
					isPlayingSBApp = [sbcontroller applicationWithPid:PID]?:nil;
				}
			} @catch (NSException * e) {
				isPlayingSBApp = nil;
			}
		});		
	}];
}
- (void)mediaPicker:(MPMediaPickerController *)__unused mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    if (mediaItemCollection) {
	    MPMusicPlayerController* musicPlayer = [objc_getClass("MPMusicPlayerController") iPodMusicPlayer];
        [musicPlayer setQueueWithItemCollection:mediaItemCollection];
        [musicPlayer play];
    }
	[self libraryWindowHide];
} 
- (void)mediaPickerDidCancel:(MPMediaPickerController *)__unused mediaPicker
{
	[self libraryWindowHide];
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
	    if (Class la = objc_getClass("LAActivator")) {
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
	if([WidPlayer sharedInstanceExist]) {
		if (WidPlayer* WidShared = [WidPlayer sharedInstance]) {
			[WidShared.widgetWindow setHidden:!WidShared.widgetWindow.hidden];
			WidShared.widgetWindow.alpha = 1.0;
			WidShared.widgetWindow.frame = CGRectMake(20, 60, WidgetWidth, WidgetWidth/2.5);			
			if(!WidShared.libraryWindow.hidden) {
				[WidShared libraryWindowHide];
			}
		}		
	}
}
@end


static void settingsChangedWidPlayer(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{	
	@autoreleasepool {		
		NSDictionary *WidPlayerPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary] copy];
		
		WidPlayerEnabled = (BOOL)[[WidPlayerPrefs objectForKey:@"Enabled"]?:@YES boolValue];
		WidPlayerLyrics = (BOOL)[[WidPlayerPrefs objectForKey:@"Lyrics"]?:@YES boolValue];
		int newWidPlayerHideNoPlaying = (BOOL)[[WidPlayerPrefs objectForKey:@"HideNoPlaying"]?:@NO boolValue];
		Blur = (int)[[WidPlayerPrefs objectForKey:@"Blur"]?:objc_getClass("UIBlurEffect")!=nil&&objc_getClass("UIVisualEffectView")!=nil?@4:@1 intValue];
		int newWidgetWidth = (int)[[WidPlayerPrefs objectForKey:@"WidgetWidth"]?:@(250) intValue];
		if (newWidgetWidth < 200) {
			newWidgetWidth = 200;
		}
		int newWidgetRadius = (int)[[WidPlayerPrefs objectForKey:@"WidgetRadius"]?:@10 intValue];
		int newArtworkRadius = (int)[[WidPlayerPrefs objectForKey:@"ArtworkRadius"]?:@10 intValue];
		WidgetOriginX = (float)[[WidPlayerPrefs objectForKey:@"x"]?:@(0-(newWidgetWidth-(newWidgetWidth/15))) floatValue];
		WidgetOriginY = (float)[[WidPlayerPrefs objectForKey:@"y"]?:@(60) floatValue];
		if ([WidPlayer sharedInstanceExist]) {
			WidPlayer* WPShared = [WidPlayer sharedInstance];
			[[WPShared widgetWindow] setHidden:!WidPlayerEnabled];
			if(!WPShared.libraryWindow.hidden) {
				[WPShared libraryWindowHide];
			}
			if (newWidgetWidth != WidgetWidth || newWidPlayerHideNoPlaying != WidPlayerHideNoPlaying) {
				WidgetWidth = newWidgetWidth;
				WidPlayerHideNoPlaying = newWidPlayerHideNoPlaying;
				[WPShared UpdateFrame];
				[WPShared updateNowPlayingStatus];
			}
			if (newWidgetRadius != WidgetRadius || newArtworkRadius != ArtworkRadius) {
				WidgetRadius = newWidgetRadius;
				ArtworkRadius = newArtworkRadius;
				[WPShared UpdateRadius];
			}
			[WPShared UpdateBlur];
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
		//if (WidPlayerEnabled) {
			%init(WidPlayerHooks);
			[[WidPlayerActivator sharedInstance] RegisterActions];
		//}
	}
}