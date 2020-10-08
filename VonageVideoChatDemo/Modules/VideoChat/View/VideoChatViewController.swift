//
//  VideoChatViewController.swift
//  OpenTokVideoDemo
//
//  Created by Abhi Makadiya on 27/08/20.
//  Copyright © 2020 Abhi Makadiya. All rights reserved.
//

import UIKit

protocol VideoChatViewDelegate: class {
    func shrinkContainerView()
    func fullScreenContainerViewView()
}

class VideoChatViewController: UIViewController {

    // MARK: - Variable Declaration
    //viewModel
    var viewModel: VideoChatViewModel!
    //delegate
    weak var videoLayoutDelegate: VideoChatViewDelegate?
    //tap gesture
    var tapGesture = UITapGestureRecognizer()
    
    // MARK: - Outlets
    ///UIView
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var viewOpponentVideoContainer: UIView!
    @IBOutlet weak var viewMyVideoContainer: UIView!
    ///UIButton
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnSpeaker: UIButton!
    @IBOutlet weak var btnDisconnect: UIButton!
    @IBOutlet weak var btnMic: UIButton!
    ///UISatckView
    @IBOutlet weak var stackChatControl: UIStackView!
    ///NSLayoutConstraint
    @IBOutlet weak var widthMyVideoContainer: NSLayoutConstraint!
    @IBOutlet weak var heightMyVideoContainer: NSLayoutConstraint!
    @IBOutlet weak var trailingMyVideoContainer: NSLayoutConstraint!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateContainer()
    }
    
    //MARK: - IB Action
    @IBAction func btnBackAction(_ sender: UIButton) {
        videoLayoutDelegate?.shrinkContainerView()
    }
    
    @IBAction func btnDisconnectAction(_ sender: UIButton) {
        //viewModel.doDisconnect()
        viewModel.endCall()
    }
    
    @IBAction func btnMicMuteAction(_ sender: UIButton) {
        if sender.isSelected { //currently mic is unmute
            sender.isSelected = false //Mute Mic
            viewModel.publisher?.publishAudio = false
        } else {
            sender.isSelected = true //Unmute Mic
            viewModel.publisher?.publishAudio = true
        }
    }
    
    @IBAction func btnSpeakerMuteAction(_ sender: UIButton) {
        if sender.isSelected { //currently speaker is unmute
            sender.isSelected = false //Mute speaker
            viewModel.subscriber?.subscribeToAudio = false
        } else {
            sender.isSelected = true //Unmute speaker
            viewModel.subscriber?.subscribeToAudio = true
        }
    }
    
    @IBAction func videoPausePlayAction(_ sender: UIButton) {
        if sender.isSelected {
            sender.isSelected = false
            viewModel.publisher?.publishVideo = false
            viewModel.stopCallDurationTimer()
        } else {
            sender.isSelected = true
            viewModel.publisher?.publishVideo = true
            viewModel.startCallDurationTimer()
        }
    }
    
    
    //MARK: - Function Declaration
    func setupUI() {
        viewModel = VideoChatViewModel()
        fullScreenContainerView()
        viewMyVideoContainer.layer.cornerRadius = 6.0
        animateContainer()
        openTokClosures() //closures from viewModel
        viewModel.doConnect()
    }
    
    func openTokClosures() {
        viewModel.addPublisherView = { [weak self] in
            guard let this = self else {
                return
            }
            if let pubView = this.viewModel.publisher?.view {
                pubView.tag = 32
                pubView.frame = this.viewMyVideoContainer.bounds
                this.viewMyVideoContainer.addSubview(pubView)
            }
        }
        
        viewModel.addSubscriberView = { [weak self] in
            
            guard let this = self else {
                return
            }
            
            this.viewModel.subscriber?.viewScaleBehavior = .fill
            
            if let subView = this.viewModel.subscriber?.view {
                subView.tag = 23
                this.viewOpponentVideoContainer.addSubview(subView)
                subView.frame = this.viewOpponentVideoContainer.bounds
            }
            
        }
    
        viewModel.streamDestroyed = { [weak self] in
            guard let this = self else {
                return
            }
            this.viewModel.endCall()
            this.viewModel.session = nil
            this.viewModel.publisher = nil
            this.viewModel.subscriber = nil
            print(this.viewModel.durationSec)
            this.viewModel.stopCallDurationTimer()
            this.animateToDestroyContainer()
        }
    }
    
    func animateContainer() { //animate controller on first load
        viewContainer.backgroundColor = UIColor.white.withAlphaComponent(0.0)
        UIView.animate(withDuration: 0.4) { [weak self] in
            guard let this = self else {
                return
            }
            this.viewContainer.backgroundColor = UIColor.white.withAlphaComponent(1.0)
        }
    }
    
    func animateToDestroyContainer() {
        viewContainer.backgroundColor = UIColor.white.withAlphaComponent(1.0)
        UIView.animate(withDuration: 0.4, animations: { [weak self] in
            guard let this = self else {
                return
            }
            this.viewContainer.backgroundColor = UIColor.white.withAlphaComponent(0.0)
        }) { (isSuccess) in
            appDelegate?.deinitializeChatView()
        }
    }
    
    func shrinkContainerView() {
        heightMyVideoContainer.constant = 70
        widthMyVideoContainer.constant = 45
        trailingMyVideoContainer.constant = 10
        btnBack.isHidden = true
        stackChatControl.isHidden = true
        btnSpeaker.isHidden = true
        btnMic.isHidden = true
        btnDisconnect.isHidden = true
        viewContainer.layer.cornerRadius = 6.0
        addTapGestureToContainer()
    }
    
    func fullScreenContainerView() {
        heightMyVideoContainer.constant = 165
        widthMyVideoContainer.constant = 100
        trailingMyVideoContainer.constant = 20
        btnBack.isHidden = false
        stackChatControl.isHidden = false
        btnSpeaker.isHidden = false
        btnMic.isHidden = false
        btnDisconnect.isHidden = false
        viewContainer.layer.cornerRadius = 0.0
        removeTapGestureToContainer()
    }
    
    func layoutStreamingSubView() {
        if let publisherView = self.viewMyVideoContainer.viewWithTag(32) {
            publisherView.frame = self.viewMyVideoContainer.bounds
        }
        if let subscriberView = self.viewOpponentVideoContainer.viewWithTag(23) {
            subscriberView.frame = self.viewOpponentVideoContainer.bounds
        }
    }
    
    func addTapGestureToContainer() { // Double Tap to Full Screen
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapToExpandAction(_:)))
        tapGesture.numberOfTapsRequired = 2
        viewContainer.addGestureRecognizer(tapGesture)
        viewContainer.isUserInteractionEnabled = true
    }
    
    @objc func doubleTapToExpandAction(_ sender: UITapGestureRecognizer) {
        videoLayoutDelegate?.fullScreenContainerViewView()
    }
    
    func removeTapGestureToContainer() {
        viewContainer.removeGestureRecognizer(tapGesture)
    }
}
