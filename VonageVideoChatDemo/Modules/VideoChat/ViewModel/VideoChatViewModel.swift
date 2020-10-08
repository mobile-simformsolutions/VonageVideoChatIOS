//
//  VideoChatViewModel.swift
//  OpenTokVideoDemo
//
//  Created by Abhi Makadiya on 28/08/20.
//  Copyright © 2020 Abhi Makadiya. All rights reserved.
//

import UIKit
import OpenTok
import  AVKit

class VideoChatViewModel: NSObject {
    
    // MARK: - Variable Declaration
    var callDurationTimer: Timer?
    var durationSec: Int = 0
    var isCallTimerPause: Bool = false
    //opentok
    lazy var session: OTSession? = {
        return OTSession(apiKey: AppConstant.openTokApiKey, sessionId: AppConstant.openTokSessionId, delegate: self)!
    }()
    lazy var publisher: OTPublisher? = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        settings.audioTrack = true
        settings.videoTrack = true
        return OTPublisher(delegate: self, settings: settings)!
    }()
    var subscriber: OTSubscriber?
    //closures
    var addPublisherView: (() -> Void)?
    var addSubscriberView: (() -> Void)?
    var streamDestroyed: (() -> Void)?
    
    // MARK: - Initializer
    override init() {
        super.init()
    }
    
    deinit {
        publisher = nil
        session = nil
    }
    
    // MARK: - Functions
    @objc func callDurationTimerAction() {
        durationSec = durationSec + 1
        print(durationSec)
        
        subscriber = nil
    }
    
    func startCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
        callDurationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(callDurationTimerAction), userInfo: nil, repeats: true)
    }
    
    func stopCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }
    
    // MARK: - OpenTok Functions
    
    /**
    * Asynchronously begins the session connect process. Some time later, we will
    * expect a delegate method to call us back with the results of this action.
    */
    func doConnect() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session?.connect(withToken: AppConstant.openTokToken, error: &error)
    }
    
    func doDisconnect() {
        var error: OTError?
        defer {
            processError(error)
        }
        session?.disconnect(&error)
        session = nil
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        if publisher != nil {
            session?.publish(publisher!, error: &error)
        }
        addPublisherView?()
    }
    
    func endCall() {
        /*
        Simulate the end taking effect immediately, since
        the example app is not backed by a real network service
        */
        if let publisher = publisher {
            var error: OTError?
            session?.unpublish(publisher, error: &error)
            if error != nil {
                print(error!)
            }
        }
        publisher = nil
        doDisconnect()
        subscriber = nil
    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            processError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        
        session?.subscribe(subscriber!, error: &error)
        
    }
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    fileprivate func cleanupPublisher() {
        publisher?.view?.removeFromSuperview()
    }
    
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            print(err)
        }
    }
  
}

// MARK: - OTSession delegate callbacks
extension VideoChatViewModel: OTSessionDelegate {
    
    func sessionDidConnect(_ session: OTSession) {
        print(#function)
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print(#function)
        streamDestroyed?()
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print(#function)
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print(#function)
        if subscriber == nil {
            doSubscribe(stream)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print(#function)
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
        streamDestroyed?()
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension VideoChatViewModel: OTPublisherDelegate {
    
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print(#function)
        print("Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        print(#function)
        cleanupPublisher()
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
        streamDestroyed?()
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print(#function, error.localizedDescription)
    }
    
}

// MARK: - OTSubscriber delegate callbacks
extension VideoChatViewModel: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        print(#function)
        startCallDurationTimer()
        addSubscriberView?()
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print(#function)
        print("Subscriber failed: \(error.localizedDescription)")
    }
}
