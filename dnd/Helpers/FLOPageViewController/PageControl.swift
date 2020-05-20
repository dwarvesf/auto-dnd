//
//  FLOPageControl.swift
//  FLOPageViewController
//
//  Created by Florian Schliep on 21.01.16.
//  Copyright © 2016 Florian Schliep. All rights reserved.
//

import Cocoa

@objc(FLOPageControl)
public class PageControl: NSControl {
    
    private var needsToRedrawIndicators = false
    
// MARK: - Appearance
    
    public var color = NSColor.black {
        didSet {
            self.redrawIndicators()
        }
    }
    
    public var indicatorSize: CGFloat = 7 {
        didSet {
            self.redrawIndicators()
        }
    }
    
    @objc(FLOPageControlStyle)
    public enum Style: Int {
        case dot
        case circle
    }
    
    public var style = Style.dot {
        didSet {
            self.redrawIndicators()
        }
    }
    
// MARK: - Pages
    
    public var numberOfPages: UInt = 0 {
        didSet {
            self.redrawIndicators()
        }
    }
    
    public var selectedPage: UInt = 0 {
        didSet {
            self.redrawIndicators()
        }
    }
    
// MARK: - NSControl
    
    public override var frame: NSRect {
        willSet {
            self.needsToRedrawIndicators = true
        }
    }

// MARK: - Drawing
    
    public override func draw(_ dirtyRect: NSRect) {
        guard self.needsToRedrawIndicators else { return }
        
        if self.numberOfPages > 1 {
            for index in 0...self.numberOfPages-1 {
                var fill = true
                let frame = self.frameOfIndicator(at: index)
                let lineWidth: CGFloat = 1
                
                switch (self.style, index == self.selectedPage) {
                case (.dot, true), (.circle, true):
                    self.color.setFill()
                case (.dot, false):
                    self.color.withAlphaComponent(0.33).setFill()
                case (.circle, false):
                    self.color.setStroke()
                    fill = false
                    _ = frame.insetBy(dx: lineWidth*0.5, dy: lineWidth*0.5)
                }
                
                let path = NSBezierPath(ovalIn: frame)
                if fill {
                    path.fill()
                } else {
                    path.lineWidth = lineWidth
                    path.stroke()
                }
            }
        }
        
        self.needsToRedrawIndicators = false
    }
    
// MARK: - Mouse
    
    public override func mouseDown(with theEvent: NSEvent) {
        let location = self.convert(theEvent.locationInWindow, from: nil)
        self.highlightIndicator(at: location)
    }
    
    public override func mouseDragged(with theEvent: NSEvent) {
        let location = self.convert(theEvent.locationInWindow, from: nil)
        self.highlightIndicator(at: location)
    }
    
    public override func mouseUp(with theEvent: NSEvent) {
        let location = self.convert(theEvent.locationInWindow, from: nil)
        self.highlightIndicator(at: location, sendAction: true)
    }
    
// MARK: - Helpers
    
    private func highlightIndicator(at location: NSPoint, sendAction: Bool = false) {
        var newPage = self.selectedPage
        for index in 0...self.numberOfPages-1 {
            if NSPointInRect(location, self.frameOfIndicator(at: index)) {
                newPage = index
                break
            }
        }
        if self.selectedPage != newPage {
            self.selectedPage = newPage
        }
        
        guard sendAction, let target = self.target, let action = self.action else { return }
        NSApp.sendAction(action, to: target, from: self)
    }
    
    private func frameOfIndicator(at index: UInt) -> NSRect {
        let centerDrawingAroundSpace = (self.numberOfPages % 2 == 0)
        let centeredIndex = self.numberOfPages/2
        let centeredFrame = NSRect(x: NSMidX(self.bounds) - (centerDrawingAroundSpace ? -self.indicatorSize/2 : self.indicatorSize/2), y: NSMidY(self.bounds) - self.indicatorSize/2, width: self.indicatorSize, height: self.indicatorSize)
        let distanceToCenteredIndex = CGFloat(centeredIndex)-CGFloat(index)
        
        return NSRect(x: NSMinX(centeredFrame) - distanceToCenteredIndex*self.indicatorSize*2, y: NSMidY(self.bounds) - self.indicatorSize/2, width: self.indicatorSize, height: self.indicatorSize)
    }
    
    private func redrawIndicators() {
        self.needsToRedrawIndicators = true
        self.needsDisplay = true
    }
    
}
