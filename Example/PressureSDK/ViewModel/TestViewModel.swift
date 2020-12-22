//
//  TestViewModel.swift
//  PressureSDK_Example
//
//  Created by 屋联-神兽 on 2020/12/22.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import HLUIKit
import PressureSDK

class TestViewModel: HLViewModel {
    
    enum EventType: Int {
        /// 加压模式
        case pressureTesting = 1000
        /// 智能模式
        case smartTesting
    }
    
    /// 加压模式设置参数
    var pressureSettingModel = WLSettingModel().defaultData(.pressure)
    
    /// 智能模式设置参数
    var smartSettingModel = WLSettingModel().defaultData(.intelligent)

    
    override func refresh() {
        
        var items = [HLCellType]()
        items.append("加压模式测试")
        items.append("智能模式测试")
        
        _ = setItems(items)
    }
    
    override func cellConfig(_ cell: HLTableViewCell, _ indexPath: IndexPath) {
        _ = cell.addBorderLine(direction: .bottom, color: .lightGray)
    }
    
    override func itemSelected(indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            /// 加压模式第一组测试
            WLSendCommandType.chooseModel(type: .pressure, groupIndex: 1).send()
        case 1:
            /// 智能模式第一组测试
            WLSendCommandType.chooseModel(type: .pressure, groupIndex: 1).send()
        default:
            break
        }
    }
}
