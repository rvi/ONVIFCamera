//
//  StreamViewController.swift
//  StreamTutorial
//
//  Created by Rémy Virin on 15/01/2018.
//  Copyright © 2018 RemyVirin. All rights reserved.
//

import UIKit

/**
 This controller plays the live stream through VLC of the URI passed by the previous view controller.
 */
class StreamViewController: UIViewController {
    
    var URI: String?
    @IBOutlet weak var movieView: UIView!
    var mediaPlayer = VLCMediaPlayer()
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Associate the movieView to the VLC media player
        mediaPlayer.drawable = self.movieView
        
        // Create `VLCMedia` with the URI retrieved from the camera
        if let URI = URI ,let url = URL(string: URI) {
            let media = VLCMedia(url: url)
            mediaPlayer.media = media
        }
        
        mediaPlayer.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mediaPlayer.stop()
    }
}
