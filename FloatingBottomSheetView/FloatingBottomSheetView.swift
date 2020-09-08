//
//  FloatingBottomSheetView.swift
//  FloatingBottomSheetView
//
//  Created by Krisnandika Aji on 02/09/20.
//  Copyright © 2020 Sinar Nirmata. All rights reserved.
//

import UIKit

protocol FloatingBottomSheetDelegate {
    func floatingBottomSheetDidCollapse()
    func floatingBottomSheetDidExpand()
    func floatingButtonSheetDidUpdate(sheet: FloatingBottomSheetView, progress: CGFloat)
}

extension FloatingBottomSheetDelegate {
    /// Tells superview that sheet has been collapsed
    func floatingBottomSheetDidCollapse() {}
    /// Tells superview that sheet has been expanded
    func floatingBottomSheetDidExpand() {}
    /// Tells user the progress of sheet expansion
    func floatingButtonSheetDidUpdate(sheet: FloatingBottomSheetView, progress: CGFloat) {}
}

open class FloatingBottomSheetView: UIView {
    // MARK: - Typealias
    /// `FloatingBottomSheetView` typealias. The view will be called as
    /// `sheet` from here on out.
    fileprivate typealias sheet = FloatingBottomSheetView
    
    // MARK: - Properties
    /// The default frame of `sheet`, if not defined,
    /// `sheet` will follow this size.
    public static var defaultFrame: CGRect = CGRect(x: 0, y: 0, width: 320, height: 72)
    
    /// Corner radius of FloatingBottomSheetView.
    open dynamic var cornerRadius: CGFloat = 8 {
        didSet {
            cornerRadius = max(cornerRadius, 0)
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = true
        }
    }
    
    /// Left and right margin of initial floating view.
    /// Define this property before calling `configure` or else `sheet`
    /// will follow default value in its initialization.
    open dynamic var horizontalMargin: CGFloat = 16 {
        didSet {
            horizontalMarginConstraint?.forEach({ $0.constant = horizontalMargin })
            superview?.layoutIfNeeded()
        }
    }
    
    /// Bottom margin of desired floating view.
    /// Define this property before calling `configure` or else `sheet`
    /// will follow default value in its initialization.
    open dynamic var bottomMargin: CGFloat = 16 {
        didSet {
            bottomMarginConstraint?.constant = bottomMargin
            superview?.layoutIfNeeded()
        }
    }
    
    /// Minimum inset (left, right, bottom margin of `sheet`) for expanded state.
    /// This property value will be assigned whenever `sheet` is updating to
    /// 'expanded' state. Default value is 0, so the view will stick to left, right
    /// and bottom of superview.
    open dynamic var minimumInset: CGFloat = 0 {
        didSet {
            if minimumInset < 0 { minimumInset = 0 }
            initInset = minimumInset
        }
    }
    
    /// Maximum inset (left, right, bottom margin of `sheet`) for collapsed state.
    /// This property value will be assigned whenever `sheet` is updating to
    /// 'collapsed' state. Default value is 16.
    open dynamic var maximumInset: CGFloat = 16
    
    /// Minimum height of `sheet`. When collapsed, `sheet` will stick
    /// to this limit minimum height. Prevents it to have less than 10 point of height.
    open dynamic var minimumHeight: CGFloat = 72 {
        didSet {
            if minimumHeight < 10 { minimumHeight = 10 }
            initHeight = minimumHeight
        }
    }
    
    /// Maximum height of `sheet`. When expanded, `sheet` will follow
    /// this property value.
    open dynamic var maximumHeight: CGFloat = 270
    
    /// Background color of `sheet`
    open dynamic var drawerBackgroundColor: UIColor = .white
    
    /// Drawer view toggle, `drawerView` is the grey thin view on top side
    /// of `sheet`.
    open dynamic var showDrawerView: Bool = true
    
    /// Superview dim toggle, set superview dimming based on this value.
    open dynamic var shouldDimSuperview: Bool = true
    
    /// Collapsed content view, this view will be shown when bottom sheet is collapsed.
    @objc open dynamic var collapsedContentView: UIView!
    
    /// Expanded content view, this view will be shown when bottom sheet is expanded.
    @objc open dynamic var expandedContentView: UIView?
    
    var delegate: FloatingBottomSheetDelegate?
    
    // MARK: - Private Properties
    /// Property to store `sheet`'s superview.
    fileprivate var superView: UIView!
    /// Property to store `sheet`'s dim view.
    fileprivate var dimView: UIView?
    
    /// Property to store pan gesture.
    fileprivate var pan: UIPanGestureRecognizer!
    /// Property to store content view of `sheet`.
    fileprivate var contentView: UIView!
    /// Property to store single view status.
    fileprivate var singleView: Bool { expandedContentView == nil }
    
    /// Property to store left and right constraints.
    fileprivate var horizontalMarginConstraint: [NSLayoutConstraint]? = nil
    /// Property to store bottom margin constraint.
    fileprivate var bottomMarginConstraint: NSLayoutConstraint? = nil
    /// Property to store height constraint.
    fileprivate var heightConstraint: NSLayoutConstraint? = nil
    
    /// Property to store initial height after `sheet` state update.
    fileprivate var initHeight: CGFloat = 72
    /// Property to store initial inset after `sheet` state update.
    fileprivate var initInset: CGFloat = 16
    
    // MARK: - init
    /// Required coder init.
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Overrides view init to set view frame.
    public override init(frame: CGRect) {
        super.init(frame: sheet.defaultFrame)
    }
    
    /// Required init to set collapsed and expanded views. (Main initialization method)
    public init(initView: UIView, expandedView: UIView?) {
        super.init(frame: sheet.defaultFrame)
        self.collapsedContentView = initView
        self.expandedContentView = expandedView
    }
}

public extension FloatingBottomSheetView {
    // MARK: - Public Methods
    
    /// Call this method immediately after defining `sheet` in your class.
    /// If you desire a set minimum and maximum height, you need to define that too
    /// before calling this method.
    func configure(in superview: UIView) {
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        let contentView = UIView()
        self.contentView = contentView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.frame = sheet.defaultFrame
        contentView.backgroundColor = drawerBackgroundColor
        
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        let drawerView = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 6))
        drawerView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        drawerView.layer.cornerRadius = 3
        drawerView.translatesAutoresizingMaskIntoConstraints = false
        
        guard let collapsedContentView = collapsedContentView else {
                fatalError("Init (collapsed) view must be set.")
        }
        
        contentView.addSubview(collapsedContentView)
        if let expandedView = expandedContentView { contentView.addSubview(expandedView) }
        if showDrawerView { contentView.addSubview(drawerView) }
        
        expandedContentView?.alpha = 0
        
        let heightSelfConstraint = NSLayoutConstraint.init(
            item: self,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: initHeight)
        
        let collapsedViewHConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-0-[collapsedView]-0-|",
            options: .init(rawValue: 0),
            metrics: nil,
            views: ["collapsedView": collapsedContentView])
        
        let collapsedViewVConstrains = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-16-[collapsedView]-0-|",
            options: .init(rawValue: 0),
            metrics: nil,
            views: ["collapsedView": collapsedContentView])
        
        let drawerVConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-6-[drawerView(4)]",
            options: .init(rawValue: 0), metrics: nil,
            views: ["drawerView": drawerView])
        
        let drawerHConstraints = NSLayoutConstraint(
            item: drawerView, attribute: .centerX,
            relatedBy: .equal,
            toItem: contentView, attribute: .centerX,
            multiplier: 1, constant: 0)
        
        let drawerWidthConstraint = NSLayoutConstraint(
            item: drawerView, attribute: .width,
            relatedBy: .equal,
            toItem: nil, attribute: .notAnAttribute,
            multiplier: 1, constant: 100)
            
        if let expandedView = expandedContentView {
            let expandedViewHConstraints = NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-0-[expandedView]-0-|",
                options: .init(rawValue: 0),
                metrics: nil,
                views: ["expandedView": expandedView])
            
            let expandedViewVConstrains = NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-16-[expandedView]-0-|",
                options: .init(rawValue: 0),
                metrics: nil,
                views: ["expandedView": expandedView])
            
                contentView.addConstraints(expandedViewHConstraints)
                contentView.addConstraints(expandedViewVConstrains)
        }
        
        contentView.addConstraint(drawerWidthConstraint)
        contentView.addConstraint(drawerHConstraints)
        contentView.addConstraints(drawerVConstraints)
        contentView.addConstraints(collapsedViewVConstrains)
        contentView.addConstraints(collapsedViewHConstraints)
        
        self.addSubview(contentView)
        
        let contentViewHConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-0-[contentView]-0-|",
            options: .init(rawValue: 0),
            metrics: nil,
            views: ["contentView": contentView])
        
        let contentViewVConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-0-[contentView]-0-|",
            options: .init(rawValue: 0),
            metrics: nil,
            views: ["contentView": contentView])
        
        self.addConstraints(contentViewHConstraints)
        self.addConstraints(contentViewVConstraints)
        
        if shouldDimSuperview { addDimLayerTo(superView: superview )}
        
        superview.addSubview(self)
        self.superView = superview
            
        let horizontalConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-\(horizontalMargin)-[sheetView]-\(horizontalMargin)-|",
            options: .init(rawValue: 0),
            metrics: nil,
            views: ["sheetView": self])
        
        let bottomConstraint = NSLayoutConstraint.init(
            item: self,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: superview,
            attribute: .bottom,
            multiplier: 1,
            constant: -bottomMargin)
        
        horizontalMarginConstraint = horizontalConstraints
        bottomMarginConstraint = bottomConstraint
        heightConstraint = heightSelfConstraint
        
        superview.addConstraints(horizontalMarginConstraint!)
        superview.addConstraint(bottomMarginConstraint!)
        
        self.addConstraint(heightConstraint!)
        
        pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(gestureRecognizer:)))
        
        self.addGestureRecognizer(pan)
        
        contentView.layoutIfNeeded()
        self.layoutIfNeeded()
        superview.layoutIfNeeded()
    }
    
    /// Instruct `sheet` to collapse programmatically, if `sheet` is in expanded
    /// state.
    func collapse() {
        if initHeight == minimumHeight { return }
        self.heightConstraint?.constant = minimumHeight
        self.bottomMarginConstraint?.constant = -maximumInset
        self.horizontalMarginConstraint?.first?.constant = maximumInset
        self.horizontalMarginConstraint?.last?.constant = maximumInset
        
        initHeight = minimumHeight
        UIView.animate(withDuration: 0.2) {
            
            self.dimView?.alpha = 0
            if !self.singleView {
                self.collapsedContentView.alpha = 1
                self.expandedContentView?.alpha = 0
            }
            
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
        }
        delegate?.floatingBottomSheetDidCollapse()
    }
    
    /// Instruct `sheet` to expand programmatically, if `sheet` is in collapsed
    /// state.
    func expand() {
        if initHeight == maximumHeight { return }
        self.heightConstraint?.constant = maximumHeight
        self.bottomMarginConstraint?.constant = -minimumInset
        self.horizontalMarginConstraint?.first?.constant = minimumInset
        self.horizontalMarginConstraint?.last?.constant = minimumInset
        
        initHeight = maximumHeight
        UIView.animate(withDuration: 0.2) {
            
            self.dimView?.alpha = 0.5
            if !self.singleView {
                self.collapsedContentView.alpha = 0
                self.expandedContentView?.alpha = 1
            }
            
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
        }
        delegate?.floatingBottomSheetDidExpand()
    }
    
    // MARK: - Private Methods
    
    /// Add dim layer to black out view behind `sheet` so parent view
    /// will be blocked slightly by this layer. User can set this on or off
    /// through the `shouldDimSuperview` property.
    private func addDimLayerTo(superView: UIView) {
        let dimView = UIView(frame: superView.frame)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = UIColor.black
        dimView.alpha = 0
        
        superView.addSubview(dimView)
        self.dimView = dimView
        
        let hConstraint = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-0-[dimView]-0-|",
            options: .init(rawValue: 0), metrics: nil,
            views: ["dimView": dimView])
        
        let vConstraint = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-0-[dimView]-0-|",
            options: .init(rawValue: 0), metrics: nil,
            views: ["dimView": dimView])
        
        superView.addConstraints(hConstraint)
        superView.addConstraints(vConstraint)
    }
}

private extension FloatingBottomSheetView {
    
    // MARK: - Private Actions
    
    /// Pan gesture handler
    @objc func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = pan.translation(in: nil)
        let y = translation.y
        
        /// Define height range of view
        let heightRange = maximumHeight - minimumHeight
        /// Define inset range of view
        let insetRange = maximumInset - minimumInset
        
        /// Store progress for exact height calculation in pan y value changes
        var progress = (initHeight - minimumHeight) / heightRange
        
        switch pan.state {
        case .changed:
            var yProgress: CGFloat = 0
            yProgress = 0 - (y / heightRange)
            progress += yProgress
            
            /// Limit progress bounds
            if progress < 0 { progress = 0 }
            if progress > 1 { progress = 1 }
            
            let height = (progress * heightRange) + minimumHeight
            let inset = insetRange * (1 - progress)
            
            /// Update dimView alpha
            let alpha = progress * 0.5
            
            DispatchQueue.main.async {
                self.heightConstraint?.constant = height
                self.bottomMarginConstraint?.constant = -inset
                self.horizontalMarginConstraint?.first?.constant = inset
                self.horizontalMarginConstraint?.last?.constant = inset
                
                self.dimView?.alpha = alpha
                if !self.singleView {
                    self.collapsedContentView.alpha = 1 - progress
                    self.expandedContentView?.alpha = progress
                }
                self.delegate?.floatingButtonSheetDidUpdate(sheet: self, progress: progress)
            }
        case .ended:
            let resultH: CGFloat = heightConstraint!.constant / maximumHeight
            if resultH < 0.5 {
                /// Collapse view
                self.heightConstraint?.constant = minimumHeight
                self.bottomMarginConstraint?.constant = -maximumInset
                self.horizontalMarginConstraint?.first?.constant = maximumInset
                self.horizontalMarginConstraint?.last?.constant = maximumInset
                
                delegate?.floatingBottomSheetDidCollapse()
            } else {
                /// Expand view
                self.heightConstraint?.constant = maximumHeight
                self.bottomMarginConstraint?.constant = -minimumInset
                self.horizontalMarginConstraint?.first?.constant = minimumInset
                self.horizontalMarginConstraint?.last?.constant = minimumInset
                
                delegate?.floatingBottomSheetDidExpand()
            }
            initHeight = heightConstraint!.constant
            UIView.animate(withDuration: 0.2) {
                
                self.dimView?.alpha = resultH < 0.5 ? 0 : 0.5
                if !self.singleView {
                    self.collapsedContentView.alpha = resultH < 0.5 ? 1 : 0
                    self.expandedContentView?.alpha = resultH > 0.5 ? 1 : 0
                }
                
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
            }
        default: break
        }
    }
}
