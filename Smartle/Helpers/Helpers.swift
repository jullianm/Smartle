//
//  Helpers.swift
//  Smartle
//
//  Created by jullianm on 23/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import UIKit

// MARK: Helpers
extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}
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
extension UITableView {
    func indexPathsForRowsInSection(_ section: Int) -> [IndexPath] {
        return (0..<self.numberOfRows(inSection: section)).map { IndexPath(row: $0, section: section) }
    }
}

public func convertToUIImages(items: [Data]) -> [UIImage] {
    var flags = [UIImage]()
    items.forEach({ flagData in
        if let flagImage = UIImage(data: flagData) {
            flags.append(flagImage)
        }
    })
    return flags
}
public func convertToData(items: [UIImage]) -> [Data] {
    var flags = [Data]()
    items.forEach({ flag in
        guard let data: Data = UIImagePNGRepresentation(flag) else { return }
        flags.append(data)
    })
    return flags
}
