//
//  ViewController.swift
//  youtubePlayer
//
//  Created by 玉越敬典 on 2015/12/23.
//  Copyright © 2015年 玉越敬典. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let api = SwiftubeApi(url: "https://www.youtube.com/watch?v=8P4a2YWCzT8")
        api.fromUrl("https://www.youtube.com/watch?v=8P4a2YWCzT8")
    }
}

