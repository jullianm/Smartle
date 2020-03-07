//
//  Countries.swift
//  Smartle
//
//  Created by jullianm on 23/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import UIKit

class LanguageManager {
    static let shared = LanguageManager()
    
    var favoritesItems = [UIImage]()
    var items = [UIImage]()
    
    var favoritesLanguages = [String]()
    var languages = [String]()
    
    var chosenLanguage = String()
    
    private init() { }
    
    func updateFavoriteLanguage(atIndex index: Int) {
        favoritesItems.insert(items[index], at: favoritesItems.count-1)
        items.remove(at: index)
        favoritesLanguages.append(languages[index])
        languages.remove(at: index)
        
        chosenLanguage = favoritesLanguages.last ?? "FR"
    }
    
    func deleteFavoriteLanguage() {
        let index = favoritesLanguages.enumerated().first(where: { $0.element == chosenLanguage })?.offset ?? 0
        items.append(favoritesItems[index])
        favoritesItems.remove(at: index)
        languages.append(favoritesLanguages[index])
        favoritesLanguages.remove(at: index)
    }
}
