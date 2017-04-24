//
//  Connor Gordon 
//  Date: 4/22/17
//  Class: CSC2310
//

import UIKit
import Swift

class DrawView: UIView, UIGestureRecognizerDelegate
{
    // Line Variables
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    
    // Circle Variables
    var currentCircle = Circle()
    var finishedCircles = [Circle]()
    
    // Long Touch Gesture Reconizer
    var longPressReconizer: UILongPressGestureRecognizer!
    
    // Velocity Variables for Line Size
    var maxRecordedVelocity: CGFloat = CGFloat.leastNonzeroMagnitude
    var minRecordedVelocity: CGFloat = CGFloat.greatestFiniteMagnitude
    var currentVelocity: CGFloat = 0
    var currentLineWidth: CGFloat
    {
        let maxLineWidth: CGFloat = 20
        let minLineWidth: CGFloat = 1
        // Thinner line for faster velocity
        let lineWidth = (maxRecordedVelocity - currentVelocity) / (maxRecordedVelocity - minRecordedVelocity) * (maxLineWidth - minLineWidth) + minLineWidth
        return lineWidth
    }
    
    //---------------------------------------------------------------------------------------------------------
    @IBInspectable var finishedLineColor: UIColor = UIColor.black
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    //---------------------------------------------------------------------------------------------------------
    @IBInspectable var currentLineColor: UIColor = UIColor.red
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    //---------------------------------------------------------------------------------------------------------
    @IBInspectable var lineThickness: CGFloat = 10
    {
        didSet
        {
            setNeedsDisplay()
        }
    }

    //---------------------------------------------------------------------------------------------------------
    var selectedLineIndex: Int?
    {
        didSet
        {
            if selectedLineIndex == nil
            {
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    var moveRecognizer: UIPanGestureRecognizer!
    
    //---------------------------------------------------------------------------------------------------------
    override var canBecomeFirstResponder: Bool
    {
        return true
    }
    
    //---------------------------------------------------------------------------------------------------------
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self,
                                                         action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        //let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        longPressReconizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        
        addGestureRecognizer(longPressReconizer)
        
        moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DrawView.moveLine(_:)))
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
    }
    
    //---------------------------------------------------------------------------------------------------------
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
    
    // This function is for moving the lines on the screen
    //---------------------------------------------------------------------------------------------------------
    func moveLine(_ gestureRecognizer: UIPanGestureRecognizer)
    {
        print("Recognized a pan")
        
        // Log the Velocity of Swipe
        let velocityInXY = gestureRecognizer.velocity(in: self)
        currentVelocity = hypot(velocityInXY.x, velocityInXY.y)
        
        maxRecordedVelocity = max(maxRecordedVelocity, currentVelocity)
        minRecordedVelocity = min(minRecordedVelocity, currentVelocity)
        
        print("Current Drawing Velocity: \(currentVelocity) points per second")
        print("maxRecordedVelocity: \(maxRecordedVelocity) points per second")
        print("minRecordedVelocity: \(minRecordedVelocity) points per second")
        
        // Reconize Long Gesture
        guard longPressReconizer.state == .changed || longPressReconizer.state == .ended else {
            return
        }
        
        // If a line is selected...
        if let index = selectedLineIndex
        {
            // When the pan recognizer changes its position...
            if gestureRecognizer.state == .changed
            {
                // How far has the pan moved?
                let translation = gestureRecognizer.translation(in: self)
                
                // Add the translation to the current beginning and end points of the line
                // Make sure there are no copy and paste typos!
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                gestureRecognizer.setTranslation(CGPoint.zero, in: self)
                
                // Redraw the screen
                setNeedsDisplay()
            }
        }
        else
        {
            // If no line is selected, do not do anything
            return
        }
    }
    
    //---------------------------------------------------------------------------------------------------------
    func doubleTap(_ gestureRecognizer: UIGestureRecognizer)
    {
        print("Recognized a double tap")
        
        selectedLineIndex = nil
        currentLines.removeAll()
        finishedLines.removeAll()   // Delete all Lines on Screen
        finishedCircles.removeAll() // Delete all Circles on Screen
        setNeedsDisplay()
    }
    
    //---------------------------------------------------------------------------------------------------------
    func longPress(_ gestureRecognizer: UIGestureRecognizer)
    {
        print("Recognized a long press")
        
        if gestureRecognizer.state == .began
        {
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            
            if selectedLineIndex != nil
            {
                currentLines.removeAll()
            }
        }
        else if gestureRecognizer.state == .ended
        {
            selectedLineIndex = nil
        }
        
        setNeedsDisplay()
    }
    
    //---------------------------------------------------------------------------------------------------------
    func tap(_ gestureRecognizer: UIGestureRecognizer)
    {
        print("Recognized a tap")
        
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLine(at: point)
        
        // Grab the menu controller
        let menu = UIMenuController.shared
        
        if selectedLineIndex != nil
        {
            
            // Make ourselves the target of menu item action messages
            becomeFirstResponder()
            
            // Create a new "Delete" UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(DrawView.deleteLine(_:)))
            menu.menuItems = [deleteItem]
            
            // Tell the menu where it should come from and show it
            let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self)
            menu.setMenuVisible(true, animated: true)
        }
        else
        {
            // Hide the menu if no line is selected
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    //---------------------------------------------------------------------------------------------------------
    func deleteLine(_ sender: UIMenuController)
    {
        // Remove the selected line from the list of finishedLines
        if let index = selectedLineIndex
        {
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            
            // Redraw everything
            setNeedsDisplay()
        }
    }
    
    //---------------------------------------------------------------------------------------------------------
    func stroke(_ line: Line)
    {
        let path = UIBezierPath()
        path.lineWidth = line.lineWidth
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    //---------------------------------------------------------------------------------------------------------
    func indexOfLine(at point: CGPoint) -> Int?
    {
        
        // Find a line close to point
        for (index, line) in finishedLines.enumerated()
        {
            let begin = line.begin
            let end = line.end
            
            // Check a few points on the line
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05)
            {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                // If the tapped point is within 20 points, let's return this line
                if hypot(x - point.x, y - point.y) < 20.0
                {
                    return index
                }
            }
        }
        
        // If nothing is close enough to the tapped point, then we did not select a line
        return nil
    }
    
    //---------------------------------------------------------------------------------------------------------
    override func draw(_ rect: CGRect)
    {
        finishedLineColor.setStroke()
        for line in finishedLines
        {
            stroke(line)
        }
        
        currentLineColor.setStroke()
        for (_, line) in currentLines
        {
            stroke(line)
        }
        
        if let index = selectedLineIndex
        {
            UIColor.green.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
        }
        
        // current LineColor
        for (_, line) in currentLines
        {
            switch line.angle.value
            {
                case 0 ..< 90.0:
                    UIColor.red.setStroke()
                case 90.0 ..< 180.0:
                    UIColor.blue.setStroke()
                case -180.0 ..< -90.0:
                    UIColor.yellow.setStroke()
                case -90.0 ..< 0:
                    UIColor.green.setStroke()
                default:
                    break
            }
            
            stroke(line)
        }
        
        // Draw Circles
        finishedLineColor.setStroke()
        for circle in finishedCircles
        {
            let path = UIBezierPath(ovalIn: circle.rect)
            path.lineWidth = lineThickness
            path.stroke()
        }
        currentLineColor.setStroke()
        UIBezierPath(ovalIn: currentCircle.rect).stroke()
    }
    
    //---------------------------------------------------------------------------------------------------------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        // Let's put in a log statement to see the order of events
        print(#function)
        
        if touches.count == 2
        {
            let touchesArray = Array(touches)
            let location1 = touchesArray[0].location(in: self)
            let location2 = touchesArray[1].location(in: self)
            currentCircle = Circle(point1: location1, point2: location2)
        }
        else
        {
            for touch in touches
            {
                let location = touch.location(in: self)
                
                let newLine = Line(begin: location, end: location, lineWidth: currentLineWidth)
                
                let key = NSValue(nonretainedObject: touch)
                currentLines[key] = newLine
            }
        }
        setNeedsDisplay()
    }
    
    //---------------------------------------------------------------------------------------------------------
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        // Let's put in a print statement to see the order of events
        print(#function)
        
        if touches.count == 2
        {
            let touchesArray = Array(touches)
            let location1 = touchesArray[0].location(in: self)
            let location2 = touchesArray[1].location(in: self)
            currentCircle = Circle(point1: location1, point2: location2)
        }
        else
        {
            for touch in touches
            {
                let key = NSValue(nonretainedObject: touch)
                currentLines[key]?.end = touch.location(in: self)
            }
        }
        setNeedsDisplay()
    }
    
    //---------------------------------------------------------------------------------------------------------
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        // Let's put in a log statement to see the order of events
        print(#function)
        
        if touches.count == 2
        {
            let touchesArray = Array(touches)
            let location1 = touchesArray[0].location(in: self)
            let location2 = touchesArray[1].location(in: self)
            currentCircle = Circle(point1: location1, point2: location2)
            finishedCircles.append(currentCircle)
            currentCircle = Circle()
        }
        else
        {
            for touch in touches
            {
                let key = NSValue(nonretainedObject: touch)
                if var line = currentLines[key]
                {
                    line.end = touch.location(in: self)
                    line.lineWidth = currentLineWidth
                    
                    finishedLines.append(line)
                    currentLines.removeValue(forKey: key)
                }
            }
        }
        setNeedsDisplay()
    }
    
    //---------------------------------------------------------------------------------------------------------
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        // Let's put in a log statement to see the order of events
        print(#function)
        
        currentLines.removeAll()
        currentCircle = Circle()
        
        setNeedsDisplay()
    }
}
