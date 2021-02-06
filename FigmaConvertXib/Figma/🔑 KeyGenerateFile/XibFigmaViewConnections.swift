//
//  File.swift
//  FigmaConvertXib
//
//  Created by Рустам Мотыгуллин on 18.08.2020.
//  Copyright © 2020 mrusta. All rights reserved.
//

import Foundation

extension FigmaNode {
    
    /// Label | ImageView
    
    enum XibCellPropertyType {
        case xib
        
        case initItem
        case initData
        case dataProperty
        case dataSet
        case cellProperty
        case cellSet
    }
    
    // MARK: - Connections Xib <-> Swift
    
    func propertyChildren(type: XibCellPropertyType, addedCount: Int = 0) -> (connections: [String], addedCount: Int)  {
        
        var connections: [String] = []
        var addedCount_ = addedCount
        
        if self.type == .component {
            
            let result = property(type: type, typeLabel: false, id: xibId, count: addedCount_)
            addedCount_ += 1
            connections.append(result)
            
        } else if !children.isEmpty,
            self.type != .component {
            
            for node: FigmaNode in self.children {
                
                if node.visible,
                    node.type != .vector,
                    node.type != .booleanOperation {
                    
                    
                    if let _ = node.xibSearch(fill: .image) {
                        
                        let result = property(type: type, typeLabel: false, id: node.xibId, count: addedCount_)
                        connections.append(result)
                        addedCount_ += 1
                    }
                    
                    if node.type == .text {
                        
                        let result = property(type: type, typeLabel: true, id: node.xibId, count: addedCount_)
                        connections.append(result)
                        addedCount_ += 1
                    }
                    
                    let result = node.propertyChildren(type: type, addedCount: addedCount_)
                    
                    connections += result.0
                    addedCount_ = result.1
                }
            }
        }
         
        return (connections, addedCount_)
    }
    
    
    // MARK: - Connections Property .swift

    func property(type: XibCellPropertyType, typeLabel: Bool, id: String, count: Int) -> String {
        
        let name_     : String = typeLabel ? "label"   : "imageView"
        let valueName_: String = typeLabel ? "text"    : "image"
        let classType_: String = typeLabel ? "UILabel" : "UIImageView"
        let valueType_: String = typeLabel ? "String"  : "UIImage"
        
        let  prName: String = (name_      + "\(count)")
        let valName: String = (valueName_ + "\(count)")
        
        var outlet: String = ""
        
        switch type {
        case .xib:
            
            outlet = "<outlet property=\"\(prName)\" destination=\"\(id)\" id=\"\(xibID())\"/>"
            
        case .initItem:
            
            outlet = "\(valName): \(valueType_)? = nil,"
            
        case .initData:
            
            outlet = "\(valName): \(valName),"

            // text,
            // image,
            
        case .dataProperty:

            outlet = "var \(valName): \(valueType_)?"
            
            // var text: String?
            // var image: UIImage?
        
        case .dataSet:
            
            outlet = "self.\(valName) = \(valName)"
            
            // self.text = text
            // self.image = image
            
        case .cellSet:
            
            outlet = "\(prName)?.\(valueName_) = data.\(valName) ?? \(prName)?.\(valueName_)"
            
            // titleLabel?.text = data.title
            // subtitleLabel?.image = data.subtitle
            
        case .cellProperty:
            
            outlet = "@IBOutlet private weak var \(prName): \(classType_)?"
            
        }
        
        
        return outlet
        
        // connections.append(outlet)
    }
    
}
