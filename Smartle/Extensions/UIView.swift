//
//  UIView.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit

extension UIView {
    func animateWithDamping() {
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
            self.transform = .identity
        }, completion: nil)
    }
    func animateWithAlpha() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .allowUserInteraction, animations: {
            self.alpha = 1
        }, completion: nil)
    }
}
