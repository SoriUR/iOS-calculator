//  Created by Юрий Сорокин on 24/10/2017.
//  Copyright © 2017 ITMO University. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        addButtonsToArray(for: view)
        roundUpTheButtons()
        
    }
  
    @IBOutlet weak var equalsButton: UIButton!
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var radiansStateLabel: UILabel!
    
    var lastPressedOperand: UIButton?
    var inTheMiddleOftyping = false
    var radianMode = false
   
    var buttonsArray: [UIButton] = []
    
    var stack  = Stack()
    lazy var model = Model.init(stack: stack) //didnt need it eventually, but did i use "lazy" right?
    
    var symbol: Double {
        get {
            stack.push(symbol: display.text!)
            return Double(display.text!)!
        }
        set {
            let stringFromDouble = converDoubleToString(newValue)
            display.text = stringFromDouble
            
            if stack.isEmpty {
                stack.push(symbol: stringFromDouble)
            } else if stack.getIndexValue(at:  0) != stringFromDouble{
                stack.push(symbol: stringFromDouble)
            }
        }
    }
    
    let titlesForButtonsWithTwoStates: [(firstState: String,secondState: String)] = [
        ("log₁₀", "log₂"),
        ("ln", "logᵧ"),
        ("10ˣ", "2ˣ"),
        ("eˣ", "yˣ"),
        ("cos", "cos⁻¹"),
        ("sin", "sin⁻¹"),
        ("tan", "tan⁻¹"),
        ("cosh", "cosh⁻¹"),
        ("sinh", "sinh⁻¹"),
        ("tanh", "tanh⁻¹")
    ]
    
    func addButtonsToArray (for view: UIView) {
        for subview in view.subviews {
            if let stack = subview as? UIStackView {
            addButtonsToArray(for: stack)
            } else if let button = subview as? UIButton {
                buttonsArray.append(button)
            }
        }
    }
    
    func resetSelectionForAllButtons() {
        for button in buttonsArray {
            button.isSelected = false
        }
    }
    
    func roundUpTheButtons() {
        for button in buttonsArray {
            button.layer.cornerRadius = min(button.layer.bounds.size.height,button.layer.bounds.size.width) * (traitCollection.horizontalSizeClass == .compact ? 0.7 : 0.9)
            button.layer.masksToBounds = true
        }
    }
    
    private func changeTitlesForButtonsWithTwoStates(for view: UIView) {
        for button in buttonsArray {
            for (firstStateTitle, secondStateTitle) in titlesForButtonsWithTwoStates {
                if button.currentTitle==firstStateTitle {
                    button.setTitle(secondStateTitle, for: .normal)
                } else if button.currentTitle==secondStateTitle {
                    button.setTitle(firstStateTitle, for: .normal)
                }
            }
        }
    }
    
    func changeSelectionOfOperationButton(with title: String,in view: UIView) {
        for button in buttonsArray {
            if button.currentTitle! == title {
                button.isSelected = !button.isSelected
            }
        }
    }
    
    @IBAction func changeTitlesTo2ndState(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        changeTitlesForButtonsWithTwoStates(for: view)
    }
    
    @IBAction func switchRadianMode(_ sender: UIButton) {
        model.degreesMode = !model.degreesMode
        sender.setTitle(model.degreesMode ? "Rad" : "Deg", for: .normal)
        radiansStateLabel.text = model.degreesMode ? "" : "Rad"
    }
    
    func performClickAnimation(for title: String) {
        for button in buttonsArray {
            if button.currentTitle! == title {
            UIView.transition(with: button,
                          duration: 0.2,
                          options: .transitionCrossDissolve,
                          animations: { button.isHighlighted = true },
                          completion: { if $0 { button.isHighlighted = false }})
            }
        }
    }
    
    @IBAction func undo(_ sender: UIButton) {
        if !stack.isEmpty {
            let symbol = stack.pop()
            switch symbol{
            case .digit(_):
                if stack.isEmpty {
                    display.text = "0"
                    return
                }
                let prevOperationTitle = stack.getIndexValue(at: 0)
                if Double(prevOperationTitle) != nil { //another digit
                    display.text = prevOperationTitle
                    return
                }
                //operation
                let prevOperationType = model.getOperationType(of: prevOperationTitle)
                switch prevOperationType {
                case .equals,.unaryOperation(_),.trigonometryOperation(_): //display prev digit
                    display.text = stack.getIndexValue(at:1)
                    _ = stack.pop()
                case .binaryOperation(_): //select operation button
                    changeSelectionOfOperationButton(with: prevOperationTitle,in: view)
                    fallthrough
                default: // display prev operation
                    display.text = stack.getIndexValue(at:1)
                    break
                }
            case .operation(let operandTitle): //select operation button and display prev digit
                changeSelectionOfOperationButton(with: operandTitle, in: view)
                display.text = stack.getIndexValue(at:0)
            }
        }
    }
    
    @IBAction func redo(_ sender: UIButton) {
        let stackWasEmpty = stack.isEmpty
        if !stack.isFull{
            let symbol = stack.goForward()
            switch symbol {
            case .digit(let value): //dispaly digit's value, probably select prev opearation button
                display.text = value
                if !stackWasEmpty{
                    let prevOperandTitle = stack.getIndexValue(at:1)
                    changeSelectionOfOperationButton(with: prevOperandTitle, in: view)
                    performClickAnimation(for: value)
                }
            case .operation(let title):   //select operation
                changeSelectionOfOperationButton(with: title, in: view)
                let operationType = model.getOperationType(of: stack.getIndexValue(at: 0))
                switch operationType {
                case .equals,.unaryOperation(_),.trigonometryOperation(_): // if its not binary operation, display operation result, and push opertion
                    _ = stack.goForward()
                    self.symbol = Double(stack.getIndexValue(at: 0))!
                    performClickAnimation(for: title)
                default:
                    break
                }
            }
        }
    }
    
    @IBAction func clear (_ sender: UIButton) {
        stack = Stack()
        model = Model.init(stack: stack)
        inTheMiddleOftyping = false
        display.text = "0"
        resetSelectionForAllButtons()
    }
    
    @IBAction func pressDigit(_ sender: UIButton) {
        resetSelectionForAllButtons()
        let digit = sender.currentTitle!
        if inTheMiddleOftyping {
            let currentlyAtScreen = display.text!
            if Double(currentlyAtScreen+digit) != nil {
                display.text = currentlyAtScreen+digit
            }
        } else {
            display.text! = digit == "." ? "0." : digit
        }
        inTheMiddleOftyping = true
    }
    
    @IBAction func performOperation (_ sender: UIButton) {
        let stackHasChanged = stack.reset()
        let operationTitle = sender.currentTitle!
        if stackHasChanged { //have i just done an undo
            let topStackSymbol = stack.getIndexValue(at: 0)
            model = Model.init(stack: stack)
            if Double(topStackSymbol) == nil { //do i have an operation on top of the stack?
                model.setOperand(Double(stack.getIndexValue(at: 1))!) //send prev operand
                model.doOperation(stack.getIndexValue(at: 0)) //send prev opeartion
               model.setOperand(symbol) //send to model what i just typed
                changeSelectionOfOperationButton(with: operationTitle, in: view)
                 inTheMiddleOftyping = false
            } else { //calculate a new value from the stack and send it the model
                stack.putResultOnTop()
                model.setOperand(Double(stack.getIndexValue(at: 0))!)
            }
        } else if inTheMiddleOftyping {
            model.setOperand(symbol)
            inTheMiddleOftyping = false
        }
        
        lastPressedOperand?.isSelected = false
        sender.isSelected = true
        lastPressedOperand = sender
        
        model.doOperation(operationTitle)
        
        stack.push(symbol: operationTitle)
        
        if let res = model.result {
            symbol = res
        }
    }
}
