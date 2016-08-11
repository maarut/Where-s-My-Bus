//
//  FavouritesStar.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 10/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

enum FavouritesStarState
{
    case Filled
    case Empty
}

class FavouritesStar
{
    private static let defaultColour = UIColor(hexValue: 0x007AFE, alpha: 1.0)
    static func get(state: FavouritesStarState, colour: UIColor = FavouritesStar.defaultColour) -> UIImage
    {
        struct DispatchOnce {
            static var emptyToken = 0
            static var filledToken = 0
            static var emptyImage: UIImage!
            static var filledImage: UIImage!
        }
        switch state {
        case .Empty:
            dispatch_once(&DispatchOnce.emptyToken) {
                let star = FavouritesStarView(frame: CGRect(x: 0, y: 0, width: 36, height: 36),
                    colour: colour, state: state)
                DispatchOnce.emptyImage = FavouritesStar.generateImageFrom(star)
            }
            return DispatchOnce.emptyImage
        case .Filled:
            dispatch_once(&DispatchOnce.filledToken) {
                let star = FavouritesStarView(frame: CGRect(x: 0, y: 0, width: 36, height: 36),
                    colour: colour, state: state)
                DispatchOnce.filledImage = FavouritesStar.generateImageFrom(star)
            }
            return DispatchOnce.filledImage
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

private class FavouritesStarView: UIView
{
    var state: FavouritesStarState
    var colour: UIColor
    
    init(frame: CGRect, colour: UIColor, state: FavouritesStarState)
    {
        self.state = state
        self.colour = colour
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
    }
    
    override convenience init(frame: CGRect)
    {
        self.init(frame: frame, colour: UIColor(hexValue: 0x007AFE, alpha: 1.0), state: .Empty)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        state = aDecoder.decodeObjectForKey("state") as! FavouritesStarState
        colour = aDecoder.decodeObjectForKey("colour") as! UIColor
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect)
    {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: frame.width * 42.0 / 84.0, y: frame.height * 10.0 / 84.0))
        path.addLineToPoint(CGPoint(x: frame.width * 50.0 / 84.0, y: frame.height * 32.0 / 84.0))
        path.addLineToPoint(CGPoint(x: frame.width * 74.0 / 84.0, y: frame.height * 32.0 / 84.0))
        path.addLineToPoint(CGPoint(x: frame.width * 54.0 / 84.0, y: frame.height * 46.0 / 84.0))
        path.addLineToPoint(CGPoint(x: frame.width * 62.0 / 84.0, y: frame.height * 70.0 / 84.0))
        path.addLineToPoint(CGPoint(x: frame.width * 42.0 / 84.0, y: frame.height * 54.0 / 84.0))
        path.addLineToPoint(CGPoint(x: frame.width * 22.0 / 84.0, y: frame.height * 70.0 / 84.0))
        path.addLineToPoint(CGPoint(x: frame.width * 29.0 / 84.0, y: frame.height * 46.0 / 84.0))
        path.addLineToPoint(CGPoint(x: frame.width * 10.0 / 84.0, y: frame.height * 32.0 / 84.0))
        path.addLineToPoint(CGPoint(x: frame.width * 34.0 / 84.0, y: frame.height * 32.0 / 84.0))
        path.closePath()
        colour.setStroke()
        path.stroke()
        if state == .Filled {
            colour.setFill()
            path.fill()
        }
    }
}