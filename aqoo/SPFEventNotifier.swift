//
//  SPFEventNotifier.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 14.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation

struct SPFEventNotifier {
    
    var notifyPlaylistLoadCompleted = "__cloud_playlist_load_completed"
    var notifyPlaylistCacheLoadCompleted = "__cache_playlist_load_completed"
    var notifySessionRequestSuccess = "__cloud_session_request_completed"
    var notifySessionRequestCanceled = "__cloud_session_request_canceled"
}
