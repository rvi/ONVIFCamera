//
//  UIView+AlertExtension.swift
//  ONVIFCamera
//
//  Created by Mohamed Arradi on 6/8/18.
//  Copyright © 2018 Mohamed ARRADI-ALAOUI. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func presentError(with text: String) {
        let alert = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
