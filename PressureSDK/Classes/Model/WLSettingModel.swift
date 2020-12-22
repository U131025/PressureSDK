//
//  SettingModel.swift
//  Pressure
//
//  Created by mac on 2019/2/18.
//  Copyright © 2019 Mojy. All rights reserved.
//

import Foundation
import Then

extension UIColor {
    
    public enum RGBType {
        case Red
        case Green
        case Blue
    }
    
    public var toHexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(
            format: "%02X%02X%02X",
            Int(r * 0xff),
            Int(g * 0xff),
            Int(b * 0xff)
        )
    }
    
    public convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
    
    public func getValue(type : RGBType) -> Int{
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        switch type {
        case .Red:
            return Int(r * 0xff)
        case .Green:
            return Int(g * 0xff)
        case .Blue:
            return Int(b * 0xff)
        }
    }
}

public class WLBaseModel: NSObject {
    
    public required override init() {
        super.init()
    }
}

public struct WLSettingConfig {
    public static var maxKg: Float {
        #if FIXED
        return 20
        #else
        return 16
        #endif
    }
}

public enum WLSettingModelType: String {
    case pressure
    case intelligent
    
    public var titleString: String {
        switch self {
        case .pressure:
            return "加压模式设置"
        default:
            return "智能模式设置"
        }
    }
}

public class WLSettingModel: WLBaseModel {
    
    //类型
    public var typeStr: String?
    public var type: WLSettingModelType {
        set {
            typeStr = newValue.rawValue
        }
        get {
            return WLSettingModelType(rawValue: self.typeStr ?? "") ?? .pressure
        }
    }
    
    public var groups = [WLGroupModel]()
}

public class WLSettingAuthModel: WLBaseModel {
    
    public var user: String?
    public var password: String?
}

extension WLSettingModel {
        
    public func defaultData(_ type: WLSettingModelType) -> WLSettingModel {
        
        self.type = type
        self.groups.append(WLGroupModel().then({ (group) in
            group.index = 1
            group.kg = 8
            
            #if Yangzi
            group.t = 5
            #elseif HuaNing
            group.t = 5
            #else
            group.t = 30
            #endif
            
            #if FIXED
            group.kg = 16
            group.t = type == .intelligent ? 15 : 30
            #endif
                                    
            group.type = type
            
            group.defaultItems()
        }))
        
        self.groups.append(WLGroupModel().then({ (group) in
            group.index = 2
            group.kg = 10
            group.t = 30
            group.type = type
                        
            #if FIXED
            group.kg = 18
            group.t = type == .intelligent ? 20 : 30
            #endif
                        
            group.defaultItems()
        }))
        
        self.groups.append(WLGroupModel().then({ (group) in
            group.index = 3
            group.kg = 12
            group.t = 30
            group.type = type
            
            #if FIXED
            group.kg = 20
            #endif
            
            group.defaultItems()
        }))
        
        return self
    }
}

public enum WLSettingColorModelType: Int {
    case red = 1
    case blue
    case yellow
    
    public var color: UIColor {
        switch self {
        case .red:
            return .init(hex: "D4362E")
        case .blue:
            return UIColor.init(hex: "2085CA")
        case .yellow:
            return UIColor(hex: "EC9A28")
        }
    }
    
    public var description: String {
        switch self {
        case .red:
            return "红色模式设置"
        case .blue:
            return "蓝色模式设置"
        case .yellow:
            return "黄色模式设置"
        }
    }
    
}
