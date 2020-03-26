//
//  UITableView.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import UIKit

extension UITableView {
    func indexPathsForRowsInSection(_ section: Int) -> [IndexPath] {
        return (0..<self.numberOfRows(inSection: section)).map { IndexPath(row: $0, section: section) }
    }
}
