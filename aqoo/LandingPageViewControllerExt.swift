//
//  LandingPageViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 20.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

extension LandingPageViewController {
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        
        print ("\nplayback disabled ...\n")
        
        return
        
        /*
        
        _player?.playSpotifyURI(sampleSong, startingWith: 0, startingWithPosition: 0, callback: {
            
            error in
            
            if (error == nil) {
                print ("\nplaying => \(self._sampleSong)\n")
            }   else {
                print ("_dbg: error while playing sample track \(self._sampleSong)")
            }
        })*/
    }
}
