//
//  KeyboardHandlingViewController.swift
//  Tracker
//
//  Created by Yakov Nemychenkov on 28.08.2023.
//

import UIKit

class KeyboardHandlingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHideKeyboardOnTap()
    }
    
    private func setupHideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}
