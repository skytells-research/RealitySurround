//
//  RealtimeHaptics.swift
//  Reality Surround
//
//  Created by Hazem Ali on 10/29/24.
//

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
    
    private func updateHaptics(intensity: Float, sharpness: Float) {
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
