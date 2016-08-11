//
//  UIColor+Utils.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 09/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

extension UIColor
{
    convenience init(hexValue: Int, alpha: CGFloat)
    {
        let red = CGFloat((hexValue >> 16) % 256) / 256.0
        let green = CGFloat((hexValue >> 8) % 256) / 256.0
        let blue = CGFloat(hexValue % 256) / 256.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}