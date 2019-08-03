//
//  TDCToDoListController.swift
//  ToDoClearStyle
//
//  Created by LuanMa on 16/1/2.
//  Copyright © 2016年 luanma. All rights reserved.
//
//  参考 https://github.com/ColinEberhardt/iOS-ClearStyle
//

import UIKit

class TDCToDoListController: UITableViewController {
    
    var items = [
        TDCToDoItem(text: "Feed the cat"),
        TDCToDoItem(text: "Buy eggs"),
        TDCToDoItem(text: "Pack bags for WWDC"),
        TDCToDoItem(text: "Rule the web"),
        TDCToDoItem(text: "Buy a new iPhone"),
        TDCToDoItem(text: "Find missing socks"),
        TDCToDoItem(text: "Write a new tutorial"),
        TDCToDoItem(text: "Master Objective-C"),
        TDCToDoItem(text: "Remember your wedding anniversary!"),
        TDCToDoItem(text: "Drink less beer"),
        TDCToDoItem(text: "Learn to draw"),
        TDCToDoItem(text: "Take the car to the garage"),
        TDCToDoItem(text: "Sell things on eBay"),
        TDCToDoItem(text: "Learn to juggle"),
        TDCToDoItem(text: "Give up")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)) )
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)) )
        
        tableView.addGestureRecognizer(pinch)
        tableView.addGestureRecognizer(longPress)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backgroundColor(indexPath: NSIndexPath) -> UIColor {
        let val: CGFloat = CGFloat(indexPath.row) / CGFloat(items.count - 1) * 0.6
        return UIColor(red: 1, green: val, blue: 0, alpha: 1)
    }
    
    /*
     // 简单删除
     func deleteToDoItem(indexPath: NSIndexPath) {
     tableView.beginUpdates()
     items.removeAtIndex(indexPath.row)
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
     tableView.endUpdates()
     }
     */
    
    // 更漂亮视觉效果的删除
    func deleteToDoItem(indexPath: NSIndexPath) {
        let item = items.remove(at: indexPath.row)
        var animationEnabled = false
        let lastCell = tableView.visibleCells.last
        var delay: TimeInterval = 0
        for cell in tableView.visibleCells {
            let cell = cell as! TDCToDoItemCell
            if animationEnabled {
                
                UIView.animate(withDuration: 0.25, delay: delay, options: [.curveEaseInOut], animations: {
                    cell.frame.offsetBy(dx: 0, dy: -cell.frame.height)
                }, completion: { (completed) -> Void in
                    if cell == lastCell {
                        self.tableView.reloadData()
                    }
                })
                delay += 0.03
            }
            
            if cell.toDoItem == item {
                animationEnabled = true
                cell.isHidden = true
            }
        }
    }
    
    // MARK: - Pinch
    
    // 插入点
    private var pinchIndexPath: IndexPath?
    // 临时代理视图
    private var placheHolderCell: TDCPlaceHolderView?
    // 两触点的起始位置
    private var sourcePoints: (upperPoint: CGPoint, downPoint: CGPoint)?
    // 可以插入操作的标志
    private var pinchInsertEnabled = false
    
    @objc func handlePinch(_ pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .began:
            pinchBegan(pinch: pinch)
        case .changed:
            pinchChanged(pinch: pinch)
        default:
            pinchEnd(pinch: pinch)
        }
    }
    
    func pinchBegan(pinch: UIPinchGestureRecognizer) {
        pinchIndexPath = nil
        sourcePoints = nil
        pinchInsertEnabled = false
        
        let (upperPoint, downPoint) = pointsOfPinch(pinch: pinch)
        if let upperIndexPath = tableView.indexPathForRow(at: upperPoint),
            let downIndexPath = tableView.indexPathForRow(at: downPoint) {
            if downIndexPath.row - upperIndexPath.row == 1 {
                let upperCell = tableView.cellForRow(at: upperIndexPath)!
                let placheHolder = Bundle.main.loadNibNamed("TDCPlaceHolderView", owner: tableView, options: nil)?.first as! TDCPlaceHolderView
                placheHolder.frame.offsetBy(dx: 0, dy: upperCell.frame.height / 2)
                tableView.insertSubview(placheHolder, at: 0)
                
                sourcePoints = (upperPoint, downPoint)
                pinchIndexPath = upperIndexPath
                placheHolderCell = placheHolder
            }
        }
    }
    
    func pinchChanged(pinch: UIPinchGestureRecognizer) {
        if let pinchIndexPath = pinchIndexPath, let originPoints = sourcePoints, let placheHolderCell = placheHolderCell {
            let points = pointsOfPinch(pinch: pinch)
            
            let upperDistance = points.0.y - originPoints.upperPoint.y
            let downDistance = originPoints.downPoint.y - points.1.y
            let distance = -min(0, min(upperDistance, downDistance))
            NSLog("distance=\(distance)")
            
            // 移动两边的Cell
            for cell in tableView.visibleCells {
                let indexPath = tableView.indexPath(for: cell)!
                if indexPath.row <= pinchIndexPath.row {
                    cell.transform = CGAffineTransform(translationX: 0, y: -distance)
                } else {
                    cell.transform = CGAffineTransform(translationX: 0, y: distance)
                }
            }
            
            // 插入的Cell变形
            let scaleY = min(64, abs(distance) * 2) / CGFloat(64)
            placheHolderCell.transform = CGAffineTransform(scaleX: 1, y: scaleY)
            
            placheHolderCell.lblTitle.text = scaleY <= 0.5 ? "张开双指插入新项目": "松手可以插入新项目"
            
            // 张开超过一个Cell高度时，执行插入操作
            pinchInsertEnabled = scaleY >= 1
        }
    }
    
    func pinchEnd(pinch: UIPinchGestureRecognizer) {
        if let pinchIndexPath = pinchIndexPath, let placheHolderCell = placheHolderCell {
            placheHolderCell.transform = CGAffineTransform.identity
            placheHolderCell.removeFromSuperview()
            self.placheHolderCell = nil
            
            if pinchInsertEnabled {
                // 恢复各Cell的transform
                for cell in self.tableView.visibleCells {
                    cell.transform = CGAffineTransform.identity
                }
                
                // 插入操作
                let index = pinchIndexPath.row + 1
                items.insert(TDCToDoItem(text: ""), at: index)
                tableView.reloadData()
                
                // 弹出键盘
                let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! TDCToDoItemCell
                cell.txtField.becomeFirstResponder()
            } else {
                // 放弃插入，恢复原位置
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: { [unowned self] () -> Void in
                    for cell in self.tableView.visibleCells {
                        cell.transform = CGAffineTransform.identity
                    }
                    }, completion: { [unowned self] (completed) -> Void in
                        self.tableView.reloadData()
                })
            }
        }
        
        sourcePoints = nil
        pinchIndexPath = nil
        pinchInsertEnabled = false
    }
    
    func pointsOfPinch(pinch: UIPinchGestureRecognizer) -> (CGPoint, CGPoint) {
        if pinch.numberOfTouches > 1 {
            let point1 = pinch.location(ofTouch: 0, in: tableView)
            let point2 = pinch.location(ofTouch: 1, in: tableView)
            if point1.y <= point2.y {
                return (point1, point2)
            } else {
                return (point2, point1)
            }
        } else {
            let point = pinch.location(ofTouch: 0, in: tableView)
            return (point, point)
        }
    }
    
    // MARK: - Drag & Drop
    
    private var sourceIndexPath: IndexPath?
    private var snapView: UIView?
    
    @objc func handleLongPress(_ longPress: UILongPressGestureRecognizer) {
        let point = longPress.location(in: tableView)
        
        if let indexPath = tableView.indexPathForRow(at: point) {
            switch longPress.state {
            case .began:
                if let cell = tableView.cellForRow(at: indexPath) {
                    sourceIndexPath = indexPath
                    let snapView = self.snapView(view: cell)
                    snapView.alpha = 0
                    
                    self.snapView = snapView
                    
                    tableView.addSubview(snapView)
                    
                    UIView.animate(withDuration: 0.25, animations: {
                        // 选中Cell跳出放大效果
                        snapView.alpha = 0.95
                        snapView.center = CGPoint(x: cell.center.x, y: point.y)
                        snapView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                        
                        cell.alpha = 0
                    }, completion: { (completed) -> Void in
                        cell.isHidden = true
                        cell.alpha = 1
                    })
                } else {
                    sourceIndexPath = nil
                    snapView = nil
                    break
                }
            case .changed:
                if let snapView = snapView {
                    // 截图随手指上下移动
                    snapView.center = CGPoint(x: snapView.center.x, y: point.y)
                }
                
                // 如果手指移动到一个新的Cell上面，隐藏Cell跟此Cell交换位置
                if let fromIndexPath = sourceIndexPath {
                    if fromIndexPath != indexPath {
                        tableView.beginUpdates()
                        let temp = items[indexPath.row]
                        items[indexPath.row] = items[fromIndexPath.row]
                        items[fromIndexPath.row] = temp
                        tableView.moveRow(at: fromIndexPath, to: indexPath)
                        tableView.endUpdates()
                        sourceIndexPath = indexPath
                    }
                }
                
                // 手指移动到屏幕顶端或底部，UITableView自动滚动
                let step: CGFloat = 64
                if let parentView = tableView.superview {
                    let parentPos = tableView.convert(point, to: parentView)
                    if parentPos.y > parentView.bounds.height - step {
                        var offset = tableView.contentOffset
                        offset.y += (parentPos.y - parentView.bounds.height + step)
                        if offset.y > tableView.contentSize.height - tableView.bounds.height {
                            offset.y = tableView.contentSize.height - tableView.bounds.height
                        }
                        tableView.setContentOffset(offset, animated: false)
                    } else if parentPos.y <= step {
                        var offset = tableView.contentOffset
                        offset.y -= (step - parentPos.y)
                        if offset.y < 0 {
                            offset.y = 0
                        }
                        tableView.setContentOffset(offset, animated: false)
                    }
                }
            default:
                if let snapView = snapView, let fromIndexPath = sourceIndexPath, let cell = tableView.cellForRow(at: fromIndexPath) {
                    cell.alpha = 0
                    cell.isHidden = false
                    
                    // 长按移动结束，隐藏的Cell恢复显示，删除截图
                    UIView.animate(withDuration: 0.25, animations: { () -> Void in
                        snapView.center = cell.center
                        snapView.alpha = 0
                        
                        cell.alpha = 1
                    }, completion: { [unowned self] (completed) -> Void in
                        snapView.removeFromSuperview()
                        self.snapView = nil
                        self.sourceIndexPath = nil
                        
                        self.tableView.perform(#selector(self.tableView.reloadData), with: nil, afterDelay: 0.5)
                    })
                }
            }
        }
    }
    
    // UIView截图为UIImageView
    func snapView(view: UIView) -> UIImageView {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let snapShot = UIImageView(image: image)
        snapShot.layer.masksToBounds = false;
        snapShot.layer.cornerRadius = 0;
        snapShot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0);
        snapShot.layer.shadowOpacity = 0.4;
        snapShot.layer.shadowRadius = 5;
        snapShot.frame = view.frame
        return snapShot
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TDCToDoItemCell.cellId, for: indexPath) as! TDCToDoItemCell
        let toDoItem = items[indexPath.row]
        cell.toDoItem = toDoItem
        cell.centerPannel.backgroundColor = toDoItem.completed ? UIColor(red: 0, green: 0.6, blue: 0, alpha: 1): backgroundColor(indexPath: NSIndexPath(item: indexPath.row, section: indexPath.section))
        
        cell.onDelete = { [unowned self] cell in
            if let indexPath = tableView.indexPath(for: cell) {
                self.deleteToDoItem(indexPath: NSIndexPath(item: indexPath.row, section: indexPath.section))
            }
        }
        
        cell.onComplete = { [unowned self] cell in
            if let indexPath = tableView.indexPath(for: cell) {
                let toDoItem = self.items[indexPath.row]
                toDoItem.completed = !toDoItem.completed
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        
        return cell
    }
    
}
