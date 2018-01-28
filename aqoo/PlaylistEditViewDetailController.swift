//
//  PlaylistEditViewDetailController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 22.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import FoldingCell
import BGTableViewRowActionWithImage
import fluid_slider

class PlaylistEditViewDetailController: BaseViewController, UITextViewDelegate {
    
    @IBOutlet var switchPlaylistIsStarVoted: UISwitch!
    @IBOutlet var switchPlaylistIsRadioLiked: UISwitch!
    @IBOutlet var switchPlaylistIsHidden: UISwitch!
    @IBOutlet var inpPlaylistDescription: UITextView!
    @IBOutlet var navItemEditViewTitle: UINavigationItem!
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    var inputsListenForChanges = [Any]()
    var delegate: PlaylistEditViewDetailDelegate?
 
    enum tagFor: Int {
        case PlaylistDescription = 1
        case PlaylistIsStarVoted = 2
        case PlaylistIsRadioLiked = 3
        case PlaylistIsHidden = 4
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIGeneral()
        setupUINavigation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        setupUIInputFields()
        setupUISwitchButtons()
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    // not working
    func textViewDidChange(_ sender: UITextView) {
     
        print ("textView change detected ...")
        
        checkInputElementsForChanges()
    }
    
    @IBAction func switchAutoListStarVotedChanged(_ sender: UISwitch) {
        
        // only one if this internal spotify flags are allowed!
        switchPlaylistIsRadioLiked.isOn = !switchPlaylistIsStarVoted.isOn
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistVotedByStar)
    }
    
    @IBAction func switchAutoListLikedFromRadioChanged(_ sender: UISwitch) {
        
        // only one if this internal spotify flags are allowed!
        switchPlaylistIsStarVoted.isOn = !switchPlaylistIsRadioLiked.isOn
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistRadioSelected)
    }
    
    @IBAction func switchActionHidePlaylistFromAllViewsChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistHidden)
    }
    
    @IBAction func btnCancelEditViewAction(_ sender: Any) {
        
        // delegate information about current playlist entity state to playlistEditView
        if let delegate = self.delegate {
            
            playListInDb!.isPlaylistHidden = switchPlaylistIsHidden.isOn
            playListInDb!.isPlaylistRadioSelected = switchPlaylistIsRadioLiked.isOn
            playListInDb!.isPlaylistVotedByStar = switchPlaylistIsStarVoted.isOn
            playListInDb!.metaListInternalDescription = inpPlaylistDescription.text
            
            delegate.promoteToChanged( playListChanged )
            delegate.promoteChangedPlaylistObject( playListInDb! )
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnResetPlaylistStatistics(_ sender: UIButton) {
        
        print ("btnResetPlaylistStatistics:action")
    }
    
    @IBAction func btnResetPlaylistToSPFDefaults(_ sender: UIButton) {
        
        print ("btnResetPlaylistToSPFDefaults:action")
    }
}
