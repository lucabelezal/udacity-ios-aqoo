//
//  PlaylistEditViewThirdPage.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.06.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher

class PlaylistEditViewThirdPage: BasePlaylistEditViewController {
    
    var playlistUpdateDetected: Bool = false
    
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet weak var textFieldPlaylistDetails: UITextView!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUIPlaylistDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    //
    // MARK: Class Setup UI/UX Functions
    //
    
    func setupUIBase() {
        
        // playlist details will always be updateable
        btnSavePlaylistChanges.isEnabled = true
    }
    
    func setupUIPlaylistDetails() {
        
        textFieldPlaylistDetails.text = playListInDb!.metaListInternalDescription
    }
    
    func handlePlaylistMetaUpdate() {
        
        var _playlistDetails: String = textFieldPlaylistDetails.text
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                
                // find persisted playlist object from local cache (db)
                guard let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>().where(\.metaListHash == self.playListInDb!.metaListHash))
                    as? StreamPlayList else {
                        self.handleErrorAsDialogMessage(
                            "Cache Error", "unable to fetch playlist from local cache"
                        );   return
                }
                
                playlistToUpdate.updatedAt = Date()
                playlistToUpdate.metaNumberOfUpdates += 1
                playlistToUpdate.metaPreviouslyUpdatedManually = true
                playlistToUpdate.metaListInternalDescription = _playlistDetails
                
                self.playListInDb = playlistToUpdate
            },
            completion: { (result) -> Void in
                switch result {
                    
                case .failure(let error):
                    
                    self.handleBtnSavePlaylistChangesState( active: false )
                    self.handleErrorAsDialogMessage(
                        "Cache Error", "unable to update playlist local cache"
                    )
                    
                case .success(let userInfo):
                    
                    // delegate information about current playlist state to parentView
                    self.handleBtnSavePlaylistChangesState( active: true )
                    if  let delegate = self.delegate {
                        delegate.onPlaylistChanged( self.playListInDb! )
                    }
                }
            }
        )
    }
    
    func handleBtnSavePlaylistChangesState(active: Bool) {
        
        btnSavePlaylistChanges.isEnabled = active
    }
    
    //
    // MARK: Class IABaction Methods
    //
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {
        
        handlePlaylistMetaUpdate()
        dismiss(animated: true, completion: nil)
    }
}
