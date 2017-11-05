//  Created by Юрий Сорокин on 02/11/2017.
//  Copyright © 2017 ITMO University. All rights reserved.
//

import Foundation

class Stack {

    enum Symbol{
        case digit(String)
        case operation(String)
    }
    
    func getIndexValue(at index: Int) -> String {
        let symbol = peek(offsetBy: index)
        switch symbol {
        case .digit(let value):
            return value
        case .operation(let value):
            return value
        }
    }
    
    private var currentSymbol = -1
//    {
//        didSet{
//            if currentSymbol >= 0 {
//                print("""
//                -----------------
//                \(history[0...currentSymbol])
//                """)
//            }
//        }
//    }
    
    var isEmpty : Bool {
        return currentSymbol<0
    }
    
    var isFull: Bool {
        return currentSymbol.distance(to: history.count) == 1
    }
    
    func recognize (value: String) -> Symbol{
        if Double(value) != nil {
            return .digit(value)
        }
        return .operation(value)
    }
    
    private var history: [Symbol] = []
//    { didSet {
//            print("""
//            -----------------------
//            \(history)
//            """)
//        }
//    }
    
    func push(symbol: String){
        if shouldWeReallyPush(value: symbol){
            history.append(recognize(value: symbol))
            currentSymbol+=1
        }
    }
    
    func pop() -> Symbol {
        currentSymbol-=1
        return history[currentSymbol+1]
    }
    
    func peek(offsetBy: Int) -> Symbol {
        return history[currentSymbol-offsetBy]
    }
    
    func reset() -> Bool {
        var countOfDeletedElements = 0
        while(history.count-1>currentSymbol){
            history.removeLast()
            countOfDeletedElements+=1
        }
        if countOfDeletedElements != 0 {
            return true
        }
        return false
    }
    
    func goForward() -> Symbol {
        if currentSymbol<history.count {
            currentSymbol+=1
        }
        return history[currentSymbol]
    }
    
    private func shouldWeReallyPush (value: String) -> Bool{
        if !isEmpty, value == getIndexValue(at: 0) { //same value
            return false
        }
        if isEmpty, Double(value) == nil { //operation cannot be first
            return false
        }
        if value == "=", currentSymbol>1, getIndexValue(at: 1) == "=" { //equal pressed twice
            return false
        }
        return true
    }
    
    func putResultOnTop(){
        let model = Model(stack: self)
        for symbol in history {
            switch symbol{
            case .digit(let value):
                model.setOperand(Double(value)!)
            case .operation(let value):
                model.doOperation(value)
            }
        }
        model.doOperation("=")
        history.removeLast()
        history.append(.digit(converDoubleToString(model.result!)))
    }
}
