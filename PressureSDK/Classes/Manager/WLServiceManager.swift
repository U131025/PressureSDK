//
//  WLServiceManager.swift
//  PressureSDK
//
//  Created by 屋联-神兽 on 2020/12/21.
//

import Foundation
import RxSwift
import RxCocoa
import RxBluetoothKit

extension WLSendCommandType {
    public func send() {
        WLServiceManager.shared.send(data)
    }
}

public class WLServiceManager: NSObject {
    public static let shared = WLServiceManager()
    
    /// 当前连接设备
    public var device: ScannedPeripheral?
    
    /// 测试结果
    public var testStatus = PublishSubject<(time: Int, isEnd: Bool)>()
    
    private var disapsable: Disposable?
    private var disposeBag = DisposeBag()
    
    /// 加压模式设置参数
    public var pressureSettingModel = WLSettingModel().defaultData(.pressure)
    /// 智能模式设置参数
    public var smartSettingModel = WLSettingModel().defaultData(.intelligent)
    
    /// 当前蓝牙设备参数设置
    public var deviceConfig: DeviceConfigModel?
    
    /// 是否为分包处理
    public var isSplite: Bool = true
    fileprivate let sendQueue = OperationQueue()    //发送线程
    
    fileprivate var scheduler: ConcurrentDispatchQueueScheduler!
    fileprivate let manager = CentralManager(queue: .main)
        
    public override init() {
        super.init()
        
        sendQueue.maxConcurrentOperationCount = 1
        
        listen()
    }
    /// 监听设备返回数据
    public func listen() {
        HLBluetoothKitService.shared
            .updatedValueAndNotificationOutput
            .subscribe(onNext: {[weak self] (result) in
            
                if case let .success(chr) = result {
                    self?.respondHandle(data: chr.value)
                }
        
            }).disposed(by: disposeBag)
    }
    /// 扫描蓝牙设备
    public func scan() -> Observable<ScannedPeripheral> {
        return HLBluetoothKitService.shared.startScan()
    }
    
    /// 停止扫描
    public func stopScan() {
        HLBluetoothKitService.shared.stopScanning()
    }
    
    /// 连接设备
    public func connect(_ device: ScannedPeripheral) -> Observable<HLBluetoothResult<Peripheral, Error>> {
        return HLBluetoothKitService.shared
            .connect(for: device.peripheral, characteristicConfig: HLPeripheralCharacteristicConfig().then({ (config) in
                config.readChrUUIDStr = "FFF3"
                config.writeChrUUIDStr = "FFF1"
                config.notifyChrUUIDStr = "FFF3"
            }))
            .connectionResultOutput
            .do { (result) in
                if case .success = result {
                    self.device = device
                }
            }
    }
    
    /// 断开连接
    public func disconnect(_ device: ScannedPeripheral) {
        HLBluetoothKitService.shared.disconnect(device.peripheral)
    }
    
    public func send(_ data: Data?) {
        guard let device = self.device,
              let commandData = data else {
            return
        }
        
        sendData(data: commandData as NSData, device: device)
    }
    
    /// 发送数据
    ///
    /// - Parameters:
    ///   - data: 发送的数据
    ///   - type: 特征码类型
    public func sendData(data: NSData, device: ScannedPeripheral) {

        if isSplite == true  {
            
            /// 分包发送20一包
            let sendLen = data.length > 20 ? 20 : data.length
            if data.length > sendLen {
                
                let senddata = data.subdata(with: NSRange.init(location: 0, length: sendLen))
                let lastdata = data.subdata(with: NSRange.init(location: sendLen, length: data.length - sendLen))
                
                self.sendQueue.addOperation {
                    
                    let tempData: Data = senddata as Data
                    
                    self.writeValueForCharacteristic(data: tempData, device: device)
                    Thread.sleep(forTimeInterval: 0.1)
                }
                //            print("========\n lastdata: <\(lastdata.hexEncodedString())>")
                self.sendData(data: lastdata as NSData, device: device)
            }
            else {
                self.sendQueue.addOperation {
                    let tempData: Data = data as Data
                    
                    self.writeValueForCharacteristic(data: tempData, device: device)
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            
        }
        else {
            /// 一次性发送完
            self.sendQueue.addOperation {
                let tempData: Data = data as Data
                self.writeValueForCharacteristic(data: tempData, device: device)
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    /// 写数据
    ///
    /// - Parameters:
    ///   - data: 发送数据
    ///   - characteristic: 特征码
    fileprivate func writeValueForCharacteristic(data: Data, device: ScannedPeripheral) {
        
        _ = HLBluetoothKitService.shared.send(data: data, for: device.peripheral)
    }
    
    /// 返回数据处理
    ///
    /// - Parameter data: 返回的数据
    var respondBytes = [UInt8]()
    func respondHandle(data: Data?) {
        
        guard let tempData = data else {
            return
        }
                
        objc_sync_enter(self)
        
        let bytes:[UInt8] = [UInt8](tempData)
        //过滤掉不是0xa5开头的数据, 需要丢包
        if bytes.count > 0 {
            
            respondBytes += bytes
            
            if respondBytes[0] != CommandHeader1 {
                
                //需要遍历保证 respondBytes为Header开头的数据
                var pos = -1
                for (index, byte) in respondBytes.enumerated() {
                    
                    if byte == CommandHeader1 {
                        pos = index
                        break
                    }
                }
                
                if pos == -1 {
                    respondBytes.removeAll()
                }
                else {
                    let temp = respondBytes[pos..<respondBytes.count]
                    let data = Data.init(temp)
                    respondBytes = [UInt8](data)
                }
            }
            
            handleResult()
        }
        
        objc_sync_exit(self)
    }
    
    func handleResult() {
        
        guard let resultModel = RespondDataModel.convert(bytes: respondBytes) else {
            return
        }
        
        self.handleBluetoothRespond(resultModel)
        
        //截取剩余的
        if respondBytes.count >= resultModel.totalLength {
            let offset = resultModel.totalLength
            respondBytes.removeSubrange(0..<offset)
            handleResult()
        }
    }
    
    func handleBluetoothRespond(_ respond: RespondDataModel) {
        
        guard let commandType = WLBluetoothCommandType(rawValue: respond.command) else { return }
        
        switch commandType {
        case .splite:
            isSplite = true            
            send(WLSendCommandType.splitRespond.data)
                        
        case .realTime:
            handleRealTimeData(respond)
            
        case .sysn:
            //发送同步参数至设备
            send(WLSendCommandType.sysn(normal: pressureSettingModel, smart: smartSettingModel).data)
            
        case .voicePrompt:
            handleVoicePrompt(respond)
            
        default:
            break
        }
    }
    
    func handleRealTimeData(_ respond: RespondDataModel) {
        
        if respond.command != WLBluetoothCommandType.realTime.rawValue { return }
        
        guard let datas = respond.datas else { return }
        
        let config = DeviceConfigModel(datas)
                
        /// 未进入操作界面不进行其他操作，只记录当前状态
        if isHandleEvent == false { return }
        
        if config.isComplete == true {
            /// 发送结束命令
            send(WLSendCommandType.finish.data)
            
            /// 保存结束数据，发送结束命令后会返回0数据
            self.deviceConfig = config
            
            DispatchQueue.main.async {
                if config.workStatus == .failed {
                    PlayerHelper.shared.playFile("测试异常")
                }
                else if config.workStatus == .success {
                    PlayerHelper.shared.playFile("测试合格")
                }
            }
            
            /// 发送通知，界面跳转
//            let notificationName = NSNotification.Name(rawValue: UpdateServiceCardNofity)
//            NotificationCenter.default.post(name: notificationName, object: nil)
        }
        
    }
    
    var isHandleEvent = false
    func handleVoicePrompt(_ respond: RespondDataModel) {
        
        if isHandleEvent == false { return }
        if respond.command == WLBluetoothCommandType.voicePrompt.rawValue {
            
            if let type = respond.datas?.first {
                
                let isEnd: Bool = type % 2 == 0
                let index: Int = type % 2 == 0 ? Int(type) / 2 : Int(type+1) / 2
                
                let indexVoice = "\(index)"
                let endVoice = isEnd ? "阶段测试结束" : "阶段测试开始"
                PlayerHelper.shared.play(files: ["第", indexVoice, endVoice])
                self.testStatus.onNext((time: index, isEnd: isEnd))
                
            }
        }
    }
}
