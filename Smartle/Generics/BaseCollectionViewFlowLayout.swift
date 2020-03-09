//
//  CollectionViewDelegate.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit

class BaseCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else {
            return
        }
        
        itemSize = .init(width: collectionView.bounds.height/2.5, height: collectionView.bounds.height/2.5)
        minimumLineSpacing = 10.0
        minimumInteritemSpacing = 10.0
    }
}
