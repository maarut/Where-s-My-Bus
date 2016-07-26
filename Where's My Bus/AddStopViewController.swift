//
//  AddStopViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 25/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit
import MapKit

class AddStopViewController: UIViewController
{
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
}

extension AddStopViewController: MKMapViewDelegate
{
    
}
