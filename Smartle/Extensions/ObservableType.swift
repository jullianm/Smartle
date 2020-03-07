//
//  ObservableType.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit
import RxSwift

extension ObservableType where Element == Data {
    func decode<T: Decodable>(model: T.Type, using decoder: JSONDecoder = .init()) -> Observable<T> {
        return map { data in
            try decoder.decode(model, from: data)
        }
    }
}

extension ObservableType where Element == Optional<URL> {
    func ignoreNil() -> Observable<URL> {
        return flatMap { url -> Observable<URL> in
            (url != nil) ? .just(url!): .empty()
        }
    }
}
