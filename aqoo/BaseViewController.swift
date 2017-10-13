//
//  BaseViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class BaseViewController: UIViewController {
    
    //
    // MARK: Base Constants
    //
    
    let debugMode: Bool = true
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let segueIdentPlayListPage = "showAllUserPlaylists"
    
    let _sampleSong: String = "spotify:track:3rkge8kur9i26zpByFKvBu"
    
    let metaDateTimeFormat = "dd.MM.Y hh:mm"
    
    //
    // MARK: Base Methods
    //
    
    func _handleErrorAsDialogMessage(_ errorTitle: String, _ errorMessage: String) {
        
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}
