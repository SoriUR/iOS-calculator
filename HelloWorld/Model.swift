//  Created by Юрий Сорокин on 24/10/2017.
//  Copyright © 2017 ITMO University. All rights reserved.
//

import Foundation

func converDoubleToString(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 9
    let stringFromDouble = formatter.string(from: NSNumber(value: value))!
//    if stringFromDouble.first == "."{
//        stringFromDouble = "0"+stringFromDouble
//    }
    return stringFromDouble
}

class Model {
    
    var stack: Stack
    var degreesMode = true
    private var accumulator: Double?
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    private var resultIsPending: Bool {
        return pendingBinaryOperation != nil
    }
    
    var result: Double? {
        return accumulator
    }
    
    private var operators: [String: OperationType] = [
    //constants
        "π": OperationType.constant(Double.pi),
         "e": OperationType.constant(M_E),
    //unary
        "²√x": OperationType.unaryOperation(sqrt),
        "∛x": OperationType.unaryOperation({pow($0, 1/3)}),
        "x²": OperationType.unaryOperation({$0*$0}),
        "x³": OperationType.unaryOperation({pow($0, 3)}),
        "x⁻¹": OperationType.unaryOperation({1/$0}),
        "ln": OperationType.unaryOperation({log($0)/log(M_E)}),
        "log₁₀": OperationType.unaryOperation(log10),
        "log₂": OperationType.unaryOperation(log2),
        "x!": OperationType.unaryOperation(factorial),
        "10ˣ": OperationType.unaryOperation({pow(10, $0)}),
        "2ˣ": OperationType.unaryOperation({pow(2, $0)}),
        "eˣ": OperationType.unaryOperation({pow(M_E, $0)}),
        "cos": OperationType.trigonometryOperation(cos),
        "sin": OperationType.trigonometryOperation(sin),
        "tan": OperationType.trigonometryOperation(tan),
        "sinh": OperationType.trigonometryOperation(sinh),
        "cosh": OperationType.trigonometryOperation(cosh),
        "tanh": OperationType.trigonometryOperation(tanh),
        "cos⁻¹": OperationType.trigonometryOperation({1/cos($0)}),
        "sin⁻¹": OperationType.trigonometryOperation({1/sin($0)}),
        "tan⁻¹": OperationType.trigonometryOperation({1/tan($0)}),
        "sinh⁻¹": OperationType.trigonometryOperation({1/sinh($0)}),
        "cosh⁻¹": OperationType.trigonometryOperation({1/cosh($0)}),
        "tanh⁻¹": OperationType.trigonometryOperation({1/tanh($0)}),
        "%": OperationType.unaryOperation({$0/100}),
        "±": OperationType.unaryOperation({-$0}),
        //binary
        "logᵧ": OperationType.binaryOperation({log($1)/log($0)}),
        "+": OperationType.binaryOperation({$0+$1}),
        "-": OperationType.binaryOperation({$0-$1}),
        "×": OperationType.binaryOperation(*),
        "÷": OperationType.binaryOperation(/),
        "ʸ√x": OperationType.binaryOperation({pow($0, 1.0/$1)}),
        "xʸ": OperationType.binaryOperation({pow($1, $0)}),
         "yˣ": OperationType.binaryOperation({pow($0, $1)}),
        "EE": OperationType.binaryOperation({$0*pow(10, $1)}),
        //random and equals
        "Rand": OperationType.random(generateRandomDoubleValue),
        "=": OperationType.equals
    ]
    
    init(stack: Stack) {
        self.stack = stack
    }
    
    enum OperationType {
        case constant(Double)
        case unaryOperation((Double)->Double)
        case trigonometryOperation((Double)->Double)
        case binaryOperation((Double, Double)->Double)
        case equals
        case random(()->Double)
    }
    
    private struct PendingBinaryOperation {
        let function: (Double, Double) -> Double
        let firstOperand: Double
        func perform (with secondOperand: Double) -> Double {
            return (function(firstOperand, secondOperand))
        }
    }
    
     func doOperation (_ symbol: String) {
        guard let operation = operators[symbol] else {
            return
        }
        switch (operation, accumulator) {
        case (.constant(let value), _):
            accumulator = value
        case (.trigonometryOperation(let function), Optional.some):
            checkAndProbablyPerformPendingOperation()
            accumulator = degreesMode ? radiansToDegree(accumulator!) : accumulator!
            accumulator = function(accumulator!)
            pendingBinaryOperation=nil
        case (.unaryOperation(let function), Optional.some):
            checkAndProbablyPerformPendingOperation()
            accumulator = (function(accumulator!))
            pendingBinaryOperation = nil
        case (.binaryOperation(let function), Optional.some):
            checkAndProbablyPerformPendingOperation()
            pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: accumulator!)
            accumulator = nil
            if pendingBinaryOperation != nil {
                pendingBinaryOperation=PendingBinaryOperation(function: function, firstOperand: (pendingBinaryOperation!.firstOperand))
            }
        case (.equals, Optional.some):
            if pendingBinaryOperation != nil {
                accumulator = pendingBinaryOperation!.perform(with: accumulator!)
                pendingBinaryOperation=nil
            }
        case (.random(let function), _):
            accumulator = function()
        default:
            break
        }
    }
    
    func setOperand (_ operand: Double) {
        accumulator = operand
    }
    
    func getOperationType(of operation: String) -> OperationType {
        return operators[operation]!
    }
    
    func checkAndProbablyPerformPendingOperation() {
        if let pendingBinaryOperation = pendingBinaryOperation {
            accumulator = pendingBinaryOperation.perform(with: accumulator!)
        }
    }
    
    private func radiansToDegree(_ radians: Double) -> Double {
        return radians * Double.pi / 180
    }
    
    private class func generateRandomDoubleValue () -> Double {
        let randomUInt32 = arc4random()
        let countOfDigitsInRandomNumber = Double(String(randomUInt32).count)
        let randomDouble = Double(randomUInt32) * pow(10, -countOfDigitsInRandomNumber)
        return randomDouble
    }
    
    private class func factorial (value: Double) -> Double {
        if value.remainder(dividingBy: 1) != 0.0 {
            return Double.nan
        }
        var factorial = 1
        for nextMultiplier in 1...Int(value) {
            factorial *= nextMultiplier
        }
        return Double(factorial)
    }
}
