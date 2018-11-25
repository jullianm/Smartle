//
//  Translation.swift
//  Smartle
//
//  Created by jullianm on 16/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import Foundation
import Alamofire

class Translation {    
    static func fetch(word textToTranslate: String, to language: String, completion: @escaping (String) -> ()) {
        
        let APIKey = ""
        
        guard let url = URL(string: "https://translation.googleapis.com/language/translate/v2?key=\(APIKey)") else { return }
        
        let parameters: Parameters = ["q": textToTranslate, "target": "\(language)", "format": "text"]        
        DispatchQueue.global(qos: .userInteractive).async {
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseJSON { response in

            if let result = response.result.value {
                let myJson = result as! NSDictionary
                if let data = myJson["data"] as? NSDictionary {
                    if let translations = data["translations"] as? NSArray {
                        if let translationsArray = translations[0] as? NSDictionary {
                            if let text = translationsArray["translatedText"] as? String {
                                let translatedText = text.capitalizingFirstLetter()
                                DispatchQueue.main.async {
                                           completion(translatedText)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }
}
