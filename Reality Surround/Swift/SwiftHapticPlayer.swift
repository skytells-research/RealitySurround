//
//  SwiftHapticPlayer.swift
//  Skytells, Inc.
//
//  Created by Hazem Ali on 9/16/21.
//  Copyright © 2021 Skytells, Inc. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import CoreHaptics

class HapticMusicPlayer {
    var pageNumber = 0
    private var engine: CHHapticEngine!
    private var engineNeedsStart = true
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    
    // Constants
    private let initialIntensity: Float = 1.0
    private let initialSharpness: Float = 0.6
    static let sampleCount = 1024
    static var samples: [Float] = [0.0]
    var assetUrl: URL?
    var mediaPlayer = MPMusicPlayerController.applicationQueuePlayer
    
    init() { }
    
    deinit {
        print("HapticMusicPlayer - deinit")
    }
    
    func load(url: URL) {
        reset()
        getSampleFromMusicKit(from: url)
        createAndStartHapticEngine()
        createContinuousHapticPlayer()
    }
    
    func start() {
        // Additional start functionality
    }
    
    func reset() {
        HapticMusicPlayer.samples = [0.0]
        pageNumber = 0
        engineNeedsStart = true
    }
    
    func stop() {
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        engine?.stop(completionHandler: nil)
        reset()
    }
    
    private func getSampleFromMusicKit(from url: URL) {
        AudioUtilities.stopAudioFirstTime()
        
        let samplesFromMusicKit: [Float] = {
            guard let samples = AudioUtilities.getAudioSamples(from: url) else {
                fatalError("Unable to parse the audio resource.")
            }
            return samples
        }()
        
        HapticMusicPlayer.samples = samplesFromMusicKit
        DispatchQueue.global(qos: .userInitiated).async {
            AudioUtilities.configureAudioUnit(signalProvider: self)
        }
    }
    
    private func createAndStartHapticEngine() {
        do {
            engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isMutedForAudio = true
        } catch {
            fatalError("Engine Creation Error: \(error)")
        }
        
        // Avoid retain cycles in stopped and reset handlers
        engine.stoppedHandler = { [weak self] reason in
            guard let self = self else { return }
            print("Engine stopped for reason: \(reason.rawValue)")
            switch reason {
            case .audioSessionInterrupt: print("Audio session interrupt")
            case .applicationSuspended: print("Application suspended")
            case .idleTimeout: print("Idle timeout")
            case .systemError: print("System error")
            case .notifyWhenFinished: print("Playback finished")
            case .engineDestroyed: print("Engine destroyed")
            case .gameControllerDisconnect: print("Game controller disconnect")
            @unknown default: print("Unknown error")
            }
        }
        
        engine.resetHandler = { [weak self] in
            guard let self = self else { return }
            do {
                try self.engine.start()
                self.engineNeedsStart = false
                print("Haptic Engine Restarted!")
            } catch {
                print("Failed to start the engine")
            }
        }
        
        do {
            try engine.start()
            print("Haptic Engine Started for the first time!")
        } catch {
            print("Failed to start the engine: \(error)")
        }
    }
    
    private func createContinuousHapticPlayer() {
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: initialIntensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: initialSharpness)
        let continuousEvent = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 100)
        
        do {
            let pattern = try CHHapticPattern(events: [continuousEvent], parameters: [])
            continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
        } catch {
            print("Pattern Player Creation Error: \(error)")
        }
    }
    
    func getSignal() -> [Float] {
        let start = pageNumber * HapticMusicPlayer.sampleCount
        let end = min((pageNumber + 1) * HapticMusicPlayer.sampleCount, HapticMusicPlayer.samples.count)
        let page = Array(HapticMusicPlayer.samples[start..<end])
        
        pageNumber += 1
        if (pageNumber + 1) * HapticMusicPlayer.sampleCount >= HapticMusicPlayer.samples.count {
            pageNumber = 0
        }
        
        let outputSignal = page
        let forHapticParameter = outputSignal.filter { $0 >= 0 }
        let index = min(50, forHapticParameter.count)
        let signalToParameter = forHapticParameter[index] ?? 0.0
        let dynamicIntensity = signalToParameter
        let dynamicSharpness = signalToParameter / 2
        
        if Haptics.isFeedbackSupport() {
            let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: dynamicIntensity, relativeTime: 0)
            let sharpnessParameter = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: dynamicSharpness, relativeTime: 0)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                do {
                    try self.continuousPlayer?.sendParameters([intensityParameter, sharpnessParameter], atTime: 0)
                    try self.continuousPlayer?.start(atTime: CHHapticTimeImmediate)
                    print("Haptic Continuous Player Started!")
                } catch {
                    print("Error starting the continuous haptic player: \(error)")
                }
            }
        }
        
        return outputSignal
    }
}
