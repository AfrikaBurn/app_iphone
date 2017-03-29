//
//  MapViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

struct Resources {
    static let mapOverlayImage: UIImage = {
        let path = Bundle.main.path(forResource: "AB2017_Layout_RoadsLabel_20170308", ofType: "png")!
        return UIImage(contentsOfFile: path)!
    }()
}

struct BurnMap {
    static let boundingMapRect: MKMapRect = MKMapRect(origin: MKMapPoint(x: 148937508.42330855, y: 159711548.54660633), size: MKMapSize(width: 9388.6817751824855, height: 7286.825931340456))
}

class MapViewController: UIViewController {
    
    var selectedElement : AfrikaBurnElement? = nil
    @IBOutlet weak var mapView: MKMapView!
    let persistentStore = PersistentStore()
    let locationManager = CLLocationManager()
    lazy var allElements: Results<AfrikaBurnElement> = self.persistentStore.elements()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
        mapView.delegate = self
    
        loadElements()
        
        self.navigationItem.title = "Map"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadElements()
    }
    
    func loadElements(){
        NSLog("load elements")
        
        for element in allElements {
            guard let locationString = element.locationString else {
                continue
            }
            
            if locationString.range(of:",") == nil{
                continue
            }
            
//            let coordinates = locationString.characters.split{$0 == ","}.map(String.init)
            let coordinates = locationString.components(separatedBy: ",")
            
            let CLLCoordType = CLLocationCoordinate2D(latitude: Double(coordinates[0])!,
                                                      longitude: Double(coordinates[1])!);
            let anno = BurnAnnotation(coordinate: CLLCoordType);
            anno.element = element
            anno.title = element.name
            anno.image = UIImage(named: "map-pin.png")
            
            mapView.addAnnotation(anno);
//            NSLog("%@", locationString)
        }
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


extension MapViewController: MKMapViewDelegate {
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // If annotation is not of type RestaurantAnnotation (MKUserLocation types for instance), return nil
        if !(annotation is BurnAnnotation){
            return nil
        }
        
        var annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: "Pin")
        
        if annotationView == nil{
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
            annotationView?.canShowCallout = true
        }else{
            annotationView?.annotation = annotation
        }
        
        let burnAnnotation = annotation as! BurnAnnotation
        
        let blurb = UILabel(frame: CGRect(x: 0,y: 0,width: annotationView!.frame.size.width,height: 200))
        blurb.font = UIFont(name: "Helvetica", size: 12)
        blurb.text = burnAnnotation.element?.shortBlurb
        blurb.numberOfLines = 6
        annotationView?.detailCalloutAccessoryView = blurb
        
        
        // Left Accessory
        //let leftAccessory = UILabel(frame: CGRect(x: 0,y: 0,width: 50,height: 30))
        //leftAccessory.text = burnAnnotation.element?.name
        //leftAccessory.font = UIFont(name: "Verdana", size: 10)
        annotationView?.leftCalloutAccessoryView = UIImageView(image: UIImage(named: "fire.png"))
        
        // Right accessory view
        // let image = UIImage(named: "fire.png")
        let button = UIButton(type: .detailDisclosure)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        annotationView?.rightCalloutAccessoryView = button
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let annotation = view.annotation
        if !(annotation is BurnAnnotation){
            NSLog("Annotation is not burn annotation ignore")
            return
        }
        NSLog("callout tapped. load element")
        
        let burnAnnotation = annotation as! BurnAnnotation
        let detail = BurnElementDetailViewController.create(camp: burnAnnotation.element!)
        navigationController?.pushViewController(detail, animated: true)
        
    }
    
}


class BurnAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var element: AfrikaBurnElement?
    var title: String?
    var image: UIImage?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

