//
//  UIViewController.swift
//  Reality Surround
//
//  Created by Hazem Ali on 10/29/24.
//  Kindly, Run this ViewController from the hosting app.
//
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
