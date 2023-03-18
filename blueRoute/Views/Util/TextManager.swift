//
//  TextManager.swift
//  blueRoute
//
//  Created by Sandro Giannini on 3/17/23.
//

import Foundation

/// Object to managed text input as an observable object with count
///
class TextManager: ObservableObject {
    @Published var counted = 0;
    @Published var text = "" {
        didSet {
            counted = text.count
            if text.count > self.maxLenght {
                text = String(text.prefix(self.maxLenght))
            }
        }
    }
    
    var maxLenght: Int;
    
    init(maxLenght: Int) {
        self.maxLenght = maxLenght
    }
    
    
    
    func reset() {
        text = "";
    }
}
