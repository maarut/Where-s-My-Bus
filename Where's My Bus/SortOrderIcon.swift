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
    private static var icon: UIImage = { (colour: UIColor) in
            let icon = SortOrderIconView(frame: CGRect(x: 0, y: 0, width: 36, height: 36),
                                                colour: colour)
            return SortOrderIcon.generateImageFrom(icon)
        }(SortOrderIcon.defaultColour)
    fileprivate static let defaultColour = UIColor(hexValue: 0x007AFE, alpha: 1.0)
    
    static func get(_ colour: UIColor = SortOrderIcon.defaultColour) -> UIImage
    {
        return icon
        
    }
    
    fileprivate static func generateImageFrom(_ view: UIView) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        if let context = context { view.layer.render(in: context) }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

// MARK: - SortOrderIconView Implementation
private class SortOrderIconView: UIView
{
    var colour: UIColor
    fileprivate weak var arrowLabel: UILabel!
    fileprivate weak var aToZLabel: UILabel!
    
    init(frame: CGRect, colour: UIColor)
    {
        self.colour = colour
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        setupView()
    }
    
    override convenience init(frame: CGRect)
    {
        self.init(frame: frame, colour: SortOrderIcon.defaultColour)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        colour = aDecoder.decodeObject(forKey: "colour") as! UIColor
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    
    fileprivate func setupView()
    {
        let arrowLabel = UILabel()
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowLabel.text = "↓"
        arrowLabel.font = arrowLabel.font.withSize(25.0)
        arrowLabel.textColor = colour
        let aToZLabel = UILabel()
        aToZLabel.translatesAutoresizingMaskIntoConstraints = false
        aToZLabel.font = aToZLabel.font.withSize(13.0)
        aToZLabel.numberOfLines = 2
        aToZLabel.text = "A\nZ"
        aToZLabel.textColor = colour
        addSubview(arrowLabel)
        addSubview(aToZLabel)
        self.arrowLabel = arrowLabel
        self.aToZLabel = aToZLabel
        NSLayoutConstraint.activate(createConstraints())
        layoutIfNeeded()
    }
    
    fileprivate func createConstraints() -> [NSLayoutConstraint]
    {
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "|[aToZ][arrow]|",
            options: .alignAllCenterY, metrics: nil, views: ["aToZ": aToZLabel, "arrow": arrowLabel])
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[aToZ]|",
            options: [], metrics: nil, views: ["aToZ": aToZLabel])
        return constraints
    }
    
    override var intrinsicContentSize : CGSize
    {
        let width = arrowLabel.intrinsicContentSize.width + aToZLabel.intrinsicContentSize.width
        let height = max(arrowLabel.intrinsicContentSize.height,
                         aToZLabel.intrinsicContentSize.height)
        return CGSize(width: width, height: height)
    }
}
