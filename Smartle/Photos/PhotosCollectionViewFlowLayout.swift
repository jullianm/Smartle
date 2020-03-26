//
//  PhotosCollectionViewFlowLayout.swift
//  Smartle
//
//  Created by Jullianm on 08/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit

class PhotosCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else {
            return
        }
        
        scrollDirection = .horizontal
        
        itemSize = .init(width: collectionView.bounds.size.height/3 - 1,
                         height: collectionView.bounds.size.height/3 - 1)
        minimumLineSpacing = 1.0
        minimumInteritemSpacing = 1.0
    }
}
