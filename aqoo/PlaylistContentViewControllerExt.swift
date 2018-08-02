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
import BGTableViewRowActionWithImage
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
        
        switch usedPlayMode {
            
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
                if  self.debugMode == true {
                    print ("dbg [playlist] : playMode [\(usedPlayMode)] unknown <ignored>")
                };  break
        }
    }
    
    func setPlaylistPlayMode(
       _ usedPlayMode: Int16) {
        
        // reset playMode for all (spotify) playlists in cache
        localPlaylistControls.resetPlayModeOnAllPlaylists()
        // set new playMode to corrsponding playlist now
        localPlaylistControls.setPlayModeOnPlaylist( playListInDb!, usedPlayMode )
        // play track
        trackStartPlaying( currentTrackPosition )
    }
    
    func trackStopPlaying(
       _ number: Int) {
        
        if playListTracksInCloud == nil || number > playListTracksInCloud!.count { return }
        
        // fetch track from current playlist trackSet
        let track = playListTracksInCloud![number] as! StreamPlayListTracks
        
        // update local persistance layer for tracks, set track to mode "isPlaying"
        localPlaylistControls.setTrackInPlayState( track, false )
        
        // handle corresponding cell UI
        handleTrackPlayingCellUI( number, isPlaying: false )
        
        // stop playback
        try! localPlayer.player?.setIsPlaying(false, callback: { (error) in
            if (error != nil) {
                self.handleErrorAsDialogMessage("Player Controls Error", "\(error?.localizedDescription)")
            }
        })
    }
    
    func trackStartPlaying(
       _ number: Int) {
        
        if playListTracksInCloud == nil || number > playListTracksInCloud!.count { return }
       
        // fetch track from current playlist trackSet
        let track = playListTracksInCloud![number] as! StreamPlayListTracks
        
        // update local persistance layer for tracks, set track to mode "isPlaying"
        localPlaylistControls.setTrackInPlayState( track, true )
        
        currentTrackPlaying  = track
        // (re)evaluate trackInterval
        currentTrackInterval = TimeInterval(currentTrackTimePosition)
        
        // handle corresponding cell UI
        handleTrackPlayingCellUI( number, isPlaying: true )
        
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
        
        if  active == false {
            
            trackStopPlaying( currentTrackPosition )
            
        }   else {
        
            // start playback meta timer
            _trackTimer = Timer.scheduledTimer(
                timeInterval : TimeInterval(1),
                target       : self,
                selector     : #selector(handleTrackTimerEvent),
                userInfo     : nil,
                repeats      : true
            );  trackControlView.state = .playing
        }
    }
    
    @objc
    func handleTrackTimerEvent() {
        
        currentTrackTimePosition += 1
        currentTrackInterval = TimeInterval(currentTrackTimePosition)

        localPlaylistControls.setTrackTimePositionWhilePlaying( currentTrackPlaying!, currentTrackTimePosition )
        
        guard let _trackCell = tableView.cellForRow(at: IndexPath(row: currentTrackPosition, section: 0)) as? PlaylistTracksTableCell else {
            return
        }
        
        var _ctp: Float = Float(currentTrackTimePosition)
        var _ctd: Float = Float(currentTrackPlaying!.trackDuration)
        var _progress: Float = (_ctp / _ctd)
        
        _trackCell.progressBar.setProgress(_progress, animated: true)
    }
    
    func handleTrackPlayingCellUI(_ number: Int, isPlaying: Bool) {
        
        guard let _trackCell = tableView.cellForRow(at: IndexPath(row: number, section: 0)) as? PlaylistTracksTableCell else {
            return
        }
        
        _trackCell.imageViewTrackIsPlayingIndicator.isHidden = !isPlaying
        _trackCell.progressBar.isHidden = true
        _trackCell.state = .stopped
        
        if  isPlaying == true {
           _trackCell.state = .playing
           _trackCell.progressBar.isHidden = false
           _trackCell.progressBar.progress = 0
           _trackCell.progressBar.progressTintColor = UIColor(netHex: 0x1DB954)
           _trackCell.progressBar.trackTintColor = UIColor.clear
        }
    }
    
    func resetLocalPlayerMetaSettings() {

        currentTrackPlaying = nil
        currentTrackTimePosition = 0
        currentTrackPosition = 0
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
    
    func loadMetaPlaylistTracksFromDb() {
        
        playListTracksInCloud = CoreStore.defaultStack.fetchAll(
            From<StreamPlayListTracks>().where((\StreamPlayListTracks.playlist == playListInDb))
        )
    }
}
