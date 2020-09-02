//
//  Extension+UIWindow.swift
//  OpenTokVideoDemo
//
//  Created by Abhi Makadiya on 25/08/20.
//  Copyright © 2020 Abhi Makadiya. All rights reserved.
//

import UIKit

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
