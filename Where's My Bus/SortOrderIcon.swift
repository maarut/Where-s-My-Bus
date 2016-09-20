//
//  SortOrderIcon.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 22/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit
class SortOrderIcon
{
    private static let defaultColour = UIColor(hexValue: 0x007AFE, alpha: 1.0)
    
    static func get(colour: UIColor = SortOrderIcon.defaultColour) -> UIImage
    {
        struct DispatchOnce {
            static var token = 0
            static var image: UIImage!
        }
        dispatch_once(&DispatchOnce.token) {
            let icon = SortOrderIconView(frame: CGRect(x: 0, y: 0, width: 36, height: 36),
                                                colour: colour)
            DispatchOnce.image = SortOrderIcon.generateImageFrom(icon)
        }
        return DispatchOnce.image
        
    }
    
    private static func generateImageFrom(view: UIView) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        if let context = context { view.layer.renderInContext(context) }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

// MARK: - SortOrderIconView Implementation
private class SortOrderIconView: UIView
{
    var colour: UIColor
    private weak var arrowLabel: UILabel!
    private weak var aToZLabel: UILabel!
    
    init(frame: CGRect, colour: UIColor)
    {
        self.colour = colour
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
        setupView()
    }
    
    override convenience init(frame: CGRect)
    {
        self.init(frame: frame, colour: SortOrderIcon.defaultColour)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        colour = aDecoder.decodeObjectForKey("colour") as! UIColor
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
    }
    
    private func setupView()
    {
        let arrowLabel = UILabel()
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowLabel.text = "↓"
        arrowLabel.font = arrowLabel.font.fontWithSize(25.0)
        arrowLabel.textColor = colour
        let aToZLabel = UILabel()
        aToZLabel.translatesAutoresizingMaskIntoConstraints = false
        aToZLabel.font = aToZLabel.font.fontWithSize(13.0)
        aToZLabel.numberOfLines = 2
        aToZLabel.text = "A\nZ"
        aToZLabel.textColor = colour
        addSubview(arrowLabel)
        addSubview(aToZLabel)
        self.arrowLabel = arrowLabel
        self.aToZLabel = aToZLabel
        NSLayoutConstraint.activateConstraints(createConstraints())
        layoutIfNeeded()
    }
    
    private func createConstraints() -> [NSLayoutConstraint]
    {
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("|[aToZ][arrow]|",
            options: .AlignAllCenterY, metrics: nil, views: ["aToZ": aToZLabel, "arrow": arrowLabel])
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[aToZ]|",
            options: [], metrics: nil, views: ["aToZ": aToZLabel])
        return constraints
    }
    
    override func intrinsicContentSize() -> CGSize
    {
        let width = arrowLabel.intrinsicContentSize().width + aToZLabel.intrinsicContentSize().width
        let height = max(arrowLabel.intrinsicContentSize().height,
                         aToZLabel.intrinsicContentSize().height)
        return CGSize(width: width, height: height)
    }
}
