//
//  FlatActionSheetController.swift
//  FlatActionSheetController
//
//  Created by Thanh-Nhon Nguyen on 8/17/16.
//  Copyright © 2016 Thanh-Nhon Nguyen. All rights reserved.
//

import UIKit

// MARK: FlatAction
struct FlatAction {
    let icon: UIImage?
    let title: String
    let handler: (() -> Void)?
}

// MARK: FlatActionSheetConfiguration
struct FlatActionSheetConfiguration {
    var dimBackgroundColor: UIColor = UIColor.blackColor()
    var dimBackgroundAlpha: CGFloat = 0.3
    var animationDuration: NSTimeInterval = 0.25
    var textFont: UIFont = UIFont.systemFontOfSize(13)
    var textColor: UIColor = UIColor.darkGrayColor()
    var wrapText: Bool = true
    var iconSize: CGSize = CGSize(width: 15, height: 15)
    var maxHeight: CGFloat = UIScreen.mainScreen().bounds.height*2/3
}

// MARK: FlatActionSheetController
final class FlatActionSheetController: UIViewController {
    var didDismiss: (() -> Void)?
    var configuration: FlatActionSheetConfiguration {
        get {
            return FlatActionSheetController.sharedConfiguration
        }
        set {
            FlatActionSheetController.sharedConfiguration = newValue
        }
    }
    
    // Private elements
    static private var sharedConfiguration = FlatActionSheetConfiguration()
    private let applicationWindow: UIWindow!
    private var actions: [FlatAction]
    private var dimBackgroundView: UIView
    private let tableView: UITableView
    
    init() {
        applicationWindow = UIApplication.sharedApplication().delegate?.window!
        actions = []
        dimBackgroundView = UIView()
        tableView = UITableView(frame: applicationWindow.frame, style: UITableViewStyle.Plain)
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = UIModalPresentationStyle.Custom
        modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(withActions actions: [FlatAction]) {
        self.init()
        self.actions = actions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addDimBackgroundView()
        addTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animateWithDuration(configuration.animationDuration) { [unowned self] in
            
            if self.tableView.contentSize.height <= self.configuration.maxHeight {
                self.tableView.frame.origin = CGPoint(x: 0, y: self.applicationWindow.frame.height - self.tableView.contentSize.height)
            } else {
                self.tableView.frame.origin = CGPoint(x: 0, y: self.applicationWindow.frame.height - self.configuration.maxHeight)
            }
        }
    }
    
    private func dismiss(completion: (() -> Void)? = nil) {
        UIView.animateWithDuration(configuration.animationDuration, animations: {[unowned self] in
            self.tableView.frame.origin = CGPoint(x: 0, y: self.applicationWindow.frame.height)
            self.dimBackgroundView.alpha = 0
        }) { [unowned self] (finished) in
            self.tableView.removeFromSuperview()
            self.dimBackgroundView.removeFromSuperview()
            self.didDismiss?()
            self.dismissViewControllerAnimated(true, completion: completion)
        }
    }
    
    // Dim background
    private func addDimBackgroundView() {
        dimBackgroundView = UIView(frame: applicationWindow.frame)
        dimBackgroundView.backgroundColor = configuration.dimBackgroundColor.colorWithAlphaComponent(configuration.dimBackgroundAlpha)
        let tap = UITapGestureRecognizer(target: self, action: #selector(FlatActionSheetController.dimBackgroundViewTapped))
        dimBackgroundView.userInteractionEnabled = true
        dimBackgroundView.addGestureRecognizer(tap)
        applicationWindow.addSubview(dimBackgroundView)
        dimBackgroundView.alpha = 0
        UIView.animateWithDuration(configuration.animationDuration) { [unowned self] in
            self.dimBackgroundView.alpha = 1
        }
    }
    
    @objc private func dimBackgroundViewTapped() {
        dismiss()
    }
    
    // TableView
    private func addTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = UIColor.clearColor()
        tableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
        tableView.registerClass(FlatActionTableViewCell.self, forCellReuseIdentifier: "\(FlatActionTableViewCell.self)")
        tableView.frame.origin = CGPoint(x: 0, y: applicationWindow.frame.height)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50
        applicationWindow.addSubview(tableView)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if tableView.contentSize.height <= configuration.maxHeight {
            tableView.frame.size = tableView.contentSize
            tableView.scrollEnabled = false
        } else {
            tableView.frame.size = CGSize(width: tableView.frame.width, height: configuration.maxHeight)
            tableView.scrollEnabled = true
        }
    }
    
    deinit {
        tableView.removeObserver(self, forKeyPath: "contentSize")
    }
}

extension FlatActionSheetController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("\(FlatActionTableViewCell.self)", forIndexPath: indexPath) as! FlatActionTableViewCell
        
        let action = actions[indexPath.row]
        cell.titleLabel.text = action.title
        cell.iconImageView.image = action.icon
        
        return cell
    }
}

extension FlatActionSheetController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let action = actions[indexPath.row]
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        dismiss {
            action.handler?()
        }
    }
}

// MARK: FlatActionTableViewCell
private final class FlatActionTableViewCell: UITableViewCell {
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: iconImageView, attribute: .Leading, relatedBy: .Equal, toItem: contentView, attribute: .LeadingMargin, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: iconImageView, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: iconImageView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1, constant: FlatActionSheetController.sharedConfiguration.iconSize.width).active = true
        NSLayoutConstraint(item: iconImageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: FlatActionSheetController.sharedConfiguration.iconSize.height).active = true
        
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        if FlatActionSheetController.sharedConfiguration.wrapText == true {
            titleLabel.numberOfLines = 1
        } else {
            titleLabel.numberOfLines = 0
        }
        titleLabel.font = FlatActionSheetController.sharedConfiguration.textFont
        titleLabel.textColor = FlatActionSheetController.sharedConfiguration.textColor
        NSLayoutConstraint(item: titleLabel, attribute: .Leading, relatedBy: .Equal, toItem: iconImageView, attribute: .Trailing, multiplier: 1, constant: 15).active = true
        NSLayoutConstraint(item: titleLabel, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .TrailingMargin, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: titleLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: titleLabel, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: 10).active = true
        NSLayoutConstraint(item: titleLabel, attribute: .Bottom, relatedBy: .Equal, toItem: contentView, attribute: .Bottom, multiplier: 1, constant: -10).active = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
    }
}