//
//  FLOArrowControl.swift
//  FLOPageViewController
//
//  Created by Florian Schliep on 21.01.16.
//  Copyright © 2016 Florian Schliep. All rights reserved.
//

import Cocoa

@objc(FLOArrowControl)
public class ArrowControl: NSControl {

    private var mouseDown = false {
        didSet {
            self.needsDisplay = true
        }
    }
    
// MARK: - Properties
    
    public enum Direction {
        case left
        case right
    }
    
    public var direction = Direction.left {
        didSet {
            self.needsDisplay = true
        }
    }
    
    public var color = NSColor.black {
        didSet {
            self.needsDisplay = true
        }
    }
    
// MARK: - Drawing
    
    public override func draw(_ dirtyRect: NSRect) {
        let drawRightArrow = self.direction == .right
        let lineWidth: CGFloat = 4
        
        let bezierPath = NSBezierPath()
        bezierPath.move(to: NSPoint(x: drawRightArrow ? NSMinX(self.bounds) : NSMaxX(self.bounds), y: NSMaxY(self.bounds)))
        bezierPath.line(to: NSPoint(x: drawRightArrow ? NSMaxX(self.bounds)-lineWidth*0.5 : NSMinX(self.bounds)+lineWidth*0.5, y: NSMidY(self.bounds)))
        bezierPath.line(to: NSPoint(x: drawRightArrow ? NSMinX(self.bounds) : NSMaxX(self.bounds), y: NSMinY(self.bounds)))
        bezierPath.lineWidth = lineWidth
        bezierPath.lineCapStyle = .round
        bezierPath.lineJoinStyle = .round
        (self.mouseDown ? self.color : self.color.withAlphaComponent(0.33)).setStroke()
        bezierPath.stroke()
    }
    
// MARK: - Mouse
    
    public override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        self.mouseDown = true
    }
    
    public override func mouseUp(with theEvent: NSEvent) {
        super.mouseUp(with: theEvent)
        self.mouseDown = false
        
        guard let target = self.target, let action = self.action else { return }
        NSApp.sendAction(action, to: target, from: self)
    }
    
}
