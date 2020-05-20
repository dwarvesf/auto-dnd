//
//  FLOPageViewController.swift
//  FLOPageViewController
//
//  Created by Florian Schliep on 19.01.16.
//  Copyright © 2016 Florian Schliep. All rights reserved.
//

import Cocoa

private let ArrowSize = NSSize(width: 20, height: 40)

public protocol PageViewControllerDelegate: class {
    func pageViewController(_ pageViewController: PageViewController, didSelectPage pageIndex: Int)
}

public class PageViewController: NSViewController {
    
    public weak var delegate: PageViewControllerDelegate?
    
    fileprivate weak var pageController: _FLOPageController!
    fileprivate weak var pageControl: PageControl?
    private weak var leftArrow: ArrowControl?
    private weak var rightArrow: ArrowControl?
    
    private var bottomPageControllerConstraint: NSLayoutConstraint?
    // we are using left/right instead of leading/trailing b/c of the arrows; in case of an r-l lang, the viewControllers array will be reversed, which is simpler than dealing w/ leading/trailing arrows, as NSPageController doesn't support r-l langs
    private var leftPageControllerConstraint: NSLayoutConstraint?
    private var rightPageControllerConstraint: NSLayoutConstraint?
    
    private var trackingRectTag: NSView.TrackingRectTag?
    private var mouseInside = false
    
// MARK: - Instantiation
    
    @objc
    public init() {
        super.init(nibName: nil, bundle: nil)
        self.setUp()
        self.view = NSView()
        self.viewDidLoad()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setUp()
    }
    
    public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    
    private func setUp() {
        let pageController = _FLOPageController()
        pageController.view = NSView() // we need to create a view here (as we're not loading one from a nib) though we'll override it later
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        pageController.delegate = self
        pageController.transitionStyle = .horizontalStrip

        self.addChild(pageController)
        self.pageController = pageController
    }
    
// MARK: - NSViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.updateBackgroundColor()
        
        // changing the view's frame is somehow not enough (NSPageController is weird), so we create a new view
        self.pageController.view = NSView(frame: self.view.bounds)
        self.pageController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.pageController.view)
        
        self.view.addConstraint(NSLayoutConstraint(item: self.pageController.view, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)) // we don't ever need to modify the top constraint
        self.leftPageControllerConstraint = NSLayoutConstraint(item: self.pageController.view, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0)
        self.view.addConstraint(self.leftPageControllerConstraint!)
        self.rightPageControllerConstraint = NSLayoutConstraint(item: self.pageController.view, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0)
        self.view.addConstraint(self.rightPageControllerConstraint!)
        self.bottomPageControllerConstraint = NSLayoutConstraint(item: self.pageController.view, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraint(self.bottomPageControllerConstraint!)
        
        self.updatePageControl()
        self.updateArrowControls()
    }
    
    public override func viewDidLayout() {
        super.viewDidLayout()
        
        for vc in self.viewControllers {
            vc.view.frame = self.view.bounds
        }
    }
    
// MARK: - View Controller Management
    
    @objc public var viewControllers: [NSViewController] = [] {
        didSet {
            let reverse = (NSApp.userInterfaceLayoutDirection == .rightToLeft && self.viewControllers.count > 1)
            
            if reverse {
                self.viewControllers.reverseInPlace()
            }
            self.pageController.arrangedObjects = self.viewControllers.map({ NSNumber(value: self.viewControllers.firstIndex(of: $0)!) })
            self.pageController.scrollingEnabled = (self.viewControllers.count > 1)
            
            if reverse {
                self.pageController.selectedIndex = self.viewControllers.count-1
            }
            self.hideArrowControls(false)
            self.updatePages()
        }
    }
    
    @objc
    public func loadViewControllers(_ viewControllerIdentifiers: [String], from storyboard: NSStoryboard) {
        self.viewControllers = viewControllerIdentifiers.map({
            storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier($0)) as! NSViewController
        })
    }
    
// MARK: - Page Control
    
    @objc
    public var selectedPage: Int {
        get {
            return self.pageController.selectedIndex
        }
        set {
            self.pageController.animator().selectedIndex = newValue
            self.pageControl?.selectedPage = UInt(newValue)
        }
    }

    @objc public var showPageControl = true {
        didSet {
            self.updatePageControl()
        }
    }
    
    @objc public var pageIndicatorStyle = PageControl.Style.dot {
        didSet {
            self.pageControl?.style = self.pageIndicatorStyle
        }
    }
    
    private func updatePageControl() {
        if self.showPageControl == true && self.pageControl == nil {
            let pageControl = PageControl()
            pageControl.target = self
            pageControl.action = #selector(pageControlDidChangeSelection(_:))
            pageControl.color = self.tintColor
            pageControl.style = self.pageIndicatorStyle
            pageControl.translatesAutoresizingMaskIntoConstraints = false
            pageControl.wantsLayer = true
            pageControl.layer!.zPosition = 1000
            self.view.addSubview(pageControl)
            self.pageControl = pageControl
            self.hidePageControl(false)
            self.updatePages()
            
            self.view.addConstraint(NSLayoutConstraint(item: pageControl, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: pageControl, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: pageControl, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -pageControl.indicatorSize))
            self.view.addConstraint(NSLayoutConstraint(item: pageControl, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: pageControl.indicatorSize))
            self.updateBottomConstraint()
        } else if self.showPageControl == false, let pageControl = self.pageControl {
            pageControl.removeFromSuperview()
            self.updateBottomConstraint()
        }
    }
    
    private func updateBottomConstraint() {
        guard let bottomConstraint = self.bottomPageControllerConstraint else { return }
        
        if let pageControl = self.pageControl {
            if self.overlayControls {
                bottomConstraint.constant = 0
            } else {
                bottomConstraint.constant = -pageControl.indicatorSize*3
            }
        } else {
            bottomConstraint.constant = 0
        }
    }
    
    @objc
    public func pageControlDidChangeSelection(_ sender: PageControl) {
        self.selectedPage = Int(sender.selectedPage)
        self.notifyDelegate()
    }
    
// MARK: - Arrow Controls
    
    @objc public var showArrowControls = true {
        didSet {
            self.updateArrowControls()
        }
    }
    
    private func updateArrowControls() {
        if self.showArrowControls == true && self.leftArrow == nil {
            let leftArrow = ArrowControl()
            leftArrow.target = self
            leftArrow.action = #selector(didPressArrowControl(_:))
            leftArrow.color = self.tintColor
            leftArrow.translatesAutoresizingMaskIntoConstraints = false
            leftArrow.wantsLayer = true
            leftArrow.layer!.zPosition = 1000
            self.view.addSubview(leftArrow)
            self.leftArrow = leftArrow
            
            let rightArrow = ArrowControl()
            rightArrow.target = self
            rightArrow.action = #selector(didPressArrowControl(_:))
            rightArrow.direction = .right
            rightArrow.color = self.tintColor
            rightArrow.translatesAutoresizingMaskIntoConstraints = false
            rightArrow.wantsLayer = true
            rightArrow.layer!.zPosition = 1000
            self.view.addSubview(rightArrow)
            self.rightArrow = rightArrow
            self.hideArrowControls(false)
            
            self.view.addConstraint(NSLayoutConstraint(item: leftArrow, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: ArrowSize.width))
            self.view.addConstraint(NSLayoutConstraint(item: leftArrow, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: leftArrow, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: ArrowSize.width))
            self.view.addConstraint(NSLayoutConstraint(item: leftArrow, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: ArrowSize.height))
            
            self.view.addConstraint(NSLayoutConstraint(item: rightArrow, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: -ArrowSize.width))
            self.view.addConstraint(NSLayoutConstraint(item: rightArrow, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: rightArrow, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: ArrowSize.width))
            self.view.addConstraint(NSLayoutConstraint(item: rightArrow, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: ArrowSize.height))
            
            self.updateSideConstraints()
        } else if self.showArrowControls == false && self.leftArrow != nil {
            self.leftArrow!.removeFromSuperview()
            self.leftArrow = nil
            
            self.rightArrow!.removeFromSuperview()
            self.rightArrow = nil
            
            self.updateSideConstraints()
        }
    }
    
    private func updateSideConstraints() {
        guard let leftConstraint = self.leftPageControllerConstraint, let rightConstraint = self.rightPageControllerConstraint else { return }
        
        if self.leftArrow != nil && !self.overlayControls {
            leftConstraint.constant = ArrowSize.width*3
            rightConstraint.constant = -ArrowSize.width*3
        } else {
            leftConstraint.constant = 0
            rightConstraint.constant = 0
        }
    }
    
    @objc
    public func didPressArrowControl(_ sender: ArrowControl) {
        switch sender.direction {
        case .left:
            self.pageController.navigateBack(nil)
        case .right:
            self.pageController.navigateForward(nil)
        }
        self.notifyDelegate()
    }
    
// MARK: - Appearance + Behavior
    
    @objc public var pageControlRequiresMouseOver = false {
        didSet {
            self.updateMouseTracking()
            self.hidePageControl(self.pageControlRequiresMouseOver)
        }
    }
    
    @objc public var arrowControlsRequireMouseOver = false {
        didSet {
            self.updateMouseTracking()
            self.hideArrowControls(self.arrowControlsRequireMouseOver)
        }
    }
    
    @objc public var overlayControls = true {
        didSet {
            self.updateBottomConstraint()
            self.updateSideConstraints()
        }
    }
    
    @objc public var tintColor = NSColor.black {
        didSet {
            self.pageControl?.color = self.tintColor
            self.leftArrow?.color = self.tintColor
            self.rightArrow?.color = self.tintColor
        }
    }
    
    @objc public var backgroundColor: NSColor? {
        didSet {
            self.updateBackgroundColor()
        }
    }
    
// MARK: - Mouse
    
    public override func mouseEntered(with theEvent: NSEvent) {
        super.mouseEntered(with: theEvent)
        guard theEvent.trackingNumber == self.trackingRectTag else { return }
        
        self.mouseInside = true
        if self.pageControlRequiresMouseOver {
            self.hidePageControl(false)
        }
        if self.arrowControlsRequireMouseOver {
            self.hideArrowControls(false)
        }
    }
    
   public override func mouseExited(with theEvent: NSEvent) {
        super.mouseExited(with: theEvent)
        guard theEvent.trackingNumber == self.trackingRectTag else { return }
        
        self.mouseInside = false
        if self.pageControlRequiresMouseOver {
            self.hidePageControl()
        }
        if self.arrowControlsRequireMouseOver {
            self.hideArrowControls()
        }
    }
    
// MARK: - Helpers
    
    private func updateMouseTracking() {
        if (self.pageControlRequiresMouseOver || self.arrowControlsRequireMouseOver) && self.trackingRectTag == nil {
            self.trackingRectTag = self.view.addTrackingRect(self.view.bounds, owner: self, userData: nil, assumeInside: false)
        } else if (!self.pageControlRequiresMouseOver && !self.arrowControlsRequireMouseOver) && self.trackingRectTag != nil {
            self.view.removeTrackingRect(self.trackingRectTag!)
            self.trackingRectTag = nil
        }
    }
    
    private func hidePageControl(_ flag: Bool = true) {
        if self.pageControlRequiresMouseOver {
            self.pageControl?.isHidden = flag ? true : !self.mouseInside
        } else {
            self.pageControl?.isHidden = flag
        }
        
    }
    
    fileprivate func hideArrowControls(_ flag: Bool = true) {
        let hideLeftArrow = (self.pageController.selectedIndex == 0)
        let hideRightArrow = (self.pageController.selectedIndex == self.viewControllers.count-1)
        if self.arrowControlsRequireMouseOver {
            self.leftArrow?.isHidden = (flag || hideLeftArrow) ? true : !self.mouseInside
            self.rightArrow?.isHidden = (flag || hideRightArrow) ? true : !self.mouseInside
        } else {
            self.leftArrow?.isHidden = (flag || hideLeftArrow)
            self.rightArrow?.isHidden = (flag || hideRightArrow)
        }
    }
    
    private func updateBackgroundColor() {
        self.view.layer?.backgroundColor = self.backgroundColor?.cgColor
    }
    
    private func updatePages() {
        self.pageControl?.numberOfPages = UInt(self.viewControllers.count)
        self.pageControl?.selectedPage = UInt(self.pageController.selectedIndex)
    }
    
    fileprivate func notifyDelegate() {
        self.delegate?.pageViewController(self, didSelectPage: self.selectedPage)
    }
    
// MARK: - Navigation
    
    private var needsLeftToRightNavigation: Bool {
        return (NSApp.userInterfaceLayoutDirection == .leftToRight)
    }
    
    @objc
    public func navigateForward() {
        if self.needsLeftToRightNavigation {
            self.pageController.navigateForward(nil)
        } else {
            self.pageController.navigateBack(nil)
        }
        self.notifyDelegate()
    }
    
    @objc
    public func navigateBack() {
        if self.needsLeftToRightNavigation {
            self.pageController.navigateBack(nil)
        } else {
            self.pageController.navigateForward(nil)
        }
        self.notifyDelegate()
    }
    
    @objc
    public var isAtStart: Bool {
        if self.needsLeftToRightNavigation {
            return (self.selectedPage == 0)
        } else {
            return (self.selectedPage == self.viewControllers.count-1)
        }
    }
    
    @objc
    public var isAtEnd: Bool {
        if self.needsLeftToRightNavigation {
            return (self.selectedPage == self.viewControllers.count-1)
        } else {
            return (self.selectedPage == 0)
        }
    }
    
}

extension PageViewController: NSPageControllerDelegate {
    
    public func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        guard let number = object as? NSNumber else { fatalError("The arrangedObjects array has been changed manually. This is not allowed! Please use the viewControllers array to manage the pages.") }
        return NSPageController.ObjectIdentifier(number.stringValue)
    }
    
    public func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        let index = (identifier as NSString).integerValue
        return self.viewControllers[index]
    }
    
    public func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
        let identifier = self.pageController(pageController, identifierFor: object)
        let viewController = self.pageController(pageController, viewControllerForIdentifier: identifier)
        guard let index = self.viewControllers.firstIndex(of: viewController) else { return }
        
        self.pageControl?.selectedPage = UInt(index)
        self.hideArrowControls(false)
        self.notifyDelegate()
    }
    
    public func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        self.pageController.completeTransition() // we need to do this, see docs
    }
    
}

extension PageViewController {
    
    func debugQuickLookObject() -> AnyObject {
        return self.view
    }
    
    var pageSize: NSSize {
        guard !self.overlayControls && (self.showPageControl || self.showArrowControls) else { return self.view.bounds.size }
        
        var size = self.view.bounds.size
        if self.showPageControl {
            size.height -= self.pageControl!.indicatorSize*3
        }
        if self.showArrowControls {
            size.width -= ArrowSize.width*6
        }
        
        return size
    }
    
}

extension Array {
    mutating func reverseInPlace() {
        self = self.reversed()
    }
}

private class _FLOPageController: NSPageController {
    var scrollingEnabled = true
    
    override func scrollWheel(with event: NSEvent) {
        guard self.scrollingEnabled else { return }
        super.scrollWheel(with: event)
    }
}
