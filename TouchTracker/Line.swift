//
//  Copyright © 2015 Big Nerd Ranch
//

import Foundation
import CoreGraphics

struct Line
{
    var begin = CGPoint.zero
    var end = CGPoint.zero
    var lineWidth: CGFloat = 10
    
    var angle: Measurement<UnitAngle>
    {
        var angleInRads: Measurement<UnitAngle>
        angleInRads = Measurement(value: -atan2(Double(end.y - begin.y),Double(end.x - begin.x)), unit: .radians)
        
        return angleInRads.converted(to: .degrees)
    }
}
