//
//  TDCToDoItemCell.swift
//  ToDoClearStyle
//
//  Created by LuanMa on 16/1/2.
//  Copyright © 2016年 luanma. All rights reserved.
//

import UIKit

class TDCToDoItemCell: UITableViewCell, UITextFieldDelegate {
    
    static let cellId = "ToDoItemCell"
    
    @IBOutlet weak var centerPannel: UIView!
    @IBOutlet weak var leftPannel: UIView!
    @IBOutlet weak var rightPannel: UIView!
    
    @IBOutlet weak var txtField: UITextField!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    private var originConstant: CGFloat = 0
    
    var toDoItem: TDCToDoItem! {
        didSet {
            if let item = toDoItem {
                txtField.text = item.text
            } else {
                txtField.text = ""
                isSelected = false
            }
        }
    }
    
    var onDelete: ((TDCToDoItemCell) -> Void)?
    var onComplete: ((TDCToDoItemCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        leftLabel.text = "\u{2713}"     //对号
        rightLabel.text = "\u{2717}"    //叉号
        
        // add a layer that overlays the cell adding a subtle gradient effect
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = centerPannel.bounds
        gradientLayer.colors = [UIColor(white: 1, alpha: 0.2).cgColor,
                                UIColor(white: 1, alpha: 0.1).cgColor,
                                UIColor.clear.cgColor,
                                UIColor(white: 0, alpha: 0.1).cgColor
        ]
        gradientLayer.locations = [NSNumber(value: 0), NSNumber(value: 0.01), NSNumber(value: 0.95), NSNumber(value: 1)]
        centerPannel.layer.insertSublayer(gradientLayer, at: 0)
        
        // 添加Pan手势
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panGesture:)))
        recognizer.delegate = self
        self.addGestureRecognizer(recognizer)
    }
    
    // 如果是划动手势，仅支持左右划动；如果是其它手势，则有父类负责
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGesture.translation(in: self.superview)
            return abs(translation.x) > fabs(translation.y)
        } else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
    }
    
    private var deleteOnDragRelease: Bool = false
    private var completeOnDragRelease: Bool = false
    
    @objc func handlePan(panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began:
            originConstant = centerConstraint.constant
        case .changed:
            let translation = panGesture.translation(in: self)
            centerConstraint.constant = translation.x
            
            // 划动移动1/3宽度为有效划动
            let finished = abs(translation.x) > bounds.width / 3
            if translation.x < originConstant { // 右划
                if finished {
                    deleteOnDragRelease = true
                    rightLabel.textColor = UIColor.red
                } else {
                    deleteOnDragRelease = false
                    rightLabel.textColor = UIColor.white
                }
            } else { // 左划
                if finished {
                    completeOnDragRelease = true
                    leftLabel.textColor = UIColor.green
                } else {
                    completeOnDragRelease = false
                    leftLabel.textColor = UIColor.white
                }
            }
        case .ended:
            centerConstraint.constant = originConstant
            
            if deleteOnDragRelease {
                deleteOnDragRelease = false
                if let onDelete = onDelete {
                    onDelete(self)
                }
            }
            
            if completeOnDragRelease {
                completeOnDragRelease = false
                if let onComplete = onComplete {
                    onComplete(self)
                }
            }
        default:
            break
        }
    }
    
    func hideKeyboard() {
        txtField.resignFirstResponder()
        txtField.text = toDoItem.text
    }
    
    // Mark - UITextFieldDelegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return !toDoItem.completed
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        toDoItem.text = textField.text!
        return false
    }
}
