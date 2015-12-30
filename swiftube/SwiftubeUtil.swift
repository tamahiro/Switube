//
//  SwiftubeUtil.swift
//  swiftube
//
//  Created by 玉越敬典 on 2015/12/27.
//  Copyright © 2015年 玉越敬典. All rights reserved.
//

import Foundation

class SwitubeUtils {
    static func safeFilename(text: String, max_length: Int = 200) -> String {
        var replaceText = text
        replaceText = replaceText.stringByReplacingOccurrencesOfString("_", withString: "")
        replaceText = replaceText.stringByReplacingOccurrencesOfString(":", withString: "-")
        
        let ntfs:[String] = ([Int])(0...31).map{String($0)}
        let paranoid: Array<String> = ["\"", "#", "$", "%", "\'", "*", ",", ".", "/", ":",
            ";", "<", ">", "?", "\\", "^", "|", "~", "\\\\"]
        let filename = replaceText.stringByReplacingOccurrencesOfString((ntfs + paranoid).joinWithSeparator("|"), withString: "")
        return truncate(filename)
    }
    
    static func truncate(filename: String, max_length: Int = 200) -> String{
        return filename.componentsSeparatedByString(" ")[0]
    }
}
