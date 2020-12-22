//
//  RespondModel.swift
//  Pressure
//
//  Created by mac on 2019/1/23.
//  Copyright © 2019 Mojy. All rights reserved.
//

import UIKit

/// 返回数据头
let CommandHeader1: UInt8 = 0x57
let CommandHeader2: UInt8 = 0x50
let CommandHeader3: UInt8 = 0x47

/// 请求数据头
let requestHeaderByte1: UInt8 = 0x41
let requestHeaderByte2: UInt8 = 0x54

/// 返回数据结构
public class RespondDataModel: NSObject {

    var command: UInt8 = 0
    var length: UInt8 = 0
    var datas: [UInt8]?
    
    public var totalLength: Int {
        return Int(length + 4)
    }
    
    init(_ command: UInt8, _ datas: [UInt8]) {
        super.init()
        
        self.command = command
        self.length = UInt8(datas.count)
        self.datas = datas
    }
    
    public class func convert(bytes: [UInt8]) -> RespondDataModel? {
        
        if bytes.count < 5 { return nil }
        
        //        var bytes:[UInt8] = [UInt8](data)
        if bytes[0] != CommandHeader1 &&
            bytes[1] != CommandHeader2 &&
            bytes[2] != CommandHeader3 {
            return nil
        }

        let command = bytes[3];
        let length = bytes[4] // 数据头，尾，命令行，长度，校验位，每个1个字节,数据的字节
     
        if length + 5 > bytes.count {
            //数据未接收完成
            return nil
        }
        
        var respondData = [UInt8]()
        let contentLent = Int(length)
        if contentLent > 0 {
            for i in 0..<contentLent {
                if i < bytes.count {
                    respondData.append(bytes[i+5])
                }
            }
        }
       
        return RespondDataModel(command, respondData)
    }
}

/// 请求数据结构
class RequestModel: NSObject {
    
    var command: UInt8 = 0
    var length: UInt8 = 0
    var datas: [UInt8]?
    
    init(_ command: UInt8 = 0x00, _ datas: [UInt8] = []) {
        super.init()
        
        self.command = command
        self.length = UInt8(datas.count)
        self.datas = datas
    }
    
    var commandBytes: [UInt8] {
        
        var commands = [UInt8]()
        commands.append(requestHeaderByte1)
        commands.append(requestHeaderByte2)
        commands.append(command)
        
        if let datas = self.datas {
            let len = UInt8(datas.count)
            commands.append(command == 0x20 ? 0x15 : len)
            commands += datas
        }
        else {
            commands.append(0x00)
        }
        
        return commands
    }
    
    var commandData: Data {
        return Data(commandBytes)
    }
    
}
