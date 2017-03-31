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
        
        attachLongPress()
        
        loadCustomLocations()
        loadElements()
        
        navigationItem.title = "Map"
        navigationController?.navigationBar.titleTextAttributes =  [NSForegroundColorAttributeName: UIColor.afrikaBurnTintColor]
        navigationController?.navigationBar.barTintColor = UIColor.afrikaBurnBgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func attachLongPress(){
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.longPressOnMap(gestureRecognizer:)))
        gesture.minimumPressDuration = 2.0
        
        mapView.addGestureRecognizer(gesture)
        
        
    }
    
    func longPressOnMap(gestureRecognizer:UIGestureRecognizer){
        
        if (gestureRecognizer.state != .began) {
            // avoid this double firing
            return
        }
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let actionSheet = UIAlertController(title: "Custom Location", message: "Select a category", preferredStyle: .actionSheet)
        actionSheet.view.tintColor = UIColor.afrikaBurnTintColor
        actionSheet.addAction(UIAlertAction(title: "Home Camp", style: .default, handler: { _ in            
            self.saveCustomLocation(name: "Home Camp", coordinates: newCoordinates, isHomeCamp: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Custom Location", style: .default, handler: { _ in
            
            var inputTextField: UITextField?
            let namePrompt = UIAlertController(title: "Custom Location", message: "Enter a name for your location.", preferredStyle: UIAlertControllerStyle.alert)
            namePrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
            namePrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                // Now do whatever you want with inputTextField (remember to unwrap the optional)
                guard let name = inputTextField!.text else {
                    return
                }
                self.saveCustomLocation(name: name, coordinates: newCoordinates, isHomeCamp: false)
            }))
            namePrompt.addTextField(configurationHandler: {(textField: UITextField!) in
                textField.placeholder = "Name"
                inputTextField = textField
            })
            
            self.present(namePrompt, animated: true, completion: { _ in {
//                    NSLog("alert view closed %@", inputTextField?.text)
                    let name = inputTextField?.text
                    NSLog("Alert view closed \(name)")
                }()})
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    func loadElements(){
        
        for element in allElements {
            guard let location = element.location else {
                continue
            }
            let anno = BurnAnnotation(coordinate: location, element: element)
            anno.title = element.name
            mapView.addAnnotation(anno);
        }
    }
    
    func loadCustomLocations(){
        
        let customLocations = self.persistentStore.customLocations()
        
        for location in customLocations {
            guard let coordinates = location.coordinates else {
                continue
            }
            
            NSLog("location.id %@", location.id)
            // skip deleted location
            if (location.isInvalidated) {
                continue
            }
            let annotation = CustomLocationAnnotation(coordinate: coordinates, customLocation: location)
            mapView.addAnnotation(annotation)
        }
    }
    
    func saveCustomLocation(name : String, coordinates : CLLocationCoordinate2D, isHomeCamp: Bool){
        let customLocation = CustomLocation(name: name, coordinate: coordinates, isHomeCamp: isHomeCamp)
        if (isHomeCamp){
            self.persistentStore.saveHomeLocation(customLocation: customLocation)
        } else {
            self.persistentStore.createLocation(customLocation: customLocation)
        }
        
        
        removeCustomLocations()
        loadCustomLocations()
    }
    
    func removeCustomLocations(){
        // delete all pins and reload them
        let pins = mapView.annotations.filter { (annotation) -> Bool in
            return (annotation is CustomLocationAnnotation)
        }
        
        mapView.removeAnnotations(pins)
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
        userTrackingMode = .none
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
        
        guard let abAnnotation = annotation as? ABAnnotation else {
            return nil
        }
        
        let annotationView: MKAnnotationView
        if let reusedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") {
            annotationView = reusedAnnotationView
            annotationView.annotation = annotation
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
            annotationView.canShowCallout = true
        }
        
        
        
        // if it's a burn annotation add a burn callout
        if (abAnnotation is BurnAnnotation){
            let burnAnnotation = abAnnotation as! BurnAnnotation
            let blurb = UILabel(frame: CGRect(x: 0,y: 0,width: annotationView.frame.size.width,height: 200))
            blurb.font = UIFont.preferredFont(forTextStyle: .body)
            blurb.text = burnAnnotation.element.shortBlurb
            blurb.numberOfLines = 6
            annotationView.detailCalloutAccessoryView = blurb
            
            // Left Accessory
            // We could make this change the icon based on the element type. Eg. mutant vehicles etc.
//            annotationView.leftCalloutAccessoryView = UIImageView(image: burnAnnotation.element.elementType.iconImage)
            
            
            let button = UIButton(type: .detailDisclosure)
            annotationView.rightCalloutAccessoryView = button
            
        } else if (abAnnotation is CustomLocationAnnotation) {
//            let customAnnotation = abAnnotation as! CustomLocationAnnotation
//            let image = customAnnotation.customLocation.isHomeCamp ? #imageLiteral(resourceName: "home") : #imageLiteral(resourceName: "star")
//            annotationView.leftCalloutAccessoryView = UIImageView(image: image)
            
            let button = UIButton(type: .detailDisclosure)
            annotationView.rightCalloutAccessoryView = button
        }
        
        
        annotationView.image = abAnnotation.image
        
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        guard let abAnnotation = view.annotation as? ABAnnotation else {
            return
        }
        
        if (abAnnotation is BurnAnnotation){
            let burnAnnotation = abAnnotation as! BurnAnnotation
            let detail = BurnElementDetailViewController.create(element: burnAnnotation.element)
            navigationController?.pushViewController(detail, animated: true)
        }
        
        if (abAnnotation is CustomLocationAnnotation){
            let customLocationAnnotation = abAnnotation as! CustomLocationAnnotation
            
            let confirmDelete = UIAlertController(title: "Delete this location?", message: "Are you sure you want to delete this location?", preferredStyle: UIAlertControllerStyle.alert)
            confirmDelete.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
            confirmDelete.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive, handler: { (action) -> Void in
                self.persistentStore.deleteLocationId(locationId: customLocationAnnotation.customLocation.id)
                
                self.removeCustomLocations()
                self.loadCustomLocations()
            }))
            
            present(confirmDelete, animated: true, completion: nil)
        }
        
    }
    
}


class ABAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var image: UIImage
    init(coordinate: CLLocationCoordinate2D, image: UIImage) {
        self.coordinate = coordinate
        self.image = image
    }
}

class CustomLocationAnnotation: ABAnnotation {
    var customLocation: CustomLocation
    
    init(coordinate: CLLocationCoordinate2D, customLocation : CustomLocation) {
        self.customLocation = customLocation
        super.init(coordinate: coordinate, image: customLocation.isHomeCamp ? #imageLiteral(resourceName: "map-home") : #imageLiteral(resourceName: "map-poi"))
        
        self.title = customLocation.name
    }

}


class BurnAnnotation: ABAnnotation {
    
    var element: AfrikaBurnElement
    
    init(coordinate: CLLocationCoordinate2D, element: AfrikaBurnElement) {
        self.element = element
        super.init(coordinate: coordinate, image: element.elementType.mapImage)
    }
}

