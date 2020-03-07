//
//  String.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}
