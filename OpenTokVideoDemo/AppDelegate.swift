//
//  AppDelegate.swift
//  OpenTokVideoDemo
//
//  Created by Abhi Makadiya on 27/08/20.
//  Copyright © 2020 Abhi Makadiya. All rights reserved.
//

import UIKit
import PushKit
import CallKit
import UIView_draggable

var appDelegate = UIApplication.shared.delegate as? AppDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let pushRegistry = PKPushRegistry(queue: DispatchQueue.main) //VOIP push registry
    var callKitProviderDelegate: CallKitProviderDelegate? //callkit delegate
    
    //videoChat screen Variables
    var windowView: UIView?
    var videoChatVC: VideoChatViewController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //VOIP
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        //Callkit
        callKitProviderDelegate = CallKitProviderDelegate()
        return true
    }


}

// MARK: - Push Registry Delegate
extension AppDelegate: PKPushRegistryDelegate {
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let deviceToken = pushCredentials.token.reduce("", {$0 + String(format: "%02X", $1) })
        print("\(#function) token is: \(deviceToken)")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("\(#function) incoming voip notfication: \(payload.dictionaryPayload)")
        
        if let uuidString = payload.dictionaryPayload["UUID"] as? String,
            let handle = payload.dictionaryPayload["handle"] as? String,
            let uuid = UUID(uuidString: uuidString) {
            OTAudioDeviceManager.setAudioDevice(OTDefaultAudioDevice.sharedInstance())
            // display incoming call UI when receiving incoming voip notification
            let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            callKitProviderDelegate?.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: true, completion: { (error) in
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            })
        }
        
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("\(#function) token invalidated")
    }
    
}


// MARK: - VideoChat Customization UI
extension AppDelegate {
    
    func initializeVideoChatViewToWindow() { // subview videochatvc to window screen when video has comes.
        guard let window = UIWindow.key else {
            return
        }
        windowView = UIView(frame: window.bounds)
        windowView?.backgroundColor = UIColor.clear
        window.addSubview(windowView!)
        
        videoChatVC = VideoChatViewController.instantiate(appStoryboard: .main)
        videoChatVC?.videoLayoutDelegate = self
        videoChatVC!.view.bounds = windowView!.bounds
        windowView?.addSubview(videoChatVC!.view)
        
        //For making Draggable View
        self.windowView?.cagingArea = window.bounds
        self.windowView?.setDraggable(false)
    }
     
    func deinitializeChatView() {
        self.videoChatVC?.view.removeFromSuperview()
        self.videoChatVC = nil
        self.windowView?.removeFromSuperview()
        self.windowView = nil
    }
    
}

// MARK: - VideoChatView Delegate
extension AppDelegate: VideoChatViewDelegate {
    func shrinkContainerView() {
        guard let window = UIWindow.key else {
            return
        }
        
        guard videoChatVC != nil else {
            return
        }
        
        let fullView = UIView(frame: window.bounds)
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            
            guard let this = self else {
                return
            }
            this.windowView?.frame = CGRect(x: fullView.frame.size.width - 122, y: this.videoChatVC!.topSafeAreaInset() + 6, width: 100, height: 165)
            this.videoChatVC?.shrinkContainerView()
        }) { [weak self] (isSuccess) in
            
            guard let this = self else {
                return
            }
            this.videoChatVC?.layoutStreamingSubView()
        }
        self.windowView?.enableDragging()
    }
    
    func fullScreenContainerViewView() {
        guard let window = UIWindow.key else {
            return
        }
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            
            guard let this = self else {
                return
            }
            
            this.windowView?.frame = CGRect(x: 0.0, y: 0.0, width: window.bounds.width, height: window.bounds.height)
            this.videoChatVC?.fullScreenContainerView()
        }) { [weak self] (isSuccess) in
            guard let this = self else {
                return
            }
            this.videoChatVC?.layoutStreamingSubView()
        }
        self.windowView?.setDraggable(false)
    }
    
    
}
