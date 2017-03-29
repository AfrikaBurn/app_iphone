//
//  SecondViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit
import MapKit

struct Resources {
    static let mapOverlayImage: UIImage = {
        let path = Bundle.main.path(forResource: "AB2017_Layout_RoadsLabel_20170308", ofType: "png")!
        return UIImage(contentsOfFile: path)!
    }()
}

struct BurnMap {
    static let boundingMapRect: MKMapRect = MKMapRect(origin: MKMapPoint(x: 148937508.42330855, y: 159711548.54660633), size: MKMapSize(width: 9388.6817751824855, height: 7286.825931340456))
}

class SecondViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsUserLocation = true
    }
}

class BurnMapView: MKMapView, MKMapViewDelegate {
    
    let overlay = BurnMapOverlay()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        showsScale = true
        showsCompass = true
        delegate = self
        userTrackingMode = .followWithHeading
        add(overlay, level: .aboveRoads)
        setVisibleMapRect(BurnMap.boundingMapRect, animated: false)
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case is BurnMapOverlay: return BurnMapOverlayView(overlay: overlay, overlayImage: Resources.mapOverlayImage)
        default: return MKOverlayRenderer(overlay: overlay)
        }
    }
}

class BurnMapOverlay: NSObject, MKOverlay {
    let boundingMapRect: MKMapRect = BurnMap.boundingMapRect
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(19.751633252193361, -32.326217923051772)
    
    func canReplaceMapContent() -> Bool {
        return true
    }
}

class BurnMapOverlayView: MKOverlayRenderer {
    let overlayImage: UIImage
    
    init(overlay: MKOverlay, overlayImage: UIImage) {
        self.overlayImage = overlayImage
        super.init(overlay: overlay)
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let imageRef = overlayImage.cgImage else {
            return
        }
        let theMapRect = overlay.boundingMapRect
        let theRect = rect(for: theMapRect)
        
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -theRect.height)
        context.draw(imageRef, in: theRect)
    }
}