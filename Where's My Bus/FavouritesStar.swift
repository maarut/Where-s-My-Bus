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
    case filled
    case empty
}

class FavouritesStar
{
    private static var filledImage: UIImage = { (colour: UIColor) in
                let star = FavouritesStarView(frame: CGRect(x: 0, y: 0, width: 30, height: 30),
                    colour: colour, state: .filled)
                return FavouritesStar.generateImageFrom(star)
            }(FavouritesStar.defaultColour)
    private static var emptyImage: UIImage = { (colour: UIColor) in
                let star = FavouritesStarView(frame: CGRect(x: 0, y: 0, width: 30, height: 30),
                    colour: colour, state: .empty)
                return FavouritesStar.generateImageFrom(star)
            }(FavouritesStar.defaultColour)
    
    fileprivate static let defaultColour = UIColor(hexValue: 0x007AFE, alpha: 1.0)
    
    static func get(_ state: FavouritesStarState) -> UIImage
    {
        switch state {
        case .empty:
            return emptyImage
        case .filled:
            return filledImage
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

private class FavouritesStarView: UIView
{
    var state: FavouritesStarState
    var colour: UIColor
    
    init(frame: CGRect, colour: UIColor, state: FavouritesStarState)
    {
        self.state = state
        self.colour = colour
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    override convenience init(frame: CGRect)
    {
        self.init(frame: frame, colour: FavouritesStar.defaultColour, state: .empty)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        state = aDecoder.decodeObject(forKey: "state") as! FavouritesStarState
        colour = aDecoder.decodeObject(forKey: "colour") as! UIColor
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect)
    {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: frame.width * 42.0 / 84.0, y: frame.height * 10.0 / 84.0))
        path.addLine(to: CGPoint(x: frame.width * 50.0 / 84.0, y: frame.height * 32.0 / 84.0))
        path.addLine(to: CGPoint(x: frame.width * 74.0 / 84.0, y: frame.height * 32.0 / 84.0))
        path.addLine(to: CGPoint(x: frame.width * 54.0 / 84.0, y: frame.height * 46.0 / 84.0))
        path.addLine(to: CGPoint(x: frame.width * 62.0 / 84.0, y: frame.height * 70.0 / 84.0))
        path.addLine(to: CGPoint(x: frame.width * 42.0 / 84.0, y: frame.height * 54.0 / 84.0))
        path.addLine(to: CGPoint(x: frame.width * 22.0 / 84.0, y: frame.height * 70.0 / 84.0))
        path.addLine(to: CGPoint(x: frame.width * 29.0 / 84.0, y: frame.height * 46.0 / 84.0))
        path.addLine(to: CGPoint(x: frame.width * 10.0 / 84.0, y: frame.height * 32.0 / 84.0))
        path.addLine(to: CGPoint(x: frame.width * 34.0 / 84.0, y: frame.height * 32.0 / 84.0))
        path.close()
        colour.setStroke()
        path.stroke()
        if state == .filled {
            colour.setFill()
            path.fill()
        }
    }
}
