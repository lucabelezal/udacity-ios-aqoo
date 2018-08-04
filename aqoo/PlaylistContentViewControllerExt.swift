//
//  PlaylistContentViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import MaterialComponents.MaterialProgressView

extension PlaylistContentViewController {
 
    func setupUIBase() {
        
        var _noCoverImageAvailable : Bool = true
        var _usedCoverImageCacheKey : String?
        var _usedCoverImageURL : URL?
        
        // try to bound cover image using user generated image (cover override)
        if  playListInDb!.coverImagePathOverride != nil {
            if  let _image = getImageByFileName(playListInDb!.coverImagePathOverride!) {
                trackControlView.imageViewPlaylistCover.image = _image
            }   else {
                handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted cover image for your playlist")
            }
            
        }   else {
            
            // try to bound cover image using largestImageURL
            if  playListInDb!.largestImageURL != nil {
               _usedCoverImageURL = URL(string: playListInDb!.largestImageURL!)
               _usedCoverImageCacheKey = String(format: "d0::%@", _usedCoverImageURL!.absoluteString).md5()
               _noCoverImageAvailable = false
            }
            
            // no large image found? try smallestImageURL instead
            if  playListInDb!.smallestImageURL != nil && _noCoverImageAvailable == true {
               _usedCoverImageURL = URL(string: playListInDb!.smallestImageURL!)
               _usedCoverImageCacheKey = String(format: "d0::%@", _usedCoverImageURL!.absoluteString).md5()
               _noCoverImageAvailable = false
            }
            
            // call cover image handler for primary coverImageView
            if _noCoverImageAvailable == false {
                handleCoverImageByCache(
                    trackControlView.imageViewPlaylistCover,
                    _usedCoverImageURL!,
                    _usedCoverImageCacheKey!,
                    [ .transition(.fade(0.1875)) ]
                )
            }
        }
        
        // add some additional meta data for our current playlist trackView
        trackControlView.lblPlaylistName.text = playListInDb!.metaListInternalName
        trackControlView.lblPlaylistTrackCount.text = String(format: "%D", playListInDb!.trackCount)
        if  let playlistOverallPlaytime = playListInDb!.metaListOverallPlaytimeInSeconds as? Int32 {
            trackControlView.lblPlaylistOverallPlaytime.text = getSecondsAsHoursMinutesSecondsDigits(Int(playlistOverallPlaytime))
        }
        
        setupUIPlayModeControls()
    }
    
    func setupUIPlayModeControls() {
        
        toggleActiveMode( true )
        if  playListTracksInCloud?.count == 0 {
            toggleActiveMode( false )
        }
        
        trackControlView.btnPlayShuffleMode.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(PlaylistContentViewController.handlePlaylistPlayShuffleMode))
        )
        
        trackControlView.btnPlayNormalMode.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(PlaylistContentViewController.handlePlaylistPlayNormalMode))
        )
        
        trackControlView.btnPlayRepeatMode.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(PlaylistContentViewController.handlePlaylistPlayRepeatMode))
        )
    }
    
    func setupPlayerAuth() {
        
        if  spotifyClient.isSpotifyTokenValid() {
            localPlayer.initPlayer(authSession: spotifyClient.spfCurrentSession!)
        }   else {
            self.handleErrorAsDialogMessage(
                "Spotify Session Closed",
                "Oops! your spotify session is not valid anymore, please (re)login again ..."
            )
        }
    }
    
    func setupUITableView() {
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    @objc
    func handlePlaylistPlayShuffleMode(sender: UITapGestureRecognizer) {
        
        if (sender.state != .ended) { return }
        
        handlePlaylistPlayMode(playMode.PlayShuffle.rawValue)
    }
    
    @objc
    func handlePlaylistPlayNormalMode(sender: UITapGestureRecognizer) {
        
        if (sender.state != .ended) { return }
        
        handlePlaylistPlayMode(playMode.PlayNormal.rawValue)
    }
    
    @objc
    func handlePlaylistPlayRepeatMode(sender: UITapGestureRecognizer) {
        
        if (sender.state != .ended) { return }
        
        handlePlaylistPlayMode(playMode.PlayRepeatAll.rawValue)
    }
    
    func handlePlaylistPlayMode(
       _ usedPlayMode: Int16) {
        
        // reset (all) playMode controls
        trackControlView.mode = .clear
        // set current playMode for internal usage
        currentPlayMode = usedPlayMode
        
        switch currentPlayMode {
            
            case playMode.PlayNormal.rawValue:
                if  playListInDb!.currentPlayMode != playMode.PlayNormal.rawValue {
                    setPlaylistPlayMode( playMode.PlayNormal.rawValue )
                    trackControlView.mode = .playNormal
                    togglePlayMode( true )
                }   else {
                    setPlaylistPlayMode( playMode.Default.rawValue )
                    trackControlView.mode = .clear
                    togglePlayMode( false )
                };  break
            
     
            case playMode.PlayShuffle.rawValue:
                if  playListInDb!.currentPlayMode != playMode.PlayShuffle.rawValue {
                    setPlaylistPlayMode( playMode.PlayShuffle.rawValue )
                    trackControlView.mode = .playShuffle
                    togglePlayMode( true )
                }   else {
                    setPlaylistPlayMode( playMode.Default.rawValue )
                    trackControlView.mode = .clear
                    togglePlayMode( false )
                };  break
            
            case playMode.PlayRepeatAll.rawValue:
                if  playListInDb!.currentPlayMode != playMode.PlayRepeatAll.rawValue {
                    setPlaylistPlayMode( playMode.PlayRepeatAll.rawValue )
                    trackControlView.mode = .playLoop
                    togglePlayMode( true )
                }   else {
                    setPlaylistPlayMode( playMode.Default.rawValue )
                    trackControlView.mode = .clear
                    togglePlayMode( false )
                };  break
            
            default:
                
                trackControlView.mode = .clear
                togglePlayMode( false )
                break
        }
    }
    
    func setPlaylistPlayMode(
       _ usedPlayMode: Int16) {
        
        // reset playMode for all (spotify) playlists in cache
        localPlaylistControls.resetPlayModeOnAllPlaylists()
        // set new playMode to corrsponding playlist now
        localPlaylistControls.setPlayModeOnPlaylist( playListInDb!, usedPlayMode )
        // start playing tracks using -1 as init position for trackJumpToNext() call
        currentTrackPosition = -1
        if  trackJumpToNext() == true {
            trackStartPlaying( currentTrackPosition )
        }
    }
    
    func trackStopPlaying(
       _ number: Int) {

        if playListTracksInCloud == nil || number > playListTracksInCloud!.count { return }
        
        jumpToActiveTrackCellByTrackPosition( number )
        
        // update local persistance layer for tracks, set track to mode "isPlaying"
        localPlaylistControls.setTrackInPlayState( currentTrackPlaying!, false )
        
        // stop playback
        try! localPlayer.player?.setIsPlaying(false, callback: { (error) in
            self.handleAllTrackCellsPlayStateReset()
            if (error != nil) {
                self.handleErrorAsDialogMessage("Player Controls Error", "\(error?.localizedDescription)")
            }
        })
    }
    
    func trackStartPlaying(
       _ number: Int) {
        
        if playListTracksInCloud == nil || number >= playListTracksInCloud!.count { return }
        
        jumpToActiveTrackCellByTrackPosition( number )
        
        // fetch track from current playlist trackSet
        let track = playListTracksInCloud![number] as! StreamPlayListTracks
        // set active meta object of active (playing) track
        currentTrackPlaying = track
        // update local persistance layer for tracks, set track to mode "isPlaying"
        localPlaylistControls.setTrackInPlayState( track, true )
        // set active meta object, (re)evaluate current trackInterval
        currentTrackInterval = TimeInterval(currentTrackTimePosition)
        // start playback using spotify api call
        localPlayer.player?.playSpotifyURI(
            currentTrackPlaying!.trackURIInternal,
            startingWith: 0,
            startingWithPosition: currentTrackInterval!,
            callback: { (error) in
                if (error != nil) {
                    self.handleErrorAsDialogMessage("Player Controls Error", "\(error?.localizedDescription)")
                }
            }
        )
    }
    
    func trackJumpToNext() -> Bool {
        
        //
        // reset currentTrackTimePosition only if not called initially (first track) -
        // I'll use playTrack override directly after setPlaylistPlayMode starts
        //
        if  currentTrackPosition != -1 {
            currentTrackTimePosition = 0
        }
        
        switch currentPlayMode {
            
            case playMode.PlayNormal.rawValue:
                
                // last track in playlist? return false (mark this process as 'not available') ...
                if playlistFinished() == true { return false }
                // otherwise jump to next track in playlist
                currentTrackPosition += 1
                
                break
            
            case playMode.PlayShuffle.rawValue:
            
                if playListTracksShuffleKeyPosition == playListTracksShuffleKeys!.count { return false }
                
                currentTrackPosition = playListTracksShuffleKeys![playListTracksShuffleKeyPosition]
                playListTracksShuffleKeyPosition += 1
                
                break
            
            case playMode.PlayRepeatAll.rawValue:
        
                // last track in playlist? jump to first track again otherwise jump to next track in PL
                if  playlistFinished() == true {
                    currentTrackPosition  = 0
                }   else {
                    currentTrackPosition += 1
                }
            
                break
            
            default: return false
        }
        
        return true
    }
    
    func trackIsFinished() -> Bool {
        let _isFinished: Bool = currentTrackTimePosition == Int(currentTrackPlaying!.trackDuration)
        if  _isFinished == true && debugMode == true {
            print ("dbg [playlist/track] : \(currentTrackPlaying!.trackIdentifier!) finished, try to start next song ...\n")
        }
        
        return _isFinished
    }
    
    func playlistFinished() -> Bool {
        
        var _isFinished: Bool = false
        
        switch currentPlayMode {
            
            case playMode.PlayRepeatAll.rawValue:
                _isFinished = false
                break
            
            case playMode.PlayShuffle.rawValue:
                _isFinished = playListTracksShuffleKeyPosition == playListTracksShuffleKeys!.count
                break
            
            case playMode.PlayNormal.rawValue:
                _isFinished = currentTrackPosition == playListTracksInCloud!.count - 1
                break
        
            default: break
        }
        
        if  _isFinished == true && debugMode == true {
            print ("dbg [playlist/track] : \(playListInDb!.metaListHash) finished, no more songs available ...\n")
        }
        
        return _isFinished
    }
    
    func toggleActiveMode(
       _ active: Bool) {
        
        trackControlView.btnPlayRepeatMode.isEnabled = active
        trackControlView.btnPlayNormalMode.isEnabled = active
        trackControlView.btnPlayShuffleMode.isEnabled = active
        
        trackControlView.btnPlayRepeatMode.isUserInteractionEnabled = active
        trackControlView.btnPlayNormalMode.isUserInteractionEnabled = active
        trackControlView.btnPlayShuffleMode.isUserInteractionEnabled = active
    }

    func togglePlayMode (
       _ active: Bool) {
        
        if  _trackTimer != nil {
            _trackTimer.invalidate()
        }
        
        trackControlView.imageViewPlaylistIsPlayingIndicator.isHidden = !active
        trackControlView.state = .stopped
        
        if  active == true {
            
            // start playback meta timer
            _trackTimer = Timer.scheduledTimer(
                timeInterval : TimeInterval(1),
                target       : self,
                selector     : #selector(handleTrackTimerEvent),
                userInfo     : nil,
                repeats      : true
            );  trackControlView.state = .playing
            
        }   else {
        
            // stop playback using direct api call
            trackStopPlaying( currentTrackPosition )
        }
    }
    
    // weazL
    func getTableCellForTrackPosition(_ trackPosition: Int) {
        
        // 1st, scroll to position
        tableView.scrollToRow(at: IndexPath(row: trackPosition, section: 0), at: .top, animated: true)
        
        // 2nd, (majic) wait for table dispatchable loadOut and fetch corresponding cell
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            
            self.currentTrackCell = nil
            let _trackCell = self.tableView.cellForRow(at: IndexPath(row: trackPosition, section: 0)) as? PlaylistTracksTableCell
            if (_trackCell != nil) {
                self.currentTrackCell = _trackCell
            }
        }
    }
    
    func handleActiveTrackCellByTrackPosition(_ trackPosition: Int) {
        
        var trackIndexPath = IndexPath(row: trackPosition, section: 0)
        tableView.reloadRows(at: [trackIndexPath], with: .none)
    }
    
    func jumpToActiveTrackCellByTrackPosition(_ trackPosition: Int) {
     
        var trackIndexPath = IndexPath(row: trackPosition, section: 0)
        tableView.scrollToRow(at: trackIndexPath, at: .top, animated: true)
        // try to postfetch ballistic meta data from current active track cell (majic)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            
            self.currentTrackCell = nil
            let _trackCell = self.tableView.cellForRow(at: trackIndexPath) as? PlaylistTracksTableCell
            if (_trackCell != nil) {
                self.currentTrackCell = _trackCell
            }
        }
    }
    
    func handleAllTrackCellsPlayStateReset() {
        
        for trackCell in tableView.visibleCells as! [PlaylistTracksTableCell] {
            trackCell.state = .stopped
            trackCell.imageViewTrackIsPlayingIndicator.isHidden = true
            trackCell.imageViewTrackIsPlayingSymbol.isHidden = true
            trackCell.lblTrackPlaytime.textColor = UIColor(netHex: 0x80C9A4)
            
            // trackCell.lblTrackPlaytime.text = getSecondsAsMinutesSecondsDigits(Int(currentTrackPlaying!.trackDuration))
            trackCell.progressBar.progress = 0.0
        }
    }
    
    @objc
    func handleTrackTimerEvent() {
        
        // trace cell for this track
        handleActiveTrackCellByTrackPosition( currentTrackPosition )
        
        //  track still runnning? update track timeFrama position and progressBar
        if  trackIsFinished() == false {
            
            currentTrackTimePosition += 1
            currentTrackTimeProgress = (Float(currentTrackTimePosition) / Float(currentTrackPlaying!.trackDuration))
            currentTrackInterval = TimeInterval(currentTrackTimePosition)
            
            localPlaylistControls.setTrackTimePositionWhilePlaying( currentTrackPlaying!, currentTrackTimePosition )
        }
        
        if  trackIsFinished() == true {
            trackStopPlaying( currentTrackPosition )
            
            if  playlistFinished() == false {
                
                if  trackJumpToNext() == true {
                    trackStartPlaying( currentTrackPosition )
                }
                
            }   else {
                
               _trackTimer.invalidate()
                handlePlaylistCompleted()
            }
        }
    }
    
    func handlePlaylistCompleted() {
        
        handlePlaylistPlayMode( 0 )
        resetLocalPlayerMetaSettings()
        localPlaylistControls.resetPlayModeOnAllPlaylists()
    }
    
    func resetLocalPlayerMetaSettings() {

        playListTracksShuffleKeyPosition = 0
        playListTracksShuffleKeys = []
        currentPlayMode = 0
    }
    
    func resetLocalTrackStateStettings() {
        
        currentTrackTimePosition = 0
        currentTrackPlaying = nil
        currentTrackInterval = 0
        currentTrackPosition = 0
        
        currentTrackCell = nil
    }
    
    func loadMetaPlaylistTracksFromDb() {
        
        // load all tracks from db
        playListTracksInCloud = CoreStore.defaultStack.fetchAll(
             From<StreamPlayListTracks>()
                .where(\StreamPlayListTracks.playlist == playListInDb)
                .orderBy(.ascending(\StreamPlayListTracks.trackAddedAt))
        )
        
        // load playlist local cache from db (refresh)
        playListInDb = CoreStore.defaultStack.fetchOne(
            From<StreamPlayList>()
                .where(\StreamPlayList.metaListHash == playListInDb!.getMD5Identifier())
        )
        
        // init shuffled key stack for shuffle-play-mode
        if  playListTracksInCloud != nil {
            playListTracksShuffleKeys = getRandomUniqueNumberArray(
                forLowerBound: 0,
                andUpperBound: playListTracksInCloud!.count,
                andNumNumbers: playListTracksInCloud!.count
            )
        }
    }
}
