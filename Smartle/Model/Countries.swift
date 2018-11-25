//
//  Countries.swift
//  Smartle
//
//  Created by jullianm on 23/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import UIKit

class Countries {
    static let shared = Countries()
    
    var favoritesItems = [UIImage]()
    var items = [UIImage]()
    var favoritesLanguages = [String]()
    var languages = [String]()
    var chosenLanguage = String()
    
    private init() {
    }
}
