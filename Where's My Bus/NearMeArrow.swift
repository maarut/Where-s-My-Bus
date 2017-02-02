//
//  NearMeArrow.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 08/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

// MARK: - NearMeArrowState Enum
enum NearMeArrowState
{
    case pressed
    case normal
}

// MARK: - NearMeArrow Implementation
class NearMeArrow
{
    private static var pressedImage: UIImage = { (colour: UIColor) in
                let locationArrow = NearMeArrowView(frame: CGRect(x: 0, y: 0, width: 36, height: 36),
                                                    colour: colour, state: .pressed)
                return NearMeArrow.generateImageFrom(locationArrow)
            }(NearMeArrow.defaultColour)
    private static var normalImage: UIImage = { (colour: UIColor) in
                let locationArrow = NearMeArrowView(frame: CGRect(x: 0, y: 0, width: 36, height: 36),
                                                    colour: colour, state: .normal)
                return NearMeArrow.generateImageFrom(locationArrow)
            }(NearMeArrow.defaultColour)
    fileprivate static let defaultColour = UIColor(hexValue: 0x007AFE, alpha: 1.0)
    
    static func get(state: NearMeArrowState, colour: UIColor = NearMeArrow.defaultColour) -> UIImage
    {
        switch state {
        case .normal:
            return normalImage
        case .pressed:
            return pressedImage
        }
        
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

// MARK: - NearMeArrowView Implementation
private class NearMeArrowView: UIView
{
    var arrowColour: UIColor
    var borderColour: UIColor
    
    init(frame: CGRect, colour: UIColor, state: NearMeArrowState)
    {
        switch state {
        case .normal:
            arrowColour = colour
            borderColour = UIColor.clear
            break
        case .pressed:
            borderColour = colour
            arrowColour = UIColor.clear
            break
        }
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    override convenience init(frame: CGRect)
    {
        self.init(frame: frame, colour: NearMeArrow.defaultColour, state: .normal)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        arrowColour = aDecoder.decodeObject(forKey: "arrowColour") as! UIColor
        borderColour = aDecoder.decodeObject(forKey: "borderColour") as! UIColor
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }

    
    override func draw(_ rect: CGRect)
    {
        let firstPoint = CGPoint(x: frame.width * 38.0 / 72.0, y: frame.height * 35.0 / 72.0)
        let secondPoint = CGPoint(x: frame.width * 13.0 / 72.0, y: frame.height * 35.0 / 72.0)
        let thirdPoint = CGPoint(x: frame.width * 57.0 / 72.0, y: frame.height * 16.0 / 72.0)
        let fourthPoint = CGPoint(x: frame.width * 38.0 / 72.0, y: frame.height * 58.0 / 72.0)
        arrowColour.setStroke()
        let arrowPath = UIBezierPath()
        arrowPath.move(to: firstPoint)
        arrowPath.addLine(to: secondPoint)
        arrowPath.addLine(to: thirdPoint)
        arrowPath.addLine(to: fourthPoint)
        arrowPath.close()
        arrowPath.stroke()
        if borderColour != UIColor.clear {
            let borderPath = UIBezierPath(roundedRect: bounds, cornerRadius: frame.width * 9.0 / 72.0)
            borderPath.append(arrowPath)
            borderColour.setStroke()
            borderColour.setFill()
            borderPath.usesEvenOddFillRule = true
            borderPath.stroke()
            borderPath.fill()
        }
    }
}
