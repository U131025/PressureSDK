//
//  PlayerHelper.swift
//  Pressure
//
//  Created by mojingyu on 2019/1/31.
//  Copyright © 2019 Mojy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import AVFoundation

class PlayerHelper: NSObject, AVAudioPlayerDelegate {
    
    static let shared = PlayerHelper()
    
    var isEanble = BehaviorRelay<Bool>(value: true)
    
    fileprivate var disposeBag = DisposeBag()
    fileprivate var selectedIndex = 0
    var playFiles = [String]()
    
    var audioPlayer:AVAudioPlayer?
    
    override init() {
        super.init()
    }
    
    func play(files: [String]) {
        stop()
        
        if isEanble.value == false {
            return
        }
        
        playFiles = files
        
        self.selectedIndex = 0
        if let path = files.first {
            playFile(path)
        }
    }
    
    func playFile(_ fileName: String) {
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            // 启动音频会话的管理，此时会阻断后台音乐的播放
            try session.setActive(true)
            // 设置音频操作类别，标示该应用仅支持音频的播放
            try session.setCategory(AVAudioSession.Category.playback)

            // 设置应用程序支持接受远程控制事件
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            // 定义一个字符常量，描述声音文件的路经
            guard let path = Bundle.main.path(forResource: fileName, ofType: "mp3") else { return }
            
            // 将字符串路径，转换为网址路径
             let soudUrl = URL(fileURLWithPath: path)
            // 对音频播放对象进行初始化，并加载指定的音频文件
            try audioPlayer = AVAudioPlayer(contentsOf: soudUrl)
            audioPlayer?.prepareToPlay()
            audioPlayer?.delegate = self
            // 开始播放
            audioPlayer?.play()
            
        } catch{
            print(error)
        }
        
    }
    
    func stop() {
        playFiles.removeAll()

    }
    
    //
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        //播放下一条
        let index = self.selectedIndex + 1
        if index < self.playFiles.count {
            let path = self.playFiles[index]
            playFile(path)
            self.selectedIndex = index
        }

    }
}
