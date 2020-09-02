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

public final class FloatingBottomSheetView: UIView {
    // MARK: - Typealias
    public typealias sheet = FloatingBottomSheetView
    
    // MARK: - Properties
    public static var defaultFrame: CGRect = CGRect(x: 0, y: 0, width: 320, height: 72)
    
    public dynamic var cornerRadius: CGFloat = 8 {
        didSet {
            cornerRadius = max(cornerRadius, 0)
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = true
        }
    }
    
    public dynamic var horizontalMargin: CGFloat = 16 {
        didSet {
            horizontalMarginConstraint?.forEach({ $0.constant = horizontalMargin })
            superview?.layoutIfNeeded()
        }
    }
    
    public dynamic var bottomMargin: CGFloat = 16 {
        didSet {
            bottomMarginConstraint?.constant = bottomMargin
            superview?.layoutIfNeeded()
        }
    }
    
    public dynamic var minimumInset: CGFloat = 0 {
        didSet {
            if minimumInset < 0 { minimumInset = 0 }
            initInset = minimumInset
        }
    }
    
    public dynamic var maximumInset: CGFloat = 16
    
    public dynamic var minimumHeight: CGFloat = 72 {
        didSet {
            if minimumHeight < 10 { minimumHeight = 10 }
            initHeight = minimumHeight
        }
    }
    
    public dynamic var maximumHeight: CGFloat = 270
    
    public dynamic var drawerBackgroundColor: UIColor = .white
    
    public dynamic var showDrawerView: Bool = true
    public dynamic var shouldDimSuperview: Bool = true
    
    /// Collapsed content view, this view will be shown when bottom sheet is collapsed.
    @objc public dynamic var collapsedContentView: UIView!
    
    /// Expanded content view, this view will be shown when bottom sheet is expanded.
    @objc public dynamic var expandedContentView: UIView!
    
    var delegate: FloatingBottomSheetDelegate?
    
    // MARK: - Private Properties
    fileprivate var superView: UIView!
    fileprivate var dimView: UIView?
    
    fileprivate var pan: UIPanGestureRecognizer!
    fileprivate var contentView: UIView!
    
    fileprivate var horizontalMarginConstraint: [NSLayoutConstraint]? = nil
    fileprivate var bottomMarginConstraint: NSLayoutConstraint? = nil
    fileprivate var heightConstraint: NSLayoutConstraint? = nil
    
    fileprivate var initHeight: CGFloat = 72
    fileprivate var initInset: CGFloat = 16
    
    // MARK: - init
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        super.init(frame: sheet.defaultFrame)
    }
    
    public init(collapsedView: UIView, expandedView: UIView) {
        super.init(frame: sheet.defaultFrame)
        self.collapsedContentView = collapsedView
        self.expandedContentView = expandedView
    }
}

extension FloatingBottomSheetView {
    // MARK: - Configuration
    public func configure(in superview: UIView) {
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
        
        guard let collapsedContentView = collapsedContentView,
            let expandedContentView = expandedContentView else {
                fatalError("Collapsed and expanded view must be set.")
        }
        
        contentView.addSubview(collapsedContentView)
        contentView.addSubview(expandedContentView)
        if showDrawerView { contentView.addSubview(drawerView) }
        
        expandedContentView.alpha = 0
        
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
            
        let expandedViewHConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-0-[expandedView]-0-|",
            options: .init(rawValue: 0),
            metrics: nil,
            views: ["expandedView": expandedContentView])
        
        let expandedViewVConstrains = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-16-[expandedView]-0-|",
            options: .init(rawValue: 0),
            metrics: nil,
            views: ["expandedView": expandedContentView])
        
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
        
        contentView.addConstraint(drawerWidthConstraint)
        contentView.addConstraint(drawerHConstraints)
        contentView.addConstraints(drawerVConstraints)
        contentView.addConstraints(collapsedViewVConstrains)
        contentView.addConstraints(collapsedViewHConstraints)
        contentView.addConstraints(expandedViewHConstraints)
        contentView.addConstraints(expandedViewVConstrains)
        
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
    
    public func check() -> Bool {
        return contentView != nil
    }
    
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

// MARK: - Actions
private extension FloatingBottomSheetView {
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
                self.collapsedContentView.alpha = 1 - progress
                self.expandedContentView.alpha = progress
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
                self.collapsedContentView.alpha = resultH < 0.5 ? 1 : 0
                self.expandedContentView.alpha = resultH > 0.5 ? 1 : 0
                
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
            }
        default: break
        }
    }
}
