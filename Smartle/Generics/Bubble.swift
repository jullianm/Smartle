//
//  Bubble.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import RxSwift
import UIKit

class Bubble: UIView {
    @IBOutlet weak var bubbleImageView: UIImageView!
    @IBOutlet weak var languagesPicker: UIPickerView! {
        didSet {
            languagesPicker.transform = CGAffineTransform(rotationAngle: -90 * (.pi/180))
            setupPickerView()
        }
    }
    @IBOutlet weak var deleteItem: UIButton!
    @IBOutlet weak var translatedText: UILabel!
    
    let collectionViewBubble: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "smartle_bubble")!)
        
        return imageView
    }()
    
    var disposeBag = DisposeBag()
    var onPickerItemSelected: ((Int) -> Void)?
    
    func updatePicker(isUserInteractionEnabled: Bool) {
        languagesPicker.reloadAllComponents()
        languagesPicker.isUserInteractionEnabled = isUserInteractionEnabled
    }
    
    func updateCollectionViewBubble(alpha: CGFloat = 0.0, isUserInteractionEnabled: Bool) {
        collectionViewBubble.alpha = alpha
        collectionViewBubble.isUserInteractionEnabled = isUserInteractionEnabled
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(collectionViewBubble)
    }
}

extension Bubble {
    func setupPickerView() {
        LanguageManager.shared.pickerViewDataSource
            .bind(to: languagesPicker.rx.items) { [weak self] (row, element, view) in
                guard let self = self else { return .init() }
                
                self.languagesPicker.subviews.forEach { $0.isHidden = $0.frame.height < 1.0 }
                
                let flagView = UIView(frame: CGRect(x: self.languagesPicker.frame.origin.x,
                                                    y: self.languagesPicker.frame.origin.y,
                                                    width: self.languagesPicker.frame.size.width,
                                                    height: self.languagesPicker.frame.size.height))
                
                let imageView = UIImageView(frame: CGRect(x: flagView.bounds.midX, y: flagView.bounds.midY, width: 20.0, height: 20.0))
                imageView.center = CGPoint(x: flagView.bounds.midX, y: flagView.bounds.midY)
                imageView.image = LanguageManager.shared.favoritesItems[row]
                
                flagView.transform = .init(rotationAngle: 90 * (.pi/180))
                flagView.addSubview(imageView)
                
                return flagView
            }.disposed(by: disposeBag)
        
        languagesPicker.rx.itemSelected
            .bind(onNext: { [weak self] row, _ in
                self?.onPickerItemSelected?(row)
            }).disposed(by: disposeBag)
    }
}
