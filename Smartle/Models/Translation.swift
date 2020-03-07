//
//  Translation.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import Foundation

struct Translation: Decodable {
    let data: Data
    
    struct Data: Decodable {
        let translations: [Translations]
        
        struct Translations: Decodable {
            let translatedText: String
        }
    }
}
