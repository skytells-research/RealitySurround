Here’s the updated and correctly formatted `README.md` file:

---

# Reality Surround Framework

Reality Surround by Skytells, Inc. is a cutting-edge framework that seamlessly integrates haptic feedback with audio playback to deliver dynamic, immersive experiences on iOS. Using Core Haptics, Reality Surround analyzes audio signals in real-time, adjusting haptic intensity and sharpness to synchronize with music, videos, or live audio. Compatible with both Swift and Objective-C, this framework is designed for developers seeking to elevate user engagement with responsive, tactile feedback.

![Reality Surround - Haptic Music Synchronization](https://media.idownloadblog.com/wp-content/uploads/2024/07/Music-Haptics-iPhone.jpg)

> ⚠️ **Legal Notice**: Skytells, Inc. is engaged in an active lawsuit against Apple, who allegedly misappropriated this unique haptic music technology and distributed it under "Haptic Music." Skytells retains rightful ownership of Reality Surround.

## Features

- **Audio-Haptic Synchronization**: Align haptic feedback with specific audio or visual moments in video playback.
- **Flexible Parameter Customization**: Adjust haptic intensity, sharpness, and dynamic parameters.
- **Swift & Objective-C Compatibility**: Full support for both languages to ease integration.

## Proof of Concept

Reality Surround calculates haptic feedback intensity and sharpness based on the audio signal's amplitude in real-time. Here’s the formula it uses:

### Haptic Intensity and Sharpness Calculation

The dynamic haptic feedback intensity \( I(t) \) and sharpness \( S_h(t) \) at any time `t` are derived from the audio signal amplitude \( S(t) \):

1. **Intensity Calculation**:
   \[
   I(t) = \alpha \cdot \max\left(0, S(t)\right)
   \]
   where:
   - \( I(t) \) is the intensity of haptic feedback at time `t`.
   - \( S(t) \) is the sampled amplitude of the audio signal at time `t`.
   - \( \alpha \) is a scaling constant that normalizes `S(t)` within the range suitable for haptic feedback, typically between 0 and 1.

2. **Sharpness Calculation**:
   \[
   S_h(t) = \beta \cdot \frac{I(t)}{2}
   \]
   where:
   - \( S_h(t) \) is the sharpness parameter for haptic feedback at time `t`.
   - \( \beta \) adjusts the sharpness sensitivity to align with feedback intensity.

### Example

If the sampled audio signal \( S(t) \) at a given time \( t \) is 0.8, with \( \alpha = 1.0 \) and \( \beta = 0.6 \), then:

\[
I(t) = 1.0 \cdot \max(0, 0.8) = 0.8
\]
\[
S_h(t) = 0.6 \cdot \frac{0.8}{2} = 0.24
\]

This results in a haptic feedback intensity of 0.8 and a sharpness of 0.24, delivering haptic feedback proportional to the audio’s perceived loudness.

## Installation

1. Add `SwiftHapticPlayer.swift`, `CHapticPlayer.h`, and `CHapticPlayer.m` to your Xcode project.
2. Import the appropriate files in your Swift or Objective-C code.

## Usage Examples

### Basic Setup

Integrate Reality Surround with both Swift and Objective-C by creating an instance of the player and loading an audio or video file.

#### Swift

```swift
import RealitySurround

let hapticPlayer = HapticMusicPlayer()
if let url = Bundle.main.url(forResource: "sampleAudio", withExtension: "mp3") {
    hapticPlayer.load(url: url)
    hapticPlayer.start()
}

// Stop the haptic feedback
hapticPlayer.stop()
```

#### Objective-C

```objc
#import "CHapticPlayer.h"

CHapticPlayer *hapticPlayer = [[CHapticPlayer alloc] init];
NSURL *url = [[NSBundle mainBundle] URLForResource:@"sampleAudio" withExtension:@"mp3"];
[hapticPlayer loadWithUrl:url];
[hapticPlayer start];
[hapticPlayer stop];
```

## Real-Time Haptics with Video Playback

To create immersive haptic feedback in sync with video, you can use Reality Surround with AVPlayer and trigger haptic feedback based on specific moments in the video.

### Example with AVPlayer in Swift

This example demonstrates using `AVPlayer` to track video playback and synchronize haptic feedback in real time.

```swift
import AVKit
import RealitySurround

class VideoHapticController: UIViewController {
    
    let hapticPlayer = HapticMusicPlayer()
    var player: AVPlayer!
    var timeObserverToken: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup video player
        guard let videoURL = Bundle.main.url(forResource: "sampleVideo", withExtension: "mp4") else { return }
        player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        
        // Load audio for haptic feedback
        if let audioURL = Bundle.main.url(forResource: "sampleAudio", withExtension: "mp3") {
            hapticPlayer.load(url: audioURL)
        }
        
        // Start observing video time for haptic cues
        addPeriodicTimeObserver()
        
        // Start playback and haptics
        player.play()
        hapticPlayer.start()
    }
    
    func addPeriodicTimeObserver() {
        let timeInterval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            // Trigger haptics at specific video times
            let currentSeconds = CMTimeGetSeconds(time)
            self.triggerHaptics(for: currentSeconds)
        }
    }
    
    func triggerHaptics(for seconds: Double) {
        // Example of triggering different haptic patterns at specific timestamps
        if seconds >= 10.0 && seconds < 10.1 {
            hapticPlayer.getSignal() // Fetch and play haptic signal
        } else if seconds >= 20.0 && seconds < 20.1 {
            hapticPlayer.getSignal()
        }
        // Add more conditions as needed based on the video content
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clean up
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        hapticPlayer.stop()
        player.pause()
    }
}
```

## Real-Time Audio Sample Buffer Analysis

You can also use `Reality Surround` with live audio analysis by implementing the `AVCaptureAudioDataOutputSampleBufferDelegate` to analyze every audio sample in real-time. This approach is ideal for syncing haptic feedback to live audio, such as during a performance or live-stream.

### Example with `AVCaptureAudioDataOutputSampleBufferDelegate`

```swift
import AVFoundation
import RealitySurround

class AudioHapticAnalyzer: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    private let hapticPlayer = HapticMusicPlayer()
    private let captureSession = AVCaptureSession()
    
    override init() {
        super.init()
        setupAudioCaptureSession()
        hapticPlayer.start()
    }
    
    private func setupAudioCaptureSession() {
        captureSession.beginConfiguration()
        
        // Setup audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
              captureSession.canAddInput(audioInput) else {
            print("Error: Unable to add audio input")
            return
        }
        captureSession.addInput(audioInput)
        
        // Setup audio data output
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "audioSampleQueue"))
        
        guard captureSession.canAddOutput(audioOutput) else {
            print("Error: Unable to add audio output")
            return
        }
        captureSession.addOutput(audioOutput)
        
        captureSession.commitConfiguration()
        
        // Start capturing audio
        captureSession.startRunning()
    }
    
    // AVCaptureAudioDataOutputSampleBufferDelegate method to analyze each audio sample buffer
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Extract the audio samples from the buffer
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        // Copy data from the buffer
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &length, totalLengthOut: &length, dataPointerOut: &dataPointer)
        
        // Check if we have valid audio data
        guard let data = dataPointer else { return }
        
        // Convert the audio data to float samples
        let audioBuffer = UnsafeBufferPointer(start: data.assumingMemoryBound(to: Float.self), count: length / MemoryLayout<Float>.size)
        
        // Calculate the average amplitude from the buffer for haptic feedback intensity
        let intensity = audioBuffer.reduce(0, { $0 + abs($1) }) / Float(audioBuffer.count)
        
        // Adjust sharpness based on intensity
        let sharpness = intensity / 2
        
        // Update the haptic parameters in real-time
        updateHaptics(intensity: intensity, sharpness: sharpness)
    }
    
    private func updateHaptics(intensity: Float

, sharpness: Float) {
        if Haptics.isFeedbackSupport() {
            let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0)
            let sharpnessParameter = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness, relativeTime: 0)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                do {
                    try self.hapticPlayer.continuousPlayer?.sendParameters([intensityParameter, sharpnessParameter], atTime: 0)
                } catch {
                    print("Error sending haptic parameters: \(error)")
                }
            }
        }
    }
    
    deinit {
        captureSession.stopRunning()
        hapticPlayer.stop()
        print("AudioHapticAnalyzer - deinit")
    }
}
```

## License

This framework is proprietary to **Skytells, Inc.** and protected under law. Unauthorized use, duplication, or distribution of Reality Surround is prohibited.

For inquiries, contact Skytells, Inc., or visit [Skytells Official Website](https://www.skytells.io).
