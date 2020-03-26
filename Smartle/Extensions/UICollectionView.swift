//
//  UICollectionView.swift
//  Smartle
//
//  Created by Jullianm on 19/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit

extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}
