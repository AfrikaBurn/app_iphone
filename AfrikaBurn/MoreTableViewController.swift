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

class MoreTableViewController: UITableViewController {

    struct URLs {
        static let survivalGuide = Bundle.main.url(forResource: "AB-SurvivalGuide-2018-English", withExtension: "pdf")!
        static let weatherReport = URL(string: "http://www.yr.no/place/South_Africa/Northern_Cape/Stonehenge/")!
        static let tankwaFreeRadio: URL = URL(string: "http://capeant.antfarm.co.za:1935/tankwaradio/tankwaradio.stream/playlist.m3u8")!
    }
    
    struct IndexPaths {
        static let navigateToTheBurn = IndexPath(row: 0, section: 0)
        static let survivalGuide = IndexPath(row: 1, section: 0)
        static let weatherReport = IndexPath(row: 2, section: 0)
        
        static let radioFreeTankwa = IndexPath(row: 0, section: 1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        Style.apply(to: tableView)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = super.tableView(tableView, cellForRowAt: indexPath)
        Style.apply(to: c)
        return c
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
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
