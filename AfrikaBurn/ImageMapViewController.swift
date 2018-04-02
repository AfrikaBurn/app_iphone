//
//  ImageMapViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2018/04/02.
//  Copyright © 2018 AfrikaBurn. All rights reserved.
//

import UIKit

class ImageMapViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    lazy var mapImageView: UIImageView = {
        let i = UIImageView(image: #imageLiteral(resourceName: "AB2018_Map"))
        return i
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(mapImageView)
        scrollView.minimumZoomScale = 0.05
        scrollView.maximumZoomScale = 0.1
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
}

extension ImageMapViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mapImageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
    }
}
