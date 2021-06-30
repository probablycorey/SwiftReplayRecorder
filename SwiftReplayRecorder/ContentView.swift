//
//  ContentView.swift
//  SwiftReplayRecorder
//
//  Created by Corey Johnson on 6/30/21.
// https://github.com/arsenal1x2/Record-Screen/blob/52fb17322ff4c4894b27c61c29f11de83935cae0/RecordScreen/Ultinities/Source/ScreenRecorder.swift

import SwiftUI
import AVFoundation
import ReplayKit

struct ContentView: View {
    @State var recording = false
    @State var url = URL(fileURLWithPath: "")
    @State var assetWriter: AVAssetWriter!
    @State var audioMicInput: AVAssetWriterInput!
    @State var videoInput: AVAssetWriterInput!
    
    var body: some View {
        VStack {
            Text("Record the screen")
                .font(.title)
                .padding()
                .foregroundColor(.green)
            Text("Saving to " + url.absoluteString)
            Button(recording ? "Stop" : "Start") {
                if (recording) {
                    self.stop()
                } else {
                    self.start()
                }
            }
        }
        .padding()
    }
    
    func start() -> Void {
        print(RPScreenRecorder.shared().isMicrophoneEnabled)
        
        let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
        url = paths[0].appendingPathComponent("\(NSDate().timeIntervalSince1970).mp4")
        print(url)
        
        assetWriter = try! AVAssetWriter(outputURL: url, fileType:AVFileType.mp4)
        
        let audioOutputSettings: Dictionary<String, Any> = [
               AVFormatIDKey : kAudioFormatMPEG4AAC,
               AVNumberOfChannelsKey : 2,
               AVSampleRateKey : 44100.0,
               AVEncoderBitRateKey: 192000
           ]
       audioMicInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
       audioMicInput.expectsMediaDataInRealTime = true
       assetWriter.add(audioMicInput)
        
        let videoOutputSettings: Dictionary<String, Any> = [
            AVVideoCodecKey  : AVVideoCodecType.h264,
            AVVideoWidthKey  : NSScreen.main?.visibleFrame.size.width as AnyObject,
            AVVideoHeightKey : NSScreen.main?.visibleFrame.size.height as AnyObject
        ]
        videoInput  = AVAssetWriterInput (mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        assetWriter.add(videoInput)
        
        if RPScreenRecorder.shared().isAvailable {
            self.recording = true
            RPScreenRecorder.shared().startCapture(handler: { (buffer, bufferType, error) in
                if error == nil {
                    if CMSampleBufferDataIsReady(buffer) {
                        if self.assetWriter.status == AVAssetWriter.Status.unknown {
                            self.assetWriter.startWriting()
                            self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(buffer))
                        }
                        
                        if self.assetWriter.status == AVAssetWriter.Status.failed {
                            print("Error occured, status = \(self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(String(describing: self.assetWriter.error))")
                            return
                        }
                        
                        if bufferType == .video {
                            if self.videoInput.isReadyForMoreMediaData {
                                self.videoInput.append(buffer)
                            }
                        }
                        if bufferType == .audioMic {
                            if self.audioMicInput.isReadyForMoreMediaData {
                                self.audioMicInput.append(buffer)
                            }
                        }
                    }
                } else {
                    print(error ?? "")
                }
            })  { (error) in
                print(error ?? "")
            }
        }
    }
    
    func stop() -> Void {
        RPScreenRecorder.shared().stopCapture { (error) in
            if error == nil {
                self.assetWriter.finishWriting {
                    print("Finished")
                }
                self.recording = false

            } else {
                print(error ?? "")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
