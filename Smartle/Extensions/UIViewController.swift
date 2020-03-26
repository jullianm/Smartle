//
//  UIViewController.swift
//  Smartle
//
//  Created by Jullianm on 09/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentAlertController() {
        let alertVC = UIAlertController(title: "Nothing to learn !",
                                        message: "Add favorites by tapping the heart at the bottom right",
                                        preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK",
                                        style: .default))
        self.present(alertVC, animated: true)
    }
}
