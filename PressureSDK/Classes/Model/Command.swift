//
//  Command.swift
//  Pressure
//
//  Created by mac on 2019/1/23.
//  Copyright © 2019 Mojy. All rights reserved.
//

import UIKit

public enum WLBluetoothCommandType: UInt8 {
    case realTime = 0x01
    case sysn = 0x02
    case voicePrompt = 0x03
    
    case pressureModeSetting = 0x10
    case intelligentModelSetting = 0x20
    
    case finish = 0x40
    case splite = 0x04
}

public enum WLSendCommandType {
    case realTime
    case sysn(normal: WLSettingModel, smart: WLSettingModel)
    case voicePrompt
    
    case pressureModeSetting(WLSettingModel)
    case intelligentModelSetting(WLGroupModel)
    
    case chooseModel(type: WLSettingModelType, groupIndex: UInt8)
    
    /// 清除指令
    case finish
    case splitRespond
}

public extension WLSendCommandType {
    
    var data: Data {
        
        switch self {
        case let .chooseModel(type, groupIndex):
            let data0: UInt8 = type == .pressure ? 0x01: 0x02
            let data1 = groupIndex
            
            return RequestModel(0x30, [data0, data1]).commandData
            
        case .pressureModeSetting(let model):
            var configDatas: [UInt8] = []
            
//            let model = WLSettingModel.recover(.pressure)
            for group in model.groups {
                configDatas.append(group.kg)
                configDatas.append(group.t)
            }
            
            return RequestModel(0x10, configDatas).commandData
            
        case .intelligentModelSetting(let group):
            var configDatas: [UInt8] = []
            
            configDatas.append(group.index)
            configDatas.append(group.kg)
            
            group.items.forEach { (item) in
                configDatas.append(item.t)
                configDatas.append(item.d)
                configDatas.append(item.j)
            }
            
            return RequestModel(0x20, configDatas).commandData
            
        case let .sysn(pressureModel, smartModel):
            
            var configDatas: [UInt8] = []
            
//            let pressureModel = SettingModel.recover(.pressure)
            for group in pressureModel.groups {
                configDatas.append(group.kg)
                configDatas.append(group.t)
            }
            
//            let smartModel = SettingModel.recover(.intelligent)
            for group in smartModel.groups {
                configDatas.append(group.kg)
                
                group.items.forEach { (item) in
                    configDatas.append(item.t)
                    configDatas.append(item.d)
                    configDatas.append(item.j)
                }
            }
            
            return RequestModel(0x50, configDatas).commandData
            
        case .finish:
            return RequestModel(0x40, [0x00]).commandData
            
        case .splitRespond:
            return RequestModel(0x60, [0x01]).commandData
            
        default:
            return Data()
        }
    }    
}

/// 加压模式
public class WLKGModel: NSObject {
    
    /// KG值
    public var kg: UInt8 = 0x00
    /// 时间
    public var t: UInt8 = 0x00
    /// 压降
    public var d: UInt8 = 0x00
    /// 自动判断选择
    public var j: UInt8 = 0x00
    
    /// 类型
    public var type: WLSettingColorModelType  = .red
    
    /// 序号
    public var index: Int = 0
    
    /// 自动判断
    public var isAuto: Bool = false {
        didSet {
            j = isAuto ? 0x01 : 0x00
        }
    }
    
    public var isDisplay:Bool = true
    //加压模式
    public var pressureModeBytes: [UInt8] {
        return [kg, t]
    }
    
    //智能模式
    public var intelligentModel: [UInt8] {
        return [t, d, j]
    }
}

public class WLGroupModel: NSObject {
    
    /// GROUP：第一组：0x01  第二组：0x02  第三组：0x03
    public var index: UInt8 = 0x00
    
    /// KG值
    public var kg: UInt8 = 0x00
    
    /// 时间
    public var t: UInt8 = 0x00
    
    /// 类型
    public var typeStr: String?
    public var type: WLSettingModelType {
        set {
            typeStr = newValue.rawValue
        }
        get {
            return WLSettingModelType(rawValue: typeStr ?? "") ?? .pressure
        }
    }
    
    /// 颜色模式
    public var colorType: WLSettingColorModelType?
    
    /// 组
    public var items = [WLKGModel]()
}

extension WLGroupModel {
    
    public func defaultItems() {
        
        self.items.removeAll()
        
        for index in 0..<5 {
            self.items.append(WLKGModel().then({[unowned self] (model) in
                model.kg = self.kg
                model.d = 10
                model.index = index + 1
                
                model.type = WLSettingColorModelType(rawValue: Int(self.index)) ?? .red
                if model.index == 2 {
                    model.isAuto = true
                    model.isDisplay = false
                }
                
                switch index {
                case 0:

                    #if FIXED
                    model.t = 15
                    #else
                    model.t = 5
                    #endif
                case 1:

                    #if FIXED
                    model.t = 20
                    #else
                    model.t = 25
                    #endif
                default:
                    model.t = 0
                }
            }))
        }
    }
    
}
