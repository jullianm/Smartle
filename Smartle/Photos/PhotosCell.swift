//
//  PhotosCell.swift
//  Smartle
//
//  Created by jullianm on 20/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import UIKit

class PhotosCell: UICollectionViewCell {
    @IBOutlet var photo: UIImageView!
    @IBOutlet weak var alphaView: UIView!
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            photo.image = thumbnailImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photo.image = nil
    }
}
