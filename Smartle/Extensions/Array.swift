//
//  Array.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit

extension Array where Element == Data {
    func uiImages() -> [UIImage] {
        return self.compactMap(UIImage.init(data:))
    }
}

extension Array where Element == UIImage {
    func data() -> [Data] {
        return self.compactMap { UIImagePNGRepresentation($0) }
    }
}
