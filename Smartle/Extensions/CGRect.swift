//
//  CGRect.swift
//  Smartle
//
//  Created by Jullianm on 19/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit

extension CGRect {
    func differencesWithNewRect(_ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if self.intersects(new) {
            var added = [CGRect]()
            if new.maxY > self.maxY {
                added += [CGRect(x: new.origin.x, y: self.maxY,
                                 width: new.width, height: new.maxY - self.maxY)]
            }
            if self.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: self.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < self.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: self.maxY - new.maxY)]
            }
            if self.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: self.minY,
                                   width: new.width, height: new.minY - self.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [self])
        }
    }
}
