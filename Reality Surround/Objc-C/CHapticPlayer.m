#import "CHapticPlayer.h"
#import <CoreHaptics/CoreHaptics.h>

@interface HapticMusicPlayer ()

@property (nonatomic, strong) CHHapticEngine *engine;
@property (nonatomic) BOOL engineNeedsStart;
@property (nonatomic, strong) id<CHHapticAdvancedPatternPlayer> continuousPlayer;

@end

@implementation HapticMusicPlayer

static const NSInteger sampleCount = 1024;
static NSMutableArray<NSNumber *> *samples;

- (instancetype)init {
    self = [super init];
    if (self) {
        _pageNumber = 0;
        _engineNeedsStart = YES;
        samples = [[NSMutableArray alloc] initWithObjects:@(0.0), nil];
        _mediaPlayer = [MPMusicPlayerController applicationQueuePlayer];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"HapticsPlayer - dealloc");
}

- (void)loadWithUrl:(NSURL *)url {
    [self reset];
    [self getSampleFromMusicKitWithUrl:url];
    [self createAndStartHapticEngine];
    [self createContinuousHapticPlayer];
}

- (void)start {
    // Your start logic here
}

- (void)reset {
    samples = [[NSMutableArray alloc] initWithObjects:@(0.0), nil];
    self.pageNumber = 0;
    self.engineNeedsStart = YES;
}

- (void)stop {
    [self.continuousPlayer stopAtTime:CHHapticTimeImmediate error:nil];
    [self.engine stopWithCompletionHandler:nil];
    [self reset];
}

- (void)getSampleFromMusicKitWithUrl:(NSURL *)url {
    // Example for media player setup and audio processing:
    // Stub function for simulating sample retrieval
    
    // Assume AudioUtilities provides methods in Objective-C:
    [AudioUtilities stopAudioFirstTime];
    
    samples = [AudioUtilities getAudioSamplesFrom:url];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [AudioUtilities configureAudioUnitWithSignalProvider:self];
    });
}

- (void)createAndStartHapticEngine {
    NSError *error = nil;
    self.engine = [[CHHapticEngine alloc] initAndReturnError:&error];
    if (error) {
        NSLog(@"Engine Creation Error: %@", error);
        return;
    }
    self.engine.playsHapticsOnly = YES;
    self.engine.isMutedForAudio = YES;

    __weak typeof(self) weakSelf = self;
    self.engine.stoppedHandler = ^(CHHapticEngineStoppedReason reason) {
        switch (reason) {
            case CHHapticEngineStoppedReasonAudioSessionInterrupt:
                NSLog(@"Audio session interrupt");
                break;
            case CHHapticEngineStoppedReasonApplicationSuspended:
                NSLog(@"Application suspended");
                break;
            case CHHapticEngineStoppedReasonIdleTimeout:
                NSLog(@"Idle timeout");
                break;
            case CHHapticEngineStoppedReasonSystemError:
                NSLog(@"System error");
                break;
            default:
                NSLog(@"Unknown error");
                break;
        }
    };

    self.engine.resetHandler = ^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            NSError *startError = nil;
            [strongSelf.engine startAndReturnError:&startError];
            if (!startError) {
                strongSelf.engineNeedsStart = NO;
                NSLog(@"Haptic Engine Restarted !");
            } else {
                NSLog(@"Failed to start the engine");
            }
        }
    };

    [self.engine startAndReturnError:&error];
    if (!error) {
        NSLog(@"Haptic Engine Started for the first time !");
    }
}

- (void)createContinuousHapticPlayer {
    NSError *error = nil;
    CHHapticEventParameter *intensity = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:1.0];
    CHHapticEventParameter *sharpness = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:0.6];
    CHHapticEvent *continuousEvent = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous parameters:@[intensity, sharpness] relativeTime:0 duration:100];

    CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithEvents:@[continuousEvent] parameters:@[] error:&error];
    self.continuousPlayer = [self.engine makeAdvancedPlayerWithPattern:pattern error:&error];
}

- (NSArray<NSNumber *> *)getSignal {
    NSInteger start = self.pageNumber * sampleCount;
    NSInteger end = (self.pageNumber + 1) * sampleCount;
    NSRange range = NSMakeRange(start, end - start);
    NSArray<NSNumber *> *page = [samples subarrayWithRange:range];
    self.pageNumber += 1;

    if ((self.pageNumber + 1) * sampleCount >= samples.count) {
        self.pageNumber = 0;
    }

    NSMutableArray<NSNumber *> *forHapticParameter = [[NSMutableArray alloc] init];
    for (NSNumber *number in page) {
        if (number.floatValue >= 0) {
            [forHapticParameter addObject:number];
        }
    }

    NSNumber *signalToParameter = forHapticParameter[MIN(50, forHapticParameter.count - 1)];
    float dynamicIntensity = signalToParameter.floatValue;
    float dynamicSharpness = signalToParameter.floatValue / 2;

    if ([Haptics isFeedbackSupport]) {
        CHHapticDynamicParameter *intensityParameter = [[CHHapticDynamicParameter alloc] initWithParameterID:CHHaptic
