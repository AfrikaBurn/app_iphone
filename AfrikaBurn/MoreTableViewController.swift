//
//  MoreTableViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2018/03/26.
//  Copyright © 2018 AfrikaBurn. All rights reserved.
//

import UIKit
import MapKit
import SafariServices
import AVFoundation
import AVKit
import MediaPlayer
import StoreKit

class MoreTableViewController: UITableViewController {
    
    struct AppStoreReviewPromptHelper {
        var hasTappedACell: Bool = false
        
        var shouldPromptForAReview: Bool {
            return hasTappedACell
        }
    }

    struct URLs {
        static let survivalGuide = Bundle.main.url(forResource: "AB-SurvivalGuide-2018-English", withExtension: "pdf")!
        static let wtfGuide = Bundle.main.url(forResource: "WTF-Guide-2018", withExtension: "pdf")!
        static let weatherReport = URL(string: "https://www.yr.no/en/overview/daily/2-3360944/South%20Africa/Northern%20Cape/Namakwa%20District%20Municipality/Stonehenge")!
        static let tankwaFreeRadio: URL = URL(string: "http://capeant.antfarm.co.za:1935/tankwaradio/tankwaradio.stream/playlist.m3u8")!
    }
    
    struct IndexPaths {
        static let navigateToTheBurn = IndexPath(row: 0, section: 0)
        static let survivalGuide = IndexPath(row: 1, section: 0)
        static let wtfGuide = IndexPath(row: 2, section: 0)
        static let weatherReport = IndexPath(row: 3, section: 0)
        
        static let radioFreeTankwa = IndexPath(row: 0, section: 1)
    }
    
    var appStoreReviewPromptHelper = AppStoreReviewPromptHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        Style.apply(to: tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if appStoreReviewPromptHelper.shouldPromptForAReview {
            /// Thought it could be cool to prompt for
            /// reviews when a user has used some of our features and
            /// indicated a clear interest in the App
            if #available(iOS 10.3, *), LaunchArguments.preventAppStoreReviewPrompts == false {
                DispatchQueue.main.async {
                    SKStoreReviewController.requestReview()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = super.tableView(tableView, cellForRowAt: indexPath)
        Style.apply(to: c)
        return c
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            appStoreReviewPromptHelper.hasTappedACell = true
        }
        switch indexPath {
        case IndexPaths.navigateToTheBurn:
            let coordinate = CLLocationCoordinate2DMake(-32.3268322, 19.748085700000047)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
            mapItem.name = "AfrikaBurn"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        case IndexPaths.survivalGuide:
            let d = UIDocumentInteractionController(url: URLs.survivalGuide)
            d.name = "Survival Guide"
            d.delegate = self
            d.presentPreview(animated: true)
        case IndexPaths.wtfGuide:
            let d = UIDocumentInteractionController(url: URLs.wtfGuide)
            d.name = "WTF Guide"
            d.delegate = self
            d.presentPreview(animated: true)
        case IndexPaths.weatherReport:
            let safari = SFSafariViewController(url: URLs.weatherReport)
            present(safari, animated: true, completion: nil)
        case IndexPaths.radioFreeTankwa:
            let key = "afrikaburn.hasShownRadioFreeTankwaPlayerMessage"
            if UserDefaults.standard.bool(forKey: key) == false {
                let alert = UIAlertController(title: "Radio Free Tankwa", message: "The radio can play in the background so feel free to lock your phone and enjoy the tunes while you drive.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Lets Play", style: .default, handler: { (_) in
                    self.playTankwaRadio()
                    UserDefaults.standard.set(true, forKey: key)
                }))
                present(alert, animated: true, completion: nil)
            } else {
                playTankwaRadio()
            }
        default:
            assert(false)
        }
    }
    
    // MARK: - Radio Free Tankwa
    
    struct RadioFreeTankwa {
        struct NowPlayingInfo {
            let title = "Live Stream"
            let artist = "Radio Free Tankwa"
            let image = UIImage(named: "SplashScreen")!
        }
    }
    
    lazy var player: AVPlayer = {
        let p = AVPlayer(url: URLs.tankwaFreeRadio)
        return p
    }()
    var playerController: AVPlayerViewController?
    
    func playTankwaRadio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(convertFromAVAudioSessionCategory(AVAudioSession.Category.playback))
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
        func showController() {
            let controller = AVPlayerViewController()
            self.playerController = controller
            controller.player = player
            
            let playerImage = RadioFreeTankwa.NowPlayingInfo().image
            present(controller, animated: true) {
                self.player.play()
                self.updateNowPlayingInfoCenter()
                let v = UIImageView(image: playerImage)
                v.contentMode = .scaleAspectFill
                v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                v.frame = controller.contentOverlayView?.bounds ?? .zero
                controller.contentOverlayView?.addSubview(v)
            }
        }
        
        func playInline() {
            player.play()
            updateNowPlayingInfoCenter()
        }
        
        showController()
    }
    
    func updateNowPlayingInfoCenter() {
        guard player.status == .readyToPlay else {
            return
        }
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.player.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.player.pause()
            return .success
        }
        
        let nowPlayingCenter = MPNowPlayingInfoCenter.default()
        if nowPlayingCenter.nowPlayingInfo == nil {
            nowPlayingCenter.nowPlayingInfo = [:]
        }
        let info = RadioFreeTankwa.NowPlayingInfo()
        nowPlayingCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] = info.title
        nowPlayingCenter.nowPlayingInfo?[MPMediaItemPropertyArtist] = info.artist
        nowPlayingCenter.nowPlayingInfo?[MPMediaItemPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        let playerImage = info.image
        nowPlayingCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: playerImage.size, requestHandler: { (size) -> UIImage in
            return playerImage
        })
    }
    
    @objc func handleWillEnterBackground() {
        updateNowPlayingInfoCenter()
    }

}

extension MoreTableViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
