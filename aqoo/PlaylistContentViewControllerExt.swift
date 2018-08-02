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
        
        if  playListTracksInCloud?.count == 0 {
            trackControlView.btnPlayRepeatMode.isEnabled = false
            trackControlView.btnPlayNormalMode.isEnabled = false
            trackControlView.btnPlayShuffleMode.isEnabled = false
            trackControlView.btnPlayShuffleMode.isUserInteractionEnabled = false
            trackControlView.btnPlayNormalMode.isUserInteractionEnabled = false
            trackControlView.btnPlayRepeatMode.isUserInteractionEnabled = false
        }

        // add some additional meta data for our current playlist trackView
        trackControlView.lblPlaylistName.text = playListInDb!.metaListInternalName
        trackControlView.lblPlaylistTrackCount.text = String(format: "%D", playListInDb!.trackCount)
        if  let playlistOverallPlaytime = playListInDb!.metaListOverallPlaytimeInSeconds as? Int32 {
            trackControlView.lblPlaylistOverallPlaytime.text = getSecondsAsHoursMinutesSecondsDigits(Int(playlistOverallPlaytime))
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
    
    func handlePlaylistPlayMode(_ usedPlayMode: Int16) {
        
        // reset (all) playMode controls
        trackControlView.mode = .clear
        
        switch usedPlayMode {
            
            case playMode.PlayNormal.rawValue:
                if  playListInDb!.currentPlayMode != playMode.PlayNormal.rawValue {
                    setPlaylistPlayMode( playMode.PlayNormal.rawValue )
                    trackControlView.mode = .playNormal
                    togglePlayModeIcon( true )
                }   else {
                    setPlaylistPlayMode( playMode.Default.rawValue )
                    trackControlView.mode = .clear
                    togglePlayModeIcon( false )
                };  break
            
     
            case playMode.PlayShuffle.rawValue:
                if  playListInDb!.currentPlayMode != playMode.PlayShuffle.rawValue {
                    setPlaylistPlayMode( playMode.PlayShuffle.rawValue )
                    trackControlView.mode = .playShuffle
                    togglePlayModeIcon( true )
                }   else {
                    setPlaylistPlayMode( playMode.Default.rawValue )
                    trackControlView.mode = .clear
                    togglePlayModeIcon( false )
                };  break
            
            case playMode.PlayRepeatAll.rawValue:
                if  playListInDb!.currentPlayMode != playMode.PlayRepeatAll.rawValue {
                    setPlaylistPlayMode( playMode.PlayRepeatAll.rawValue )
                    trackControlView.mode = .playLoop
                    togglePlayModeIcon( true )
                }   else {
                    setPlaylistPlayMode( playMode.Default.rawValue )
                    trackControlView.mode = .clear
                    togglePlayModeIcon( false )
                };  break
            
            default:
                
                trackControlView.mode = .clear
                togglePlayModeIcon( false )
                if  self.debugMode == true {
                    print ("dbg [playlist] : playMode [\(usedPlayMode)] unknown")
                };  break
        }
    }
    
    func setPlaylistPlayMode(_ usedPlayMode: Int16) {
        
        // reset playMode for all (spotify) playlists in cache
        localPlaylistControls.resetPlayModeOnAllPlaylists()
        // set new playMode to corrsponding playlist now
        localPlaylistControls.setPlayModeOnPlaylist( playListInDb!, usedPlayMode )
        
        // dummy code ... just a play a fucking uri
        for (index, trackRaw) in playListTracksInCloud!.enumerated() {
            
            if  let track = trackRaw as? StreamPlayListTracks {
                
                localPlayer.player?.playSpotifyURI(
                    track.trackURIInternal,
                    startingWith: 0,
                    startingWithPosition: 0,
                    callback: { (error) in
                        if (error != nil) {
                            print (error)
                        }   else {
                            print("playing : \(track.trackName)")
                        }
                    }
                )
                
                // just play index 0 (= track_1)
                return
                
            }   else {
                handleErrorAsDialogMessage("Playlist Format Error", "your playlist isn't valid anymore")
                return
            }
            
            
        }
    }
    
    func togglePlayModeIcon(
       _ active: Bool) {
        
        trackControlView.imageViewPlaylistIsPlayingIndicator.isHidden = !active
        trackControlView.state = .stopped
        if  active == true {
            trackControlView.state = .playing
        }
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
