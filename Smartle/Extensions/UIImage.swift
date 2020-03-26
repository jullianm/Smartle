//
//  Image.swift
//  Smartle
//
//  Created by Jullianm on 06/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit

extension UIImage {
    func resized(frame: CGRect) -> UIImage {
        let rect = self.makeFillRect(aspectRatio: size, insideRect: frame)
        let size = CGSize(width: (frame.width), height: (frame.height))
        let hasAlpha = false
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        draw(in: rect)
        let sizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return sizedImage!
    }
    private func makeFillRect(aspectRatio: CGSize, insideRect: CGRect) -> CGRect {
        let aspectRatioFraction = aspectRatio.width / aspectRatio.height
        let insideRectFraction = insideRect.size.width / insideRect.size.height
        let r: CGRect
        if (aspectRatioFraction > insideRectFraction) {
            let w = insideRect.size.height * aspectRatioFraction
            r = CGRect(x: (insideRect.size.width - w)/2, y: 0, width: w, height: insideRect.size.height)
        } else {
            let h = insideRect.size.width / aspectRatioFraction
            r = CGRect(x: 0, y: (insideRect.size.height - h)/2, width: insideRect.size.width, height: h)
        }
        return r
    }
}
