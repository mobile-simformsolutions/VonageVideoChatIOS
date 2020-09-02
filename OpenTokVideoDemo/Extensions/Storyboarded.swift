//
//  Storyboarded.swift
//  OpenTokVideoDemo
//
//  Created by Amit Kajwani on 28/01/20.
//  Copyright © 2020 Simform Solutions. All rights reserved.
//

import UIKit

/// Storyboards
enum Storyboard: String {
    case main = "Main"
}

///// Instantiate View Controller
extension UIViewController {

    class func instantiate<T: UIViewController>(appStoryboard: Storyboard) -> T? {
        let storyboard = UIStoryboard(name: appStoryboard.rawValue, bundle: nil)
        let identifier = String(describing: self)
        return storyboard.instantiateViewController(withIdentifier: identifier) as? T
    }
    
    func topSafeAreaInset() -> CGFloat {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaInsets.top
        } else {
            return topLayoutGuide.length
        }
    }
    
    func bottomSafeAreaInset() -> CGFloat {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaInsets.bottom
        } else {
            return bottomLayoutGuide.length
        }
    }
}
