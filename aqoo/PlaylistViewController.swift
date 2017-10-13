//
//  PlaylistViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class PlaylistViewController:   BaseViewController,
                                SPTAudioStreamingPlaybackDelegate,
                                SPTAudioStreamingDelegate,
                                UITableViewDataSource,
                                UITableViewDelegate {
    
    //
    // MARK: Class Special Constants
    //
    
    let spotifyClient = SpotifyClient.sharedInstance
    
    var _playlistsInCloud = [SPTPartialPlaylist]()
    var _playlistsInDb = [StreamPlayList]()
    var _playListHashesInDb = [String]()
    var _playListHashesInCloud = [String]()
    var _defaultStreamingProvider: StreamProvider?
    
    @IBOutlet weak var btnRefreshPlaylist: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUITableView()
        setupUIEventObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        handlePlaylistCloudRefresh()
    }
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return _playlistsInDb.count
    }
    
    func tableView(
       _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let list = _playlistsInDb[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "playListItem", for: indexPath) 
        
        cell.detailTextLabel?.text = list.name
        cell.textLabel?.text = list.name
        
        return cell
        
    }
    
    @IBAction func btnRefreshPlaylistAction(_ sender: Any) {
        
        handlePlaylistCloudRefresh()
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        // closeSession()
        
        _ = self.navigationController!.popViewController(animated: true)
    }
}
