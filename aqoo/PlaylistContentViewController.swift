//
//  PlaylistContentViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import BGTableViewRowActionWithImage

class PlaylistContentViewController: BaseViewController,
                                     UITableViewDataSource,
                                     UITableViewDelegate {
    
    let localPlaylistControls = SPFClientPlaylistControls.sharedInstance
    let localPlayer = SPFClientPlayer.sharedInstance
    let kBaseCellHeight: CGFloat = 72.0
    
    let currentTrack = PlaylistTrack.sharedInstance
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListTracksInCloud: [StreamPlayListTracks]?
    var playListTracksShuffleKeys: [Int]?
    var playListTracksShuffleKeyPosition: Int = 0
    var playListPlayMode: Int16 = 0
    
    var _trackTimer: Timer!
    
    @IBOutlet weak var trackControlView: PlaylistTracksControlView!
    @IBOutlet weak var tableView: UITableView!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUITableView()
        setupPlayerAuth()
        
        loadMetaPlaylistTracksFromDb()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        if  _trackTimer != nil {
            _trackTimer.invalidate()
        }
    }
    
    //
    // MARK: Class Table Delegates
    //
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return playListTracksInCloud!.count
    }
    
    func tableView(
       _ tableView: UITableView,
         heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return kBaseCellHeight
    }
    
    func tableView(
       _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let playlistTrackCacheData = playListTracksInCloud![indexPath.row] as StreamPlayListTracks
        let playlistCell = tableView.dequeueReusableCell(
            withIdentifier: "playListContentItem",
            for: indexPath) as! PlaylistTracksTableCell

        var _ctd: Float = Float(TimeInterval(playlistTrackCacheData.trackDuration))
        
        var playlistCoverView: UIImageView! = playlistCell.imageViewAlbumCover
        var usedCoverImageCacheKey: String?
        var usedCoverImageURL: URL?
        
        playlistCell.state = .stopped
        
        playlistCell.lblAlbumName.text = playlistTrackCacheData.albumName
        playlistCell.lblTrackName.text = playlistTrackCacheData.trackName
        playlistCell.lblTrackPlayIndex.textColor = UIColor(netHex: 0x010101)
        playlistCell.lblTrackPlayIndex.text = String(format: "%D", (indexPath.row + 1))
        playlistCell.progressBar.progressTintColor = UIColor(netHex: 0x1DB954)
        playlistCell.progressBar.trackTintColor = UIColor.clear
        playlistCell.progressBar.isHidden = false
        
        playlistCell.imageViewTrackIsPlayingIndicator.isHidden = true
        playlistCell.imageViewTrackIsPlayingSymbol.isHidden = true
        playlistCell.lblTrackPlaytime.textColor = UIColor(netHex: 0x80C9A4)
        playlistCell.lblTrackPlaytime.text = getSecondsAsMinutesSecondsDigits(Int(_ctd))
        playlistCell.lblTrackPlaytimeRemaining.textColor = UIColor(netHex: 0x1DB954)
        playlistCell.lblTrackPlaytimeRemaining.text = playlistCell.lblTrackPlaytime.text
        playlistCell.progressBar.progress = 0.0
    
        // try to bind album cover to track, use avatar (v1) if nothing found
        if  playlistTrackCacheData.albumCoverLargestImageURL != nil {
            usedCoverImageURL = URL(string: playlistTrackCacheData.albumCoverLargestImageURL!)
            usedCoverImageCacheKey = String(format: "a0::%@", playlistTrackCacheData.albumCoverLargestImageURL!).md5()
        }   else if playlistTrackCacheData.albumCoverSmallestImageURL != nil {
            usedCoverImageURL = URL(string: playlistTrackCacheData.albumCoverSmallestImageURL!)
            usedCoverImageCacheKey = String(format: "a1::%@", playlistTrackCacheData.albumCoverSmallestImageURL!).md5()
        }
        
        // check explicit state of current track and activate icon if needed/required
        playlistCell.imageViewTrackIsExplicit.isHidden = true
        if  playlistTrackCacheData.trackExplicit == true {
            playlistCell.imageViewTrackIsExplicit.isHidden = false
        }
        
        // *** playlistCell.imageViewAlbumCover.image = UIImage.makeLetterAvatar(withUsername: playlistTrackCacheData.trackName)
        if  usedCoverImageURL != nil {
            handleCoverImageByCache(
                playlistCoverView,
                usedCoverImageURL!,
                usedCoverImageCacheKey!,
                [.transition(.fade(0.1875))]
            )
        }
        
        //
        // dynamic meta data payload
        //
        
        if  playlistTrackCacheData.metaTrackIsPlaying == true {
            
            playlistCell.state = .playing
            playlistCell.imageViewTrackIsPlayingIndicator.isHidden = false
            playlistCell.imageViewTrackIsPlayingSymbol.isHidden = false
            playlistCell.lblTrackPlaytime.isHidden = true
            playlistCell.lblTrackPlaytimeRemaining.isHidden = false
            playlistCell.lblTrackPlaytimeRemaining.text = getSecondsAsMinutesSecondsDigits(Int(_ctd) - currentTrack.timePosition)
            playlistCell.progressBar.setProgress(currentTrack.timeProgress, animated: false)
            
        }   else if playListPlayMode == 0 || playlistTrackCacheData.metaTrackIsPlaying == false {
            
            playlistCell.state = .stopped
            playlistCell.imageViewTrackIsPlayingIndicator.isHidden = true
            playlistCell.imageViewTrackIsPlayingSymbol.isHidden = true
            playlistCell.lblTrackPlaytime.text = getSecondsAsMinutesSecondsDigits(Int(_ctd))
            playlistCell.lblTrackPlaytime.isHidden = false
            playlistCell.lblTrackPlaytimeRemaining.text = playlistCell.lblTrackPlaytime.text
            playlistCell.lblTrackPlaytimeRemaining.isHidden = true
            playlistCell.progressBar.progress = 0.0
        }
        
        return playlistCell
    }
    
    func tableView(
       _ tableView: UITableView,
         editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
        let trackCell = tableView.cellForRow(at: indexPath) as! PlaylistTracksTableCell
        
        let tblActionTrackControl = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: UIColor(netHex: 0x131313),
            image: UIImage(named: "icnSetPlayMini_1"), // icnSetPauseMini_1
            forCellHeight: UInt(self.kBaseCellHeight - 10)) { (action, index) in
                
                self.trackPlaybackByCell( index!.row )
        }
        
        let tblActionTrackEdit = BGTableViewRowActionWithImage.rowAction(
            with: UITableViewRowActionStyle.default,
            title: nil,
            backgroundColor: UIColor(netHex: 0x131313),
            image: UIImage(named: "icnSettings_v2"),
            forCellHeight: UInt(self.kBaseCellHeight - 10)) { (action, index) in
            
                self.trackEditByCell( index!.row )
        }
        
        return [ tblActionTrackControl!, tblActionTrackEdit! ]
    }
    
    func trackPlaybackByCell(
       _ trackNumber: Int) {
        
        currentTrack.index = trackNumber
        
        // check current "file-of-action" (play || stop)
        if  currentTrack.isPlayingInManualMode == false {
            // play selected track
            handlePlaylistPlayMode ( playMode.PlayNormal.rawValue )
        }   else {
            // stop selected track
            handlePlaylistPlayMode ( playMode.Stopped.rawValue )
        };  currentTrack.isPlayingInManualMode = !currentTrack.isPlayingInManualMode
        
        if  debugMode == true {
            print ("dbg [playlist/track/control] : action for track #[\(trackNumber)], playing=\(currentTrack.isPlayingInManualMode)")
        }
    }
    
    func trackEditByCell(
       _ trackNumber: Int) {
        
        if  debugMode == true {
            print ("dbg [playlist/track/edit] : action for track #[\(trackNumber)]")
        }
    }
    
    func resetPlayer() {
        
        // reset (all) playMode controls
        trackControlView.mode = .clear
        // reset playMode for all (spotify) playlists in cache
        localPlaylistControls.resetPlayModeOnAllPlaylists()
        // reset playMode/timeFrame-Meta-Information for all (spotify) playlistTracks in cache
        localPlaylistControls.resetPlayModeOnAllPlaylistTracks()
        // clear local playlist playback meta
        resetLocalPlayerMetaSettings()
        // clear local track playback meta
        resetLocalTrackStateStettings()
        // logout from player
        localPlayer.player?.logout()
    }
    
    @IBAction func btnClosePlayistContentView(_ sender: Any) {
        
        resetPlayer()
        
        dismiss(animated: true, completion: nil)
    }
}
