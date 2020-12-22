//
//  RxBluetoothService.swift
//  SmartLock
//
//  Created by mac on 2020/1/6.
//  Copyright © 2020 mac. All rights reserved.
//

import Foundation
import RxBluetoothKit
import RxSwift
import RxCocoa
import CoreBluetooth
import Then

extension String {
    public var uuid: CBUUID {
        return CBUUID(string: self)
    }
}

public class HLPeripheralCharacteristicConfig: NSObject {
    public var writeChrUUIDStr: String?
    public var readChrUUIDStr: String?
    public var notifyChrUUIDStr: String?
    public var writeChr: Characteristic?
    public var readChr: Characteristic?
    public var notifyChr: Characteristic?
    public func addCharacteristic(_ chr: Characteristic?) {

        guard let chr = chr else { return }
        if chr.uuid.uuidString.uppercased() == writeChrUUIDStr?.uppercased() {
            writeChr = chr
        }
        if chr.uuid.uuidString.uppercased() == readChrUUIDStr?.uppercased() {
            readChr = chr
        }
        if chr.uuid.uuidString.uppercased() == notifyChrUUIDStr?.uppercased() {
            notifyChr = chr
        }
    }

    public func isNotifyChr(_ chr: Characteristic?) -> Bool {
        guard let chr = chr else { return false }
        if chr.uuid.uuidString.uppercased() == notifyChrUUIDStr?.uppercased() {
            return true
        }
        return false
    }
}

public class HLBluetoothKitService {

    public static let shared = HLBluetoothKitService()

    //发送线程
    private let sendQueue = OperationQueue().then { (queue) in
        queue.maxConcurrentOperationCount = 1
    }

    public typealias Disconnection = (Peripheral, DisconnectionReason?)

    public var peripheralsDic = [String: ScannedPeripheral]()
    public var autoDisposeBag = DisposeBag()

    // MARK: - Public outputs
    public var scanningOutput: Observable<ScannedPeripheral> {
        return scanningSubject.share(replay: 1, scope: .forever).asObservable()
    }

    public var connectionResultOutput: Observable<HLBluetoothResult<Peripheral, Error>> {
        return connectionResultSubject.asObservable()
    }

    public var disconnectionReasonOutput: Observable<HLBluetoothResult<Disconnection, Error>> {
        return disconnectionSubject.asObservable()
    }

    public var discoveredCharacteristicsOutput: Observable<Characteristic> {
        return discoveredCharacteristicsSubject.asObservable()
    }

    public var readValueOutput: Observable<HLBluetoothResult<Characteristic, Error>> {
        return readValueSubject.asObservable()
    }

    public var writeValueOutput: Observable<HLBluetoothResult<Characteristic, Error>> {
        return writeValueSubject.asObservable()
    }

    // 通知输出
    public var updatedValueAndNotificationOutput: Observable<HLBluetoothResult<Characteristic, Error>> {
        return updatedValueAndNotificationSubject.asObservable()
    }

    // MARK: - Private subjects
    private let discoveredCharacteristicsSubject = PublishSubject<Characteristic>()

    private let scanningSubject = PublishSubject<ScannedPeripheral>()

    private let connectionResultSubject = PublishSubject<HLBluetoothResult<Peripheral, Error>>()

    private let disconnectionSubject = PublishSubject<HLBluetoothResult<Disconnection, Error>>()

    private let readValueSubject = PublishSubject<HLBluetoothResult<Characteristic, Error>>()

    private let writeValueSubject = PublishSubject<HLBluetoothResult<Characteristic, Error>>()

    private let updatedValueAndNotificationSubject = PublishSubject<HLBluetoothResult<Characteristic, Error>>()

    // MARK: - Private fields

    private let centralManager = CentralManager(queue: .main)

    private let scheduler: ConcurrentDispatchQueueScheduler

    private var disposeBag = DisposeBag()

    private var peripheralConnections: [Peripheral: Disposable] = [:]

    private var scanningDisposable: Disposable?

//    private var connectionDisposable: Disposable!

    private var notificationDisposables: [Characteristic: Disposable] = [:]

    private var peripheralCharacteristics: [Peripheral: HLPeripheralCharacteristicConfig] = [:]

    // MARK: - Initialization
    public init() {
        let timerQueue = DispatchQueue(label: "com.polidea.rxbluetoothkit.timer")
        scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
    }
    // MARK: 扫描
    public func startScan(serviceUUIDs: [CBUUID]? = nil) -> Observable<ScannedPeripheral> {

        peripheralsDic.removeAll()
        stopScanning()

        scanningDisposable = centralManager
            .observeState()
            .startWith(centralManager.state)
            .filter { $0 == .poweredOn }
            .subscribeOn(MainScheduler.instance)
            .flatMap({ [weak self] _ -> Observable<ScannedPeripheral> in
                guard let `self` = self else {
                    return Observable.empty()
                }

                return self.centralManager.scanForPeripherals(withServices: serviceUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            })
            .subscribe(onNext: { [weak self] scannedPeripheral in
                guard let `self` = self else {
                    return
                }

                // 需要根据identifier进行过滤
                let key = scannedPeripheral.peripheral.identifier.uuidString.uppercased()

                if self.peripheralsDic[key] == nil {
                    self.scanningSubject.onNext(scannedPeripheral)
                }
                self.peripheralsDic[key] = scannedPeripheral
            })

        return scanningOutput
    }

    public func stopScanning() {
        scanningDisposable?.dispose()
    }

    // MARK: 连接
    public func connect(for peripheral: Peripheral, serviceUUIDs: [CBUUID]? = nil, characteristicConfig: HLPeripheralCharacteristicConfig? = nil) -> Self {

        let isConnected = peripheral.isConnected
        if isConnected == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[weak self] in
                self?.connectionResultSubject.onNext(HLBluetoothResult.success(peripheral))
            }
            return self
        }
        peripheralCharacteristics[peripheral] = characteristicConfig

        let disposable = peripheral.establishConnection()
            .do(onNext: {[weak self] (peripheral) in

                self?.observeDisconnect(for: peripheral)

                if peripheral.isConnected {
                    self?.connectionResultSubject.onNext(HLBluetoothResult.success(peripheral))
                } else {
                    self?.connectionResultSubject.onNext(HLBluetoothResult.error(RxError.noElements))
                }
            })
            .flatMap { $0.discoverServices(serviceUUIDs) }
            .flatMap({ (services) -> Observable<Characteristic> in
                return Observable.create { (obs) -> Disposable in

                    var disposabels = [Disposable]()
                    for service in services {

                        let disposabel = service
                            .discoverCharacteristics(nil)
                            .subscribe(onSuccess: { (characteristics) in

                                characteristics.forEach { (char) in
                                    obs.onNext(char)
                                }
                            })

                        disposabels.append(disposabel)
                    }

                    return Disposables.create(disposabels)
                }
            })
            .subscribe(onNext: {[weak self] (chr) in
                guard let `self` = self else { return }

                self.discoveredCharacteristicsSubject.onNext(chr)

                if let config = self.peripheralCharacteristics[peripheral] {

                    config.addCharacteristic(chr)
                    if config.isNotifyChr(chr) {

                        // 开启通知
                        self.observeValueUpdateAndSetNotification(for: chr)
                        self.observeNotifyValue(peripheral: peripheral, characteristic: chr)
                    }
                }

            }, onError: { (_) in

            })

        peripheralConnections[peripheral] = disposable

        return self
    }

    public func disconnect(_ peripheral: Peripheral) {
        guard let disposable = peripheralConnections[peripheral] else {
            return
        }
        disposable.dispose()
        peripheralConnections[peripheral] = nil
        peripheralCharacteristics[peripheral] = nil
    }

    public func autoConnected(_ peripheral: Peripheral) {

        disconnectionSubject
            .subscribe(onNext: {[weak self] (result) in

                guard let `self` = self else { return }
                if case let .success(disconnection) = result {

                    if disconnection.0.peripheral.identifier == peripheral.identifier {

                        if let config = self.peripheralCharacteristics[peripheral] {
                            _ = self.connect(for: peripheral, characteristicConfig: config)
                        } else {
                            _ = self.connect(for: peripheral)
                        }
                    }
                }

            }).disposed(by: autoDisposeBag)
    }

    // 监听断开连接状态
    private func observeDisconnect(for peripheral: Peripheral) {
        centralManager.observeDisconnect(for: peripheral).subscribe(onNext: { [unowned self] (peripheral, reason) in
            self.disconnectionSubject.onNext(HLBluetoothResult.success((peripheral, reason)))
            self.disconnect(peripheral)
        }, onError: { [unowned self] error in
            self.disconnectionSubject.onNext(HLBluetoothResult.error(error))
        }).disposed(by: disposeBag)
    }

    //
    // MARK: - Reading from and writing to a characteristic
    public func readValueFrom(_ characteristic: Characteristic) {
        characteristic.readValue().subscribe(onSuccess: { [unowned self] characteristic in
            self.readValueSubject.onNext(HLBluetoothResult.success(characteristic))
        }, onError: { [unowned self] error in
            self.readValueSubject.onNext(HLBluetoothResult.error(error))
        }).disposed(by: disposeBag)
    }

    public func writeValueTo(characteristic: Characteristic, data: Data) {
        guard let writeType = characteristic.determineWriteType() else {
            return
        }

        characteristic
            .writeValue(data, type: writeType)
            .subscribe(onSuccess: { [unowned self] characteristic in
                self.writeValueSubject.onNext(HLBluetoothResult.success(characteristic))

                }, onError: { [unowned self] error in
                    self.writeValueSubject.onNext(HLBluetoothResult.error(error))

            }).disposed(by: disposeBag)
    }

    // MARK: - Characteristic notifications

    // observeValueUpdateAndSetNotification(:_) returns a disposable from subscription, which triggers notifying start
    // on a selected characteristic.
    public func observeValueUpdateAndSetNotification(for characteristic: Characteristic) {
        if notificationDisposables[characteristic] != nil {
            self.updatedValueAndNotificationSubject.onNext(HLBluetoothResult.error(RxBluetoothServiceError.redundantStateChange))
        } else {
            let disposable = characteristic.observeValueUpdateAndSetNotification()
            .subscribe(onNext: { [weak self] (characteristic) in
                print("\n===== 🚖 ble respond data: \(String(describing: characteristic.value))")
                self?.updatedValueAndNotificationSubject.onNext(HLBluetoothResult.success(characteristic))
            }, onError: { [weak self] (error) in
                self?.updatedValueAndNotificationSubject.onNext(HLBluetoothResult.error(error))
            })

            notificationDisposables[characteristic] = disposable
        }
    }

    public func disposeNotification(for characteristic: Characteristic) {
        if let disposable = notificationDisposables[characteristic] {
            disposable.dispose()
            notificationDisposables[characteristic] = nil
        } else {
            self.updatedValueAndNotificationSubject.onNext(HLBluetoothResult.error(RxBluetoothServiceError.redundantStateChange))
        }
    }

    // observeNotifyValue tells us when exactly a characteristic has changed it's state (e.g isNotifying).
    // We need to use this method, because hardware needs an amount of time to switch characteristic's state.
    public func observeNotifyValue(peripheral: Peripheral, characteristic: Characteristic) {
        peripheral.observeNotifyValue(for: characteristic)
        .subscribe(onNext: { [unowned self] (characteristic) in
            self.updatedValueAndNotificationSubject.onNext(HLBluetoothResult.success(characteristic))
        }, onError: { [unowned self] (error) in
            self.updatedValueAndNotificationSubject.onNext(HLBluetoothResult.error(error))
        }).disposed(by: disposeBag)
    }

}

extension HLBluetoothKitService {

    // 发送数据
    public func send(data: Data, for peripheral: Peripheral) -> Self {

        guard let config = peripheralCharacteristics[peripheral], let chr = config.writeChr else {
            return self
        }

        writeValueTo(characteristic: chr, data: data)

        return self
    }
    // 批量发送
    public func send(datas: [Data], for peripheral: Peripheral) -> Self {

        guard let config = peripheralCharacteristics[peripheral], let chr = config.writeChr else {
            return self
        }

        for data in datas {

            sendQueue.addOperation { [unowned self] in
                self.writeValueTo(characteristic: chr, data: data)
                Thread.sleep(forTimeInterval: 0.10)
            }
        }

        return self
    }

}

public enum RxBluetoothServiceError: Error {
    case redundantStateChange
}
