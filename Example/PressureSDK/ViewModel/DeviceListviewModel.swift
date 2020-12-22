//
//  DeviceListviewModel.swift
//  PressureSDK_Example
//
//  Created by 屋联-神兽 on 2020/12/22.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import HLUIKit
import PressureSDK
import RxSwift
import RxCocoa
import RxBluetoothKit

extension ScannedPeripheral: HLCellType {
    
    var localName: String? {
        return advertisementData.localName ?? peripheral.name
    }
    
    public var cellClass: AnyClass {
        return DefaultTextTableViewCell.self
    }
    
    public var cellHeight: CGFloat {
        return 50
    }
    
    public var cellData: Any? {
        return TextCellConfig().then { (config) in
            config.text = localName
            config.textColor = .black
        }
    }
}

class DeviceListViewModel: HLViewModel {
    
    // 扫描到的设备
    private var peripherals = [ScannedPeripheral]()
        
    override func refresh() {
        super.refresh()
        
        DefaultWireframe.shared.showWaitingJuhua()
        
        peripherals.removeAll()
        
        WLServiceManager.shared
            .scan()
            .filter({ (scanner) -> Bool in
                if let name = scanner.peripheral.name {
                    return name.count > 0
                }
                return false
            })
            .subscribe(onNext: { (scanner) in
                
                DefaultWireframe.shared.dismissJuhua()
                
                self.peripherals.append(scanner)
                self.setupData()
        
            }).disposed(by: disposeBag)
    }
    
    func setupData() {
        _ = setItems(self.peripherals)
    }
    
    override func cellConfig(_ cell: HLTableViewCell, _ indexPath: IndexPath) {
        if let cell = cell as? DefaultTextTableViewCell {
            _ = cell.addBorderLine(direction: .bottom, color: .lightGray)
        }
    }
    
    override func itemSelected(_ type: HLCellType) {
        if let scanner = type as? ScannedPeripheral {
            
            DefaultWireframe.shared.showWaitingJuhua()
            
            disposable?.dispose()
            disposable = WLServiceManager.shared
                .connect(scanner)
                .subscribe(onNext: { (result) in
                    
                    DefaultWireframe.shared.dismissJuhua()
                
                    if case .success = result {
                        self.viewController?.push(TestViewController())
                    }
                })
        }
    }
}
