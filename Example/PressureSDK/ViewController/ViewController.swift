//
//  ViewController.swift
//  PressureSDK
//
//  Created by 屋联-神兽 on 12/18/2020.
//  Copyright (c) 2020 屋联-神兽. All rights reserved.
//

import UIKit
import HLUIKit

class ViewController: HLTableViewController {
    
    let scanButton = UIButton().setTitle("扫描").setFont(.pingfang(ofSize: 15)).setTitleColor(.black)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = "蓝牙设备"
        viewModel = DeviceListViewModel()
        
        setNavRightItem(scanButton)
            .subscribe(onNext: { (_) in
                self.viewModel?.refresh()
            })
            .disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

