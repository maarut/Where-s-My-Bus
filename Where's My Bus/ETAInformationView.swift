//
//  ETAInformationView.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 18/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

class ETAInformationView: UIView
{
    @IBOutlet weak var routeBorder: UIView!
    @IBOutlet weak var route: UILabel!
    @IBOutlet weak var eta: UILabel!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
        let route = UILabel()
        let eta = UILabel()
        route.translatesAutoresizingMaskIntoConstraints = false
        eta.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false
        route.textColor = UIColor.whiteColor()
        eta.text = "ETA"
        route.text = "H28"
        route.font = UIFont(name: "Menlo-Bold", size: 17.0)

        let routeBorder = UIView()
        routeBorder.translatesAutoresizingMaskIntoConstraints = false
        routeBorder.backgroundColor = UIColor(hexValue: 0xA1002C)
        routeBorder.addSubview(route)
        addSubview(routeBorder)
        addSubview(eta)
        self.eta = eta
        self.routeBorder = routeBorder
        self.route = route
        
        NSLayoutConstraint.activateConstraints(createConstraints())
        
    }
    
    private func createConstraints() -> [NSLayoutConstraint]
    {
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("|[border]-[eta]|",
            options: [.AlignAllCenterY], metrics: nil, views: ["border": routeBorder, "eta": eta])
        
        constraints.append(route.centerXAnchor.constraintEqualToAnchor(routeBorder.centerXAnchor))
        constraints.last!.identifier = "Route Center X with Route Border"
        
        constraints.append(route.centerYAnchor.constraintEqualToAnchor(routeBorder.centerYAnchor))
        constraints.last!.identifier = "Route Center Y with Route Border"
        
        constraints.append(routeBorder.heightAnchor.constraintEqualToAnchor(route.heightAnchor, multiplier: 1.35))
        constraints.last!.identifier = "Route Border Height is 1.35x Route Height"
        
        constraints.append(routeBorder.widthAnchor.constraintEqualToAnchor(route.widthAnchor, multiplier: 1.35))
        constraints.last!.identifier = "Route Border Width is 1.35x Route Width"
        
        constraints.append(routeBorder.topAnchor.constraintEqualToAnchor(self.topAnchor))
        constraints.last!.identifier = "Route Border Top to Information View Top"
        
        constraints.append(routeBorder.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor))
        constraints.last!.identifier = "Route Border Bottom to Information View Bottom"
        
        return constraints
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func intrinsicContentSize() -> CGSize
    {
        let width = route.intrinsicContentSize().width * 1.35 + eta.intrinsicContentSize().width
        let height = route.intrinsicContentSize().height * 1.35
        return CGSize(width: width, height: height)
    }
}
