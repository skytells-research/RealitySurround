//
//  AudioUtilities.swift
//  Reality Surround
//
//  Created by Hazem Ali on 9/16/21.
//  Copyright © 2021 Skytells, Inc. All rights reserved.
//
/*
 Abstract:
 Class containing methods for tone generation.
 */

import AudioToolbox
import AVFoundation
import Accelerate

class AudioUtilities: HapticMusicPlayer
{
    static var audioRunning = false             // RemoteIO Audio Unit running flag
    static var samplesFirstComparison:[Float] = [0.0]
    static var samplesSecondComparison:[Float] = [0.0]
    
    static var flagAudioUnit: AUAudioUnit?
    static var flagUrl: URL?
    
    // Returns an array of single-precision values for the specified audio resource.
    //    static func getAudioSamples(forResource: String, withExtension: String) -> [Float]?
    static func getAudioSamples(from url: URL?) -> [Float]?
    {
        //urlFromMusicKit: URL
        guard let url = url else { return nil }
        let asset = AVAsset(url: url)
        flagUrl = url
        
        guard
            let reader = try? AVAssetReader(asset: asset)
        else
        {
            return nil
        }
        
        let outputSettings =
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVNumberOfChannelsKey: 1
         
        ]
        guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return nil }
     
      //  let audioReadSetting: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM]
        let output = AVAssetReaderTrackOutput(track: audioAssetTrack, outputSettings: outputSettings)
        
        reader.add(output)
        reader.startReading()
        
        var samples = [Float]()
        
       // print("samples =", samples.count)
        
        while reader.status == .reading
        {
            if
                let sampleBuffer = output.copyNextSampleBuffer(),
                let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)
            {
                
                let bufferLength = CMBlockBufferGetDataLength(dataBuffer)
                
                var data = [Float](repeating: 0,
                                   count: bufferLength / 4)
                CMBlockBufferCopyDataBytes(dataBuffer,
                                           atOffset: 0,
                                           dataLength: bufferLength,
                                           destination: &data)
                
                samples.append(contentsOf: data)
            }
        }
        
        if samplesFirstComparison.count == 0
        {
            samplesFirstComparison = samples
        }
        else
        {
            samplesFirstComparison = samplesSecondComparison
            samplesSecondComparison = samples
        }
       
        return samples
    }
    
    // Configures audio unit to request and play samples from `signalProvider`.
    static func configureAudioUnit(signalProvider: HapticMusicPlayer?) {
        guard let signalProvider = signalProvider else { return }
        if audioRunning
        {
            if samplesFirstComparison.count == samplesSecondComparison.count
            {
                return
            }
            else
            {
                
            }
        }
        else
        {
            let kOutputUnitSubType = kAudioUnitSubType_RemoteIO
            
            let ioUnitDesc = AudioComponentDescription(
                componentType: kAudioUnitType_Output,
                componentSubType: kOutputUnitSubType,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0)
            
            guard
                let ioUnit = try? AUAudioUnit(componentDescription: ioUnitDesc,
                                              options: AudioComponentInstantiationOptions()),
                let outputRenderFormat = AVAudioFormat(
                    standardFormatWithSampleRate: ioUnit.outputBusses[0].format.sampleRate,
                    channels: 1)
            else
            {
                print("Unable to create outputRenderFormat")
                return
            }
            
            flagAudioUnit = ioUnit
            
            do
            {
                try flagAudioUnit!.inputBusses[0].setFormat(outputRenderFormat)
            }
            catch
            {
                print("Error setting format on ioUnit")
                return
            }
            
            //ioUnit.outputProvider =
            flagAudioUnit!.outputProvider =
            {
                (actionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                 timestamp: UnsafePointer<AudioTimeStamp>,
                 frameCount: AUAudioFrameCount,
                 busIndex: Int,
                 rawBufferList: UnsafeMutablePointer<AudioBufferList>) -> AUAudioUnitStatus in
                
                let bufferList = UnsafeMutableAudioBufferListPointer(rawBufferList)
                if !bufferList.isEmpty
                {
                    let signal = signalProvider.getSignal()
                    
                    bufferList[0].mData?.copyMemory(from: signal, byteCount: sampleCount * MemoryLayout<Float>.size)
                }
                return noErr
            }
            
            do
            {
                try flagAudioUnit!.allocateRenderResources()
            }
            catch
            {
                print("Error allocating render resources")
                return
            }
            
            do
            {
                
                try flagAudioUnit!.startHardware()
                audioRunning = true
            }
            catch
            {
                print("Error starting audio")
            }
        }
        
    }
    
    static func stopHardware() {
        flagAudioUnit?.stopHardware()
        audioRunning = false
    }
    static func pauseAudio()
    {
        if audioRunning
        {
            flagAudioUnit?.stopHardware()
            audioRunning = false
           
        }
        else
        {
            do
            {
                try flagAudioUnit?.startHardware()
                audioRunning = true
            }
            catch
            {
                print("Error starting audio")
            }
        }
    }
    
    static func stopAudioFirstTime()
    {
        flagAudioUnit?.stopHardware()
        audioRunning = false
    }
}

protocol SignalProvider
{
    func getSignal() -> [Float]
}
