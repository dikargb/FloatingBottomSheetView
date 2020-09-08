//
//  ViewController.swift
//  FloatingBottomSheetViewExample
//
//  Created by Sinar Nirmata on 02/09/20.
//  Copyright © 2020 Sinar Nirmata. All rights reserved.
//

import FloatingBottomSheetView
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.lightGray
        
        let collapsedView = UIView()
        collapsedView.backgroundColor = .systemTeal
        let expandedView = UIView()
        expandedView.backgroundColor = .magenta
        
        let floatingView = FloatingBottomSheetView(initView: collapsedView,
                                                   expandedView: expandedView)
        floatingView.minimumHeight = 72 // set sheet's minimum height
        floatingView.maximumHeight = 270 // set sheet's maximum height
        floatingView.minimumInset = 0 // set sheet's minimum inset for expanded state (usually 0)
        floatingView.maximumInset = 16 // set sheet's maximum inset for collapsed state
        floatingView.configure(in: view)
    }
}

