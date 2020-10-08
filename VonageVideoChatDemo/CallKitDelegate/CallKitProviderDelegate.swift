//
//  CallKitProviderDelegate.swift
//  OpenTokVideoDemo
//
//  Created by Abhi Makadiya on 27/08/20.
//  Copyright © 2020 Abhi Makadiya. All rights reserved.
//

import UIKit
import CallKit
import OpenTok

class CallKitProviderDelegate: NSObject {
    
    // MARK: - Variable Declaration
    private let provider: CXProvider
    let callController = CXCallController()
    var currentCallID: UUID?
    
    /// The app's provider configuration, representing its CallKit capabilities
    static var providerConfiguration: CXProviderConfiguration {
        let localizedName = NSLocalizedString("CallKitDemo", comment: "Name of application")
        let providerConfiguration = CXProviderConfiguration(localizedName: localizedName)

        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        //providerConfiguration.includesCallsInRecents = true
        return providerConfiguration
    }
    
    // MARK: - Initializers
    override init() {
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    // MARK: - Functions Declarations
    
    // MARK: Incoming Calls
    
    /// Use CXProvider to report the incoming call to the system
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = true, completion: ((NSError?) -> Void)? = nil) {
        // Construct a CXCallUpdate describing the incoming call, including the caller.
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo
        currentCallID = uuid
        // Report the incoming call to the system
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            completion?(error as NSError?)
        }
    }
     
    //To end Incomming calls. End this after 5 second for remove callkit UI.
    func endCall(call: UUID) {

        let endCallAction = CXEndCallAction(call: call)
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { [weak self] error in
            
            guard let this = self else {
                return
            }
            
            if let error = error {
                print("EndCallAction transaction request failed: \(error.localizedDescription).")
                this.provider.reportCall(with: call, endedAt: Date(), reason: CXCallEndedReason.remoteEnded)
                return
            }

            print("EndCallAction transaction request successful")
            this.currentCallID = nil
        }

    }
}

// MARK: - Callkit Delegates
extension CallKitProviderDelegate: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
        /*
            End any ongoing calls if the provider resets, and remove them from the app's list of calls,
            since they are no longer valid.
         */
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // Retrieve the SpeakerboxCall instance corresponding to the action's call UUID
        configureAudioSession()
        appDelegate?.initializeVideoChatViewToWindow()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let this = self else {
                return
            }
            this.endCall(call: this.currentCallID ?? UUID())
        }
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // Retrieve the SpeakerboxCall instance corresponding to the action's call UUID
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        OTAudioDeviceManager.setAudioDevice(OTDefaultAudioDevice.sharedInstance(with: audioSession))
        configureAudioSession()
    }
    
    func configureAudioSession() {
        // See https://forums.developer.apple.com/thread/64544
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: .voiceChat, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try session.setActive(true)
            try session.setMode(AVAudioSession.Mode.voiceChat)
            try session.setPreferredSampleRate(44100.0)
            try session.setPreferredIOBufferDuration(0.005)
        } catch {
            print(error)
        }
    }
}
