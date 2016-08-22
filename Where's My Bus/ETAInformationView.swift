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
    @IBOutlet weak var towards: UILabel!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
        let route = UILabel()
        let eta = UILabel()
        let towards = UILabel()
        route.translatesAutoresizingMaskIntoConstraints = false
        eta.translatesAutoresizingMaskIntoConstraints = false
        towards.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false
        route.textColor = UIColor.whiteColor()
        eta.text = "ETA"
        eta.font = UIFont.systemFontOfSize(16.0)
        route.text = "H28"
        route.font = UIFont(name: "Menlo-Bold", size: 17.0)
        route.textAlignment = .Center
        towards.text = "Towards"
        towards.font = UIFont.systemFontOfSize(11)
        let routeBorder = UIView()
        routeBorder.translatesAutoresizingMaskIntoConstraints = false
        routeBorder.backgroundColor = UIColor(hexValue: 0xA1002C)
        routeBorder.addSubview(route)
        addSubview(routeBorder)
        addSubview(eta)
        addSubview(towards)
        self.eta = eta
        self.routeBorder = routeBorder
        self.route = route
        self.towards = towards
        
        NSLayoutConstraint.activateConstraints(createConstraints())
        
    }
    
    private func createConstraints() -> [NSLayoutConstraint]
    {
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("[border]-[eta]",
            options: [], metrics: nil, views: ["border": routeBorder, "eta": eta])
        
        constraints.append(routeBorder.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor))
        constraints.last!.identifier = "Route Border Leading to Information View Leading"
        
        constraints.append(route.centerXAnchor.constraintEqualToAnchor(routeBorder.centerXAnchor))
        constraints.last!.identifier = "Route Center X with Route Border"
        
        constraints.append(route.centerYAnchor.constraintEqualToAnchor(routeBorder.centerYAnchor))
        constraints.last!.identifier = "Route Center Y with Route Border"
        
        constraints.append(routeBorder.heightAnchor.constraintEqualToAnchor(route.heightAnchor, multiplier: 1.35))
        constraints.last!.identifier = "Route Border Height is 1.35x Route Height"
        
        constraints.append(routeBorder.widthAnchor.constraintEqualToAnchor(route.widthAnchor, multiplier: 1.35))
        constraints.last!.identifier = "Route Border Width is 1.35x Route Width"
        
        constraints.append(routeBorder.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor))
        constraints.last!.identifier = "Route Border Center Y to Information View Center Y"
        
        constraints.append(eta.topAnchor.constraintEqualToAnchor(self.topAnchor))
        constraints.last!.identifier = "ETA Label Top to Information View Top"
        
        constraints.append(towards.topAnchor.constraintEqualToAnchor(eta.bottomAnchor))
        constraints.last!.identifier = "Towards Label Top to ETA Label Bottom"
        
        constraints.append(towards.leadingAnchor.constraintEqualToAnchor(eta.leadingAnchor))
        constraints.last!.identifier = "Towards Label Leading to ETA Label Leading"

        constraints.append(towards.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor))
        constraints.last!.identifier = "Towards Label Bottom to Information View Bottom"

        return constraints
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func intrinsicContentSize() -> CGSize
    {
        let width = route.intrinsicContentSize().width * 1.35 +
            max(eta.intrinsicContentSize().width, towards.intrinsicContentSize().width)
        let height = max(route.intrinsicContentSize().height * 1.35,
            eta.intrinsicContentSize().height + towards.intrinsicContentSize().height)
        return CGSize(width: width, height: height)
    }
}
