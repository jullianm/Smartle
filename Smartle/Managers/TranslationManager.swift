//
//  Translation.swift
//  Smartle
//
//  Created by jullianm on 16/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class TranslationManager {
    static let shared = TranslationManager()
    
    private var disposeBag = DisposeBag()
    private var _translation = PublishRelay<String>()
    var translation: Driver<String> {
        return _translation.asDriver(onErrorJustReturn: .init())
    }
    
    func translate(word textToTranslate: String, to language: String) {
        let APIKey = "YOUR_API_KEY"
        
        guard let url = URLComponents(string: "https://translation.googleapis.com/language/translate/v2") else {
            return
        }
        
        Observable.just(url)
            .map { urlComponents -> URL? in
                var components = urlComponents
                
                components.queryItems = [
                    .init(name: "q", value: textToTranslate),
                    .init(name: "target", value: "\(language)"),
                    .init(name: "key", value: APIKey),
                    .init(name: "format", value: "text")
                ]
                return components.url
            }
            .ignoreNil()
            .flatMapLatest { url -> Observable<Data> in
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                return URLSession.shared.rx.data(request: request)
            }
            .decode(model: Translation.self)
            .map { $0.data.translations[0].translatedText }
            .subscribeOn(MainScheduler.instance)
            .bind(to: _translation)
            .disposed(by: disposeBag)
    }
}
