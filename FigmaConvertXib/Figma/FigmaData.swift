//
//  FigmaData.swift
//  FigmaConvertXib
//
//  Created by Рустам Мотыгуллин on 24.06.2020.
//  Copyright © 2020 mrusta. All rights reserved.
//

import UIKit

class FigmaData {
    
    static let current = FigmaData()
    
    //MARK: Request
    
    typealias CompletionJSON = (_ data: Data, _ json: [String:Any]?) -> Void
    typealias CompletionBool = (_ value: Bool) -> Void
    typealias CompletionString = (_ value: String?) -> Void
    typealias Completion = () -> Void
    
    public enum documentId: String {
        case RuStAm4iK = "PLRDJ59Baio6xjpmylVt3T"
        case Short = "Zy47vycoawoNCIcEg8ygH5"
        case All = "9KadDT1iy1EX0wJMY7qhSY"
        case Coffee = "M0q8R4TA8Lb4TB5lJSIq98"
    }
    
    let token = "44169-d6b5edd3-c479-475f-bee5-d0525b239ad0"
    
    let apiURL = "https://api.figma.com/v1/files/"
    let apiURLComponent = "https://api.figma.com/v1/images/"
    
    public enum RequestType {
        case Files
        case Images
    }
    
    //MARK: - Result
    
    var response: FigmaResponse?
    var imagesURLs: [String: String]?
    
    
    //MARK: - 📁 Paths
    
    /// path: /FigmaConvertXib/FigmaConvertXib/Figma/Xib
    func pathXib() -> String {
        
        let pathFile: String = #file
        let arrayFilesName: [String] = #file.split(separator: "/").map({String($0)})
        let resultPathFinal: String = pathFile.replacingOccurrences(of: arrayFilesName.last!, with: "Xib")
        
//        print(pathFile)
//        print(arrayFilesName)
//        print(resultPathFinal)
        
        return resultPathFinal
    }
    
    /// path: /FigmaConvertXib/FigmaConvertXib/Figma/Xib/images.xcassets
    func pathXibImages() -> String {
        
        let pathFile: String = #file
        let arrayFilesName: [String] = #file.split(separator: "/").map({String($0)})
        let resultPathFinal: String = pathFile.replacingOccurrences(of: arrayFilesName.last!, with: "Xib/images.xcassets")
        
        return resultPathFinal
    }
    
    func pathDocument() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return documentDirectory[0]
    }
    
    //MARK: - 📁 Paths 🗑 Clear Temp
    
    func clearTempFolder() {
        let fileManager = FileManager.default
        let tempFolderPath = pathDocument()//NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                let resultPath = "\(tempFolderPath)/\(filePath)"
                try fileManager.removeItem(atPath: resultPath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    //MARK: - 📄 Save Local File.xib
    
    class func save(text: String, toDirectory directory: String, withFileName fileName: String) {
        
        func append(toPath path: String, withPathComponent pathComponent: String) -> String? {
            if var pathURL = URL(string: path) {
                pathURL.appendPathComponent(pathComponent)
                return pathURL.absoluteString
            }
            return nil
        }
        
        guard let filePath = append(toPath: directory, withPathComponent: fileName) else { return }
        
        do {
            try text.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch { print("Error", error); return }
    }
    
    //MARK: - 🏞 Image Download
    
    class func downloadImage(url: URL, completion: ((_ image: UIImage) -> Void)? = nil) {
           
           func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
               URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
           }
           
           getData(from: url) { data, response, error in
               guard let data = data, error == nil else { return }
               if let image = UIImage(data: data) {
                   DispatchQueue.main.async() {
                       completion?(image)
                   }
               }
           }
       }
    
    
    //MARK: - 🏞 Image Save Local Xib/
    
    class func saveImage(image: UIImage, imageRef: String) {
        
        let data = image.pngData()!
        
        let p = FigmaData.current.pathXibImages()
        let a = "file://\(p)/"
        
        guard let urlPathA = URL(string: a) else { return }
        let urlPath = urlPathA.appendingPathComponent("\(imageRef).png")
        
        do {
            try data.write(to: urlPath)
            print(" 🏞 \(urlPath.absoluteString)")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //MARK: - Request Figma
    
    func requestFiles(projectKey: String, completion: FigmaData.Completion?) {
        
        response = nil
        imagesURLs = nil
        
        request(key: projectKey, type: .Files, compJson: { [weak self] (data, json: [String:Any]?) in
            guard let json = json else { return }
            guard let _self = self else { return }
            
            _self.response = FigmaResponse(json)
            
            guard (_self.imagesURLs != nil) else { return }
            completion?()
            
        })
        
        request(key: projectKey, type: .Images, compJson: { [weak self] (data, json: [String:Any]?) in
            guard let json = json else { return }
            guard let _self = self else { return }
            
            guard let meta = json["meta"] as? [String: Any] else { return }
            guard let images = meta["images"] as? [String: String] else { return }
            _self.imagesURLs = images
                
            guard (_self.response != nil) else { return }
            completion?()
        })
        
    }
    
    func requestComponent(key: String, nodeId: String, compJson: FigmaData.CompletionJSON? = nil) {
        
        let srtURL = "\(apiURLComponent)\(key)/?ids=\(nodeId)&format=png"
        
        guard let url = URL(string: srtURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["X-Figma-Token" : token]
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                    guard let currentData: Data = data, error == nil else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: currentData, options: .allowFragments) as? [String : Any] {
                    DispatchQueue.main.async {
                        compJson?(currentData, json)
                    }
                }
            } catch {
                print(error)
            }
        }).resume()
    }
    
    func request(key: String, type: RequestType, compJson: FigmaData.CompletionJSON? = nil) {
        
        let typeURL = (type == .Images ? "/images" : "")
        
//        var srtURL = "\(apiURL)\(FigmaData.documentId.RuStAm4iK.rawValue)\(typeURL)"
        
        let srtURL = "\(apiURL)\(key)\(typeURL)"
        
        guard let url = URL(string: srtURL) else {
            
            compJson?(Data(), [ "err" : "url" ])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["X-Figma-Token" : token]
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let currentData: Data = data, error == nil else { return }
            
            compJson?(currentData, nil)
            do {
                if let json = try JSONSerialization.jsonObject(with: currentData, options: .allowFragments) as? [String : Any] {
                    DispatchQueue.main.async {
                        compJson?(currentData, json)
                    }
                }
            } catch {
                print(error)
            }
        }).resume()
        
    }
    
    
    func checkProjectRequest(key: String, complectionExists: FigmaData.CompletionString? = nil) {
        
        request(key: key, type: .Files, compJson: { (data, json: [String:Any]?) in
            
            guard let json = json else { return }
            if ((json["err"] as? String) != nil) {
                complectionExists?(nil)
                return
            }
            
            guard let name = json["name"] as? String else { return }
            
            complectionExists?(name)
        })
    }
}