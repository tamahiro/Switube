//
//  swiftube.swift
//  youtubePlayer
//
//  Created by 玉越敬典 on 2015/12/25.
//  Copyright © 2015年 玉越敬典. All rights reserved.
//

import Foundation
import JavaScriptCore

public class SwiftubeApi {
    var filename: String = ""
    var title: String = ""
    var videoURL: String = ""
    var jsCache: String = ""
    var videos: [String] = []
    
    static let QUALITY_PROFILES = [
        // flash
        5: ("flv", "240p", "Sorenson H.263", "N/A", "0.25", "MP3", "64"),
        
        // 3gp
        17: ("3gp", "144p", "MPEG-4 Visual", "Simple", "0.05", "AAC", "24"),
        36: ("3gp", "240p", "MPEG-4 Visual", "Simple", "0.17", "AAC", "38"),
        
        // webm
        43: ("webm", "360p", "VP8", "N/A", "0.5", "Vorbis", "128"),
        100: ("webm", "360p", "VP8", "3D", "N/A", "Vorbis", "128"),
        
        // mpeg4
        18: ("mp4", "360p", "H.264", "Baseline", "0.5", "AAC", "96"),
        22: ("mp4", "720p", "H.264", "High", "2-2.9", "AAC", "192"),
        82: ("mp4", "360p", "H.264", "3D", "0.5", "AAC", "96"),
        83: ("mp4", "240p", "H.264", "3D", "0.5", "AAC", "96"),
        84: ("mp4", "720p", "H.264", "3D", "2-2.9", "AAC", "152"),
        85: ("mp4", "1080p", "H.264", "3D", "2-2.9", "AAC", "152"),
    ]
    
    init(url: String = "") {
        self.videoURL = url
    }
    
    func videoId() {
        
    }
    
    func getVideos() {
        
    }
    
    func getFilename() -> String {
        if self.filename == "" {
            self.filename = SwitubeUtils.safeFilename(self.title)
        }
        return self.filename
    }
    
    func fromUrl(url: String){
        self.videoURL = url
        
        self.filename = ""
        self.videos = []
        
        let jsonData : JSON? = self.getVideoData()
        
        if jsonData == nil {
            return
        }
        self.title = jsonData!["args"]["title"].string!

        let jsUrl = "https:" + jsonData!["assets"]["js"].string!


        let streamMap = jsonData!["args"]["stream_map"]
        let videoUrls = streamMap["url"]
        
        for (idx, url) in videoUrls {
            var videoURL = url.string!
            //print("idx: \(idx) url: \(videoURL)")
            let (itag, qualityProfile) = self.getQualityProfileFromUrl(videoURL)
            
            if url.string!.rangeOfString("signature=") == nil {
                let signature = self.getCipher(streamMap["s"][Int(idx)!].string!, url: jsUrl)
                videoURL = videoURL + "&signature=" + signature
            }
            //print(videoURL)
            self.addVideo(videoURL, filename: self.getFilename(), qualityProfile: qualityProfile)
        }
        
    }
    
    func get(extention: String? = nil, resolution: String? = nil, profile: String? = nil) {
        
    }
    
    func filter(){
        
    }
    
    func getVideoData() -> JSON? {
        let url:NSURL = NSURL(string: videoURL)!
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        let req = NSURLRequest(URL: url)
        var jsonObject: JSON? = nil
        let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
        let task = session.dataTaskWithRequest(req, completionHandler: {(data, resp, err) in
            //let restrictionPattern = "og:restrictions:age"
            jsonObject = self.getJsonData(data)
            var encodedStreamMap = ""
            if jsonObject != nil {
               encodedStreamMap = jsonObject!["args"]["url_encoded_fmt_stream_map"].string!
               jsonObject!["args"]["stream_map"] = self.parseStreamMap(encodedStreamMap)
            }
            dispatch_semaphore_signal(semaphore);
        })
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        if jsonObject != nil {
            return jsonObject!
        } else {
            return nil
        }
    }
    
    private func parseStreamMap(blob: String) -> JSON{
        var dct = [String: [String]]()
        let videos = blob.componentsSeparatedByString(",").map { $0.componentsSeparatedByString("&") }
        //print("\(videos)")
        for video in videos {
            for kv in video {
                let key = kv.componentsSeparatedByString("=")[0]
                let value = kv.componentsSeparatedByString("=")[1]
                let decodedString = value.stringByRemovingPercentEncoding;
                if dct[key] != nil {
                  dct[key]!.append(decodedString!)
                } else {
                  dct[key] = [decodedString!]
                }
            }
        }
        return JSON(dct)
    }
    
    private func getJsonData(data: NSData?) -> JSON?{
        var html = ""
        if data != nil {
           html =  String(data:data!, encoding:NSUTF8StringEncoding)!
        } else {
            return nil
        }
        
        let jsonStartPattern = "ytplayer.config = "
        let range:Range<String.Index> = html.rangeOfString(jsonStartPattern)!
        let patternIdx: Int = html.startIndex.distanceTo(range.startIndex)
        let start = patternIdx + 18
        html = (html as NSString).substringFromIndex(start)
        let jsonOffset: Int = getJsonOffset(html)
        
        return JSON(data: (html as NSString).substringToIndex(jsonOffset).dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    private func getJsonOffset(html: String) ->Int{
        var unmatchedBracketsNum = 0
        let index = 1
        var plusIndex = 0
        for (idx, char) in Array(html.characters).enumerate(){
            plusIndex = idx
            if char == "{" {
                unmatchedBracketsNum += 1
            } else if char == "}" {
                unmatchedBracketsNum -= 1
                if unmatchedBracketsNum == 0 {
                    break
                }
            }
        }
        if unmatchedBracketsNum != 0 {
            // TODO raise Error
        }
        return index + plusIndex
    }
    
    private func getCipher(signature: String, url: String) -> String{
        let regexp = Regexp("\\.sig\\|\\|([a-zA-Z0-9$]+)\\(")
        if self.jsCache == "" {
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: config)
            let req = NSURLRequest(URL: NSURL(string: url)!)
            var jsString: String? = nil
            let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
            let task = session.dataTaskWithRequest(req, completionHandler: {(data, resp, err) in
                jsString = NSString(data: data!, encoding: NSUTF8StringEncoding)! as String
                dispatch_semaphore_signal(semaphore);
            })
            task.resume()
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            self.jsCache = jsString!
        }
        let matches = regexp.matches(self.jsCache)
        var function = "gr"
        if matches != nil {
          //TODO  function = next(g for g in matches.groups() if g is not None)
        }
        let regexpForJsFunction = re.compile("(?x)(?:function\\s+gr|[{;,]gr\\s*=\\s*function|var\\s+gr\\s*=\\s*function)\\s* \\(([^)]*)\\)\\s*\\{([^}]+)\\}")
        let ctx = JSContext()
        print(regexpForJsFunction.search(self.jsCache)!.group())
        let jsi = SwiftubeJSInterpreter(code: self.jsCache)
        let initialFunction = jsi.extractFunction(function)
        
        return ""
    }
    
    private func getQualityProfileFromUrl(url: String) ->(Int, (String, String, String, String, String, String, String)){
        let regexp = Regexp("itag=([0-9]+)")
        var itag = regexp.matches(url)
        var itagNum: Int? = nil
        var qualityProfile: (String, String, String, String, String, String, String)? = nil
        if itag?.count == 1 {
            let itagNumString: String = itag![0].stringByReplacingOccurrencesOfString("itag=", withString: "")
            itagNum = Int(itagNumString)!
            qualityProfile = SwiftubeApi.QUALITY_PROFILES[itagNum!]
        }
        return (itagNum!.self, qualityProfile!.self)
    }
    
    private func addVideo(url: String, filename: String, qualityProfile: (String, String, String, String, String, String, String)){
        
    }
}

class Regexp {
    let internalRegexp: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        self.internalRegexp = try! NSRegularExpression( pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive)
    }
    
    func isMatch(input: String) -> Bool {
        let matches = self.internalRegexp.matchesInString( input, options: [], range:NSMakeRange(0, input.characters.count) )
        return matches.count > 0
    }
    
    func matches(input: String) -> [String]? {
        if self.isMatch(input) {
            let matches = self.internalRegexp.matchesInString( input, options: [], range:NSMakeRange(0, input.characters.count) )
            var results: [String] = []
            for i in 0 ..< matches.count {
                results.append( (input as NSString).substringWithRange(matches[i].range) )
            }
            return results
        }
        return nil
    }
}

