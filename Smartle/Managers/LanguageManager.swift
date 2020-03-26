//
//  Countries.swift
//  Smartle
//
//  Created by jullianm on 23/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class LanguageManager {
    static let shared = LanguageManager()
    
    var collectionViewDataSource: Observable<[UIImage]> {
        return _collectionViewDataSource.asObservable()
    }
    private let _collectionViewDataSource = BehaviorRelay<[UIImage]>(value: [])
    
    var pickerViewDataSource: Observable<[UIImage]> {
        return _pickerViewDataSource.asObservable()
    }
    
    private let _pickerViewDataSource = BehaviorRelay<[UIImage]>(value: [])
    
    // language images
    var favoritesItems = [UIImage]() {
        willSet {
            _pickerViewDataSource.accept(newValue)
        }
    }
    var items = [UIImage]() {
        willSet {
            _collectionViewDataSource.accept(newValue)
        }
    }
    
    // language names
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

extension LanguageManager {
    func install() {
        favoritesItems = ["france",
                          "add_language"].compactMap(UIImage.init(named:))
        items = [
            "spain", "germany", "italy", "china",
            "arabic", "great_britain", "israel",
            "japan", "portugal", "romania", "russia",
            "netherlands", "korea", "poland", "greece"
            ].compactMap(UIImage.init(named:))
        
        favoritesLanguages = ["FR"]
        
        languages = ["ES", "DE", "IT", "ZH",
                     "AR", "EN", "HE", "JA",
                     "PT", "RO", "RU", "NL",
                     "KO", "PL", "EL"]
        
        chosenLanguage = "FR"
    }
    
    func install(fromStorage storage: [Main]) {
        storage.forEach { result in
            favoritesItems = result.favoritesItems.uiImages()
            items = result.items.uiImages()
            favoritesLanguages = result.favoritesLanguages
            languages = result.languages
            chosenLanguage = result.chosenLanguage
        }
    }
    
    func favoriteLanguageIndex() -> Int {
        return favoritesLanguages
            .enumerated()
            .first(where: { $0.element == chosenLanguage })?
            .offset ?? 0
    }
}
