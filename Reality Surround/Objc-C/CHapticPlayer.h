#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface HapticMusicPlayer : NSObject

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, strong) NSURL *assetUrl;
@property (nonatomic, strong) MPMusicPlayerController *mediaPlayer;

- (instancetype)init;
- (void)loadWithUrl:(NSURL *)url;
- (void)start;
- (void)reset;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
