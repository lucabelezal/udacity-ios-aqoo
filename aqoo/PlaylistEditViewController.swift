//
//  PlaylistEditViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 05.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//


import UIKit
import Spotify
import CoreStore
import Kingfisher
import FoldingCell
import BGTableViewRowActionWithImage

class PlaylistEditViewController: BaseViewController, UITextViewDelegate {

    @IBOutlet weak var navItemEditViewTitle: UINavigationItem!
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet weak var inpPlaylistTitle: UITextField!
    @IBOutlet weak var inpPlaylistDescription: UITextView!
    @IBOutlet weak var switchMyFavoriteList: UISwitch!
    @IBOutlet weak var switchAutoListLikedFromRadio: UISwitch!
    @IBOutlet weak var switchAutoListStarVoted: UISwitch!
    @IBOutlet weak var switchUseCoverOrigin: UISwitch!
    @IBOutlet weak var switchUseCoverOverride: UISwitch!
    @IBOutlet weak var imgViewCoverOrigin: UIImageView!
    @IBOutlet weak var imgViewCoverOverride: UIImageView!
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    var inputsListenForChanges = [Any]()
    
    enum tagFor: Int {
        case PlaylistTitle = 1
        case PlaylistDescription = 2
        case PlaylistIsHot = 3
        case PlaylistIsLikedFromRadio = 4
        case PlaylistIsVotedByStars = 5
        case PlaylistIsUseCoverOrigin = 6
        case PlaylistIsUseCoverOverride = 7
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

    func textViewDidChange(_ sender: UITextView) {
        
        checkInputElementsForChanges()
    }
    
    @IBAction func inpPlaylistTitleDidChanged(_ sender: UITextField) {

        checkInputElementsForChanges()
    }
    
    @IBAction func switchMyFavoriteListChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isHot)
    }
    
    @IBAction func switchAutoListLikedFromRadioChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistRadioSelected)
    }
    
    @IBAction func switchAutoListStarVotedChanged(_ sender: UISwitch) {
       
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistVotedByStar)
    }
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {

        var _playListTitle: String = inpPlaylistTitle.text!
        var _playListDescription: String = inpPlaylistDescription.text!
        var _playListIsHot: Bool = switchMyFavoriteList.isOn
        var _playlistIsRadioSelected: Bool = switchAutoListLikedFromRadio.isOn
        var _playlistIsStarVoted: Bool = switchAutoListStarVoted.isOn
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>()
                        .where(\.metaListHash == self.playListInDb!.metaListHash)
                )
                
                if  playlistToUpdate != nil {

                    playlistToUpdate!.metaListInternalName = _playListTitle
                    playlistToUpdate!.metaListInternalDescription = _playListDescription
                    
                    playlistToUpdate!.isHot = _playListIsHot
                    playlistToUpdate!.isPlaylistRadioSelected = _playlistIsRadioSelected
                    playlistToUpdate!.isPlaylistVotedByStar = _playlistIsStarVoted
                    
                    playlistToUpdate!.updatedAt = Date()
                    playlistToUpdate!.metaNumberOfUpdates += 1
                    playlistToUpdate!.metaPreviouslyUpdatedManually = true
                }
            },
            completion: { _ in

                self.handleSaveChangesButton( false )
                self.btnExitEditViewAction( self )
            }
        )
    }
    
    @IBAction func btnExitEditViewAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
}
