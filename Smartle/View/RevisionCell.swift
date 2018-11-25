//
//  RevisionCell.swift
//  Smartle
//
//  Created by jullianm on 04/03/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import UIKit

protocol UserWordReplacementDelegate {
    func replace(userWord: String, to chosenLanguage: String, at indexPath: IndexPath)
}
protocol RequestTranslationDelegate {
    func requestTranslation(to chosenLanguage: String, at indexPath: IndexPath)
}
class RevisionCell: UITableViewCell {
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var associatedWord: UITextField!
    @IBOutlet weak var languagePicker: UIPickerView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var containerBubble: UIImageView!
    @IBOutlet weak var languagesList: UICollectionView!
    @IBOutlet weak var deleteItem: UIButton!
    
    var wordReplacemenDelegate: UserWordReplacementDelegate?
    var translationDelegate: RequestTranslationDelegate?
    private var currentCellPosition: IndexPath? {
        get {
            if let table = self.superview as? UITableView {
                if let indexPath = table.indexPath(for: self) {
                    return indexPath
                }
            }
        return nil
        }
    }
    var selectedRow: Int!
    var tableView: UITableView!
    var lastCellPosition: IndexPath!
    var uppestCellPosition: IndexPath!
    lazy var favoritesItems = [UIImage]()
    lazy var items = [UIImage]()
    lazy var favoritesLanguages = [String]()
    lazy var languages = [String]()
    lazy var chosenLanguage = String()
    var isBeingEdited = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        associatedWord.delegate = self
        languagePicker.delegate = self
        languagePicker.dataSource = self
        languagesList.dataSource = self
        languagesList.delegate = self
        container.alpha = 0
        container.isUserInteractionEnabled = false
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        photo.contentMode = .scaleAspectFill
        photo.layer.cornerRadius = 30.0
        photo.layer.masksToBounds = true
        photo.layer.borderWidth = 2.0
        photo.layer.borderColor = #colorLiteral(red: 0.9766208529, green: 0.9123852253, blue: 0.7817487121, alpha: 1)
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneClicked))
        toolBar.setItems([doneButton], animated: false)
        associatedWord.inputAccessoryView = toolBar
        languagePicker.layer.cornerRadius = 30.0
        let rotationAngle: CGFloat = -90 * (.pi/180)
        let x = languagePicker.frame.origin.x
        let y = languagePicker.frame.origin.y
        let width = languagePicker.frame.size.width
        let height = languagePicker.frame.size.height
        languagePicker.transform = CGAffineTransform(rotationAngle: rotationAngle)
        languagePicker.frame = CGRect(x: x, y: y, width: width, height: height)
        selectedRow = languagePicker.selectedRow(inComponent: 0)
        tableView = self.superview as! UITableView
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        if container.alpha == 1 {
            deleteItem.isHidden = false
            container.alpha = 0
            container.isUserInteractionEnabled = false
            languagePicker.isUserInteractionEnabled = true
            associatedWord.isUserInteractionEnabled = true
        }
    }
    @IBAction func deleteFromFavorites(_ sender: UIButton) {
        if languagePicker.selectedRow(inComponent: 0) != favoritesItems.count-1 && languagePicker.numberOfRows(inComponent: 0) > 2 {
            let row = languagePicker.selectedRow(inComponent: 0)
            for (index, language) in favoritesLanguages.enumerated() where language == chosenLanguage {
                items.append(favoritesItems[index])
                favoritesItems.remove(at: index)
                languages.append(favoritesLanguages[index])
                favoritesLanguages.remove(at: index)
            }
            if row >= 1 {
                languagePicker.selectRow(row-1, inComponent: 0, animated: false)
                chosenLanguage = favoritesLanguages[row-1]
            } else {
                chosenLanguage = favoritesLanguages[0]
            }
            languagePicker.reloadAllComponents()
            languagesList.reloadData()
            selectedRow = languagePicker.selectedRow(inComponent: 0)
            guard let indexPath = currentCellPosition else { return }
            translationDelegate?.requestTranslation(to: chosenLanguage, at: indexPath)
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if container.isUserInteractionEnabled {
            languagePicker.selectRow(selectedRow, inComponent: 0, animated: false)
            deleteItem.isHidden = false
            container.alpha = 0
            container.isUserInteractionEnabled = false
            languagePicker.isUserInteractionEnabled = true
            associatedWord.isUserInteractionEnabled = true
        }
    }
    @objc private func doneClicked() {
        associatedWord.resignFirstResponder()
    }
    private func displayLanguagesMenu() {
        container.animateWithAlpha()
        deleteItem.isHidden = true
        container.isUserInteractionEnabled = true
        languagePicker.isUserInteractionEnabled = false
        associatedWord.isUserInteractionEnabled = false
    }
}
// MARK: CollectionView
extension RevisionCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "favoritesFlagCell", for: indexPath) as! FavoritesVCFlagCell
        cell.favoritesFlag.image = items[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        favoritesItems.insert(items[indexPath.item], at: favoritesItems.count-1)
        items.remove(at: indexPath.item)
        favoritesLanguages.append(languages[indexPath.item])
        languages.remove(at: indexPath.item)
        guard let lastLanguage = favoritesLanguages.last else { return }
        guard let myIndex = currentCellPosition else { return }
        deleteItem.isHidden = false
        container.alpha = 0
        container.isUserInteractionEnabled = false
        collectionView.reloadData()
        languagePicker.reloadAllComponents()
        languagePicker.isUserInteractionEnabled = true
        associatedWord.isUserInteractionEnabled = true
        chosenLanguage = lastLanguage
        selectedRow = languagePicker.selectedRow(inComponent: 0)
        translationDelegate?.requestTranslation(to: lastLanguage, at: myIndex)
        languagePicker.selectRow(favoritesLanguages.count-1, inComponent: 0, animated: false)
    }
}
extension RevisionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height/2.5
        return CGSize(width: height, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
}
// MARK: - PickerView
extension RevisionCell: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerView.subviews.forEach ({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return favoritesItems.count
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let myView = UIView(frame: CGRect(x: pickerView.frame.origin.x, y: pickerView.frame.origin.y, width: pickerView.frame.size.width, height: pickerView.frame.size.height))
        let imageView = UIImageView(frame: CGRect(x: myView.bounds.midX, y: myView.bounds.midY, width: 20.0, height: 20.0))
        imageView.center = CGPoint(x: myView.bounds.midX, y: myView.bounds.midY)
        imageView.image = favoritesItems[row]
        myView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        myView.addSubview(imageView)
        return myView
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.height
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == favoritesItems.count-1 {
            if !items.isEmpty {
                displayLanguagesMenu()
            }
        } else {
            selectedRow = row
            chosenLanguage = favoritesLanguages[row]
            guard let indexPath = currentCellPosition else { return }
            translationDelegate?.requestTranslation(to: favoritesLanguages[row], at: indexPath)
        }
    }
}
extension RevisionCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        languagePicker.isUserInteractionEnabled = false
        languagePicker.selectRow(selectedRow, inComponent: 0, animated: false)
        deleteItem.isUserInteractionEnabled = false
        isBeingEdited = true
        guard let currentCellIndexPath = currentCellPosition else { return }
        lastCellPosition = currentCellIndexPath
        guard let uppestCell = tableView.visibleCells.first else { return }
        guard let uppestCellIndexPath = tableView.indexPath(for: uppestCell) else { return }
        uppestCellPosition = uppestCellIndexPath
        tableView.moveRow(at: currentCellIndexPath, to: uppestCellPosition)
        tableView.scrollToRow(at: uppestCellPosition, at: .none, animated: false)
        for visibleCell in tableView.visibleCells {
            let visibleCellIndexPath = tableView.indexPath(for: visibleCell)
            if visibleCellIndexPath != uppestCellPosition {
                visibleCell.alpha = 0.3
                visibleCell.isUserInteractionEnabled = false
            }
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        isBeingEdited = false
        tableView.moveRow(at: uppestCellPosition, to: lastCellPosition)
        tableView.scrollToRow(at: lastCellPosition, at: .none, animated: false)
        for visibleCell in tableView.visibleCells {
            visibleCell.isUserInteractionEnabled = true
            visibleCell.alpha = 1
        }
        if languagePicker.selectedRow(inComponent: 0) != favoritesItems.count-1 {
            container.alpha = 0
            associatedWord.isUserInteractionEnabled = true
            languagePicker.isUserInteractionEnabled = true
            deleteItem.isUserInteractionEnabled = true
            if let word = associatedWord.text {
                wordReplacemenDelegate?.replace(userWord: word, to: favoritesLanguages[languagePicker.selectedRow(inComponent: 0)], at: lastCellPosition)
            }
        }
    }
}
