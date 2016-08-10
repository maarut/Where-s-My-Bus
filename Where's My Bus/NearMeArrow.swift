//
//  NearMeArrow.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 08/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

enum NearMeArrowState
{
    case Pressed
    case Normal
}

class NearMeArrow
{
    static func nearMeArrow(state state: NearMeArrowState,
        colour: UIColor = UIColor(hexValue: 0x007AFE, alpha: 1.0)) -> UIImage
    {
        struct DispatchOnce {
            static var pressedToken = 0
            static var normalToken = 0
            static var pressedImage: UIImage!
            static var normalImage: UIImage!
        }
        switch state {
        case .Normal:
            dispatch_once(&DispatchOnce.normalToken) {
                let locationArrow = NearMeArrowView(frame: CGRect(x: 0, y: 0, width: 36, height: 36),
                                                    colour: colour, state: state)
                DispatchOnce.normalImage = NearMeArrow.generateImageFrom(locationArrow)
            }
            return DispatchOnce.normalImage
        case .Pressed:
            dispatch_once(&DispatchOnce.pressedToken) {
                let locationArrow = NearMeArrowView(frame: CGRect(x: 0, y: 0, width: 36, height: 36),
                                                    colour: colour, state: state)
                DispatchOnce.pressedImage = NearMeArrow.generateImageFrom(locationArrow)
            }
            return DispatchOnce.pressedImage
        }
        
    }
    
    private static func generateImageFrom(view: UIView) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        if let context = context { view.layer.renderInContext(context) }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

private class NearMeArrowView: UIView
{
    var arrowColour: UIColor
    var borderColour: UIColor
    
    init(frame: CGRect, colour: UIColor, state: NearMeArrowState)
    {
        switch state {
        case .Normal:
            arrowColour = colour
            borderColour = UIColor.clearColor()
            break
        case .Pressed:
            borderColour = colour
            arrowColour = UIColor.clearColor()
            break
        }
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
    }
    
    override convenience init(frame: CGRect)
    {
        self.init(frame: frame, colour: UIColor(hexValue: 0x007AFE, alpha: 1.0), state: .Normal)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        arrowColour = aDecoder.decodeObjectForKey("arrowColour") as! UIColor
        borderColour = aDecoder.decodeObjectForKey("borderColour") as! UIColor
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
    }

    
    override func drawRect(rect: CGRect)
    {
        let firstPoint = CGPoint(x: frame.width * 38.0 / 72.0, y: frame.height * 35.0 / 72.0)
        let secondPoint = CGPoint(x: frame.width * 13.0 / 72.0, y: frame.height * 35.0 / 72.0)
        let thirdPoint = CGPoint(x: frame.width * 57.0 / 72.0, y: frame.height * 16.0 / 72.0)
        let fourthPoint = CGPoint(x: frame.width * 38.0 / 72.0, y: frame.height * 58.0 / 72.0)
        arrowColour.setStroke()
        let arrowPath = UIBezierPath()
        arrowPath.moveToPoint(firstPoint)
        arrowPath.addLineToPoint(secondPoint)
        arrowPath.addLineToPoint(thirdPoint)
        arrowPath.addLineToPoint(fourthPoint)
        arrowPath.closePath()
        arrowPath.stroke()
        if borderColour != UIColor.clearColor() {
            let borderPath = UIBezierPath(roundedRect: bounds, cornerRadius: frame.width * 9.0 / 72.0)
            borderPath.appendPath(arrowPath)
            borderColour.setStroke()
            borderColour.setFill()
            borderPath.usesEvenOddFillRule = true
            borderPath.stroke()
            borderPath.fill()
        }
    }
}