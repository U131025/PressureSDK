//
//  DeviceConfigModel.swift
//  Pressure
//
//  Created by mac on 2019/2/26.
//  Copyright © 2019 Mojy. All rights reserved.
//

import Foundation

extension Array {
    public subscript (safe index: Int) -> Element? {
        if index < 0 { return nil }
        return index < count ? self[index] : nil
    }
}

public enum WorkModelType: UInt8 {
    case none = 0
    case pressure = 1
    case intelligent = 2
}

/// 当前的工作状态，0：没有测试，1：正在测试2：测试不合格，3：测试合格。（必须在DATA0为2时才有效。）
public enum WorkStatus: UInt8 {
    case none = 0x00
    case testing = 0x01
    case failed = 0x02
    case success = 0x03
    
    public var description: String {
        switch self {
        case .none:
            return "等待"
        case .testing:
            return "测试"
        case .failed:
            return "异常"
        case .success:
            return "合格"
        }
    }
    
    public var statusValue: Int {
        switch self {
        case .none:
            return -1
        case .testing:
            return -1
        case .failed:
            return 0
        case .success:
            return 1
        }
    }
}

extension Array {
    
    public func IntValue() -> Int {
 
        if self.count >= 2 {
            if let high = self[0] as? UInt8, let low = self[1] as? UInt8 {
                let value:Int = (Int(high) << 8) & 0xff00 + Int(low) & 0xff
                return value
            }
        }
        
        return 0
    }
    
}

/// 蓝牙设备参数设置模型
public class DeviceConfigModel: NSObject {
    
    /// 当前工作的是哪种模式， 0：不工作， 1.加压模式， 2. 智能模式。
    public var workModel: WorkModelType = .none
    /// 工作在哪第几组设定值。（共三组）
    public var workModelIndex: Int = 0
    
    /// 当前的工作状态，0：没有测试，1：正在测试2：测试不合格，3：测试合格。（必须在DATA0为2时才有效。）
    public var workStatus: WorkStatus = .none
    
    ///当前是第几次测试。（只在智能模式中用到）
    public var testTime: Int = 0
    
    /// 当前压力值。高位，低位。（实时更新）
    public var currentValue: Int = 0
    /// 开始压力值。高位，低位。（测试完成后，判断合不合格时才用到。）
    public var startValue: Int = 0
    /// 结束压力值。高位，低位。（测试完成后，判断合不合格时才用到。）
    public var endValue: Int = 0
    /// 开始测试时间。时，分（智能模式才用到。）
    public var startTimeHours: Int = 0
    public var startTimeMinutes: Int = 0
    ///  实时时间。时，分（用来在APP上显示）
    public var realTimeHours: Int = 0
    public var realTimeMinutes: Int = 0
    
    public init(_ bytes: [UInt8]) {
        super.init()
        
        if bytes.count < 14 {
            print("数据长度不正确")
            return
        }
        
        guard let workModelValue = bytes[safe: 0],
            let workModelIndexValue = bytes[safe: 1],
            let workStatusValue = bytes[safe: 2],
            let testTimeValue = bytes[safe: 3],
            let currentValueH = bytes[safe: 4], let currentValueL = bytes[safe: 5],
            let startValueH = bytes[safe: 6], let startValueL = bytes[safe: 7],
            let endValueH = bytes[safe: 8], let endValueL = bytes[safe: 9],
            let startTimeHoursValue = bytes[safe: 10],
            let startTimeMinutesValue = bytes[safe: 11],
            let realTimeHoursValue = bytes[safe: 12],
            let realTimeMinutesValue = bytes[safe: 13]
            else {
            return
        }
        
        workModel = WorkModelType(rawValue: workModelValue) ?? .none
        workModelIndex = Int(workModelIndexValue)
        workStatus = WorkStatus(rawValue: workStatusValue) ?? .none
        testTime = Int(testTimeValue)
        
        currentValue = [currentValueH, currentValueL].IntValue()
        startValue = [startValueH, startValueL].IntValue()
        endValue = [endValueH, endValueL].IntValue()
        
        startTimeHours = Int(startTimeHoursValue & 0xff)
        startTimeMinutes = Int(startTimeMinutesValue & 0xff)
        
        realTimeHours = Int(realTimeHoursValue & 0xff)
        realTimeMinutes = Int(realTimeMinutesValue & 0xff)
    }
    
    public var isEmpty: Bool {
        
        return startValue == 0 && endValue == 0 && workModel == .none
    }
    
    public var isTesting: Bool {
        
//        testing
        if workModel != .none {
            return true
        }
//        if workStatus == .testing {
//            return true
//        }
        return false
    }
    
    public var isComplete: Bool {
               
        if workStatus == .failed || workStatus == .success {
            return true
        }
        return false
    }
    
    public var durationMinutes: Int {
        return startTimeHours * 60 + startTimeMinutes
    }
    
    public var resultDes: String {
        return workStatus.description        
    }
}

