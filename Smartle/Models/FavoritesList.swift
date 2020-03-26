//
//  RevisionsList.swift
//  Smartle
//
//  Created by jullianm on 31/03/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import RxDataSources
import RxSwift
import RxCocoa
import UIKit

struct FavoritesList {
    var currentTranslation: String
    var favoritesItems: [UIImage]
    var favoritesLanguages: [String]
    var items: [UIImage]
    var languages: [String]
    var originalTranslation: String
    var photo: UIImage
    var selectedLanguage: String
    
    lazy var itemsRelay = BehaviorRelay(value: items)
    lazy var favoritesItemsRelay = BehaviorRelay(value: favoritesItems)
    lazy var languagesRelay = BehaviorRelay(value: languages)
    lazy var favoritesLanguagesRelay = BehaviorRelay(value: favoritesLanguages)
    
    mutating func addItem(at index: Int) {
        favoritesItems.insert(items[index], at: favoritesItems.count-1)
        items.remove(at: index)
        favoritesLanguages.append(languages[index])
        languages.remove(at: index)
        
        updateDataSources()
    }
    
    mutating func deleteItem(at index: Int) {
        items.append(favoritesItems[index])
        favoritesItems.remove(at: index)
        languages.append(favoritesLanguages[index])
        favoritesLanguages.remove(at: index)
        
        updateDataSources()
    }
}

extension FavoritesList {
    mutating private func updateDataSources() {
        itemsRelay.accept(items)
        favoritesItemsRelay.accept(favoritesItems)
        languagesRelay.accept(languages)
        favoritesLanguagesRelay.accept(favoritesLanguages)
    }
}

extension FavoritesList {
    var selectedLanguageIndex: Int {
        return favoritesLanguages
            .enumerated()
            .first(where: { $0.element == selectedLanguage })?.offset ?? 0
        
    }
}
