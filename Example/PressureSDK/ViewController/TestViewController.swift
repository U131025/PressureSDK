//
//  TestViewController.swift
//  PressureSDK_Example
//
//  Created by 屋联-神兽 on 2020/12/22.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import HLUIKit
import PressureSDK

class TestViewController: HLTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = "测试界面"
        viewModel = TestViewModel()
    }
    

}
