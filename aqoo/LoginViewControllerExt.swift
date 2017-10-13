//
//  LoginViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 20.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

extension LoginViewController {

    func renewTokenAndShowLandingPage() {
        
        appDelegate.spfAuth.renewSession(spotifyClient.spfCurrentSession) { error, session in
            
            SPTAuth.defaultInstance().session = session
            if error != nil {
                self.lblSpotifySessionStatus.text = "REFRESH TOKEN FAIL"
                print("_dbg: error renewing session: \(error!.localizedDescription)")
                
                return
            }
            
            self.showLandingPage()
        }
    }
    
    func showLandingPage() {
        
        //
        // lets start with users playlistView
        //
        
        print ("showLandingPage")
        
        performSegue(withIdentifier: segueIdentPlayListPage, sender: self)
    }
    
    func getAuthViewController(withURL url: URL) -> UIViewController {
        
        let webView = WebViewController(url: url)
            webView.delegate = self
        
        return UINavigationController(rootViewController: webView)
    }
    
    @objc func updateAfterCancelLogin() {
        
        self.presentedViewController?.dismiss(animated: true, completion: { self.setupUILoginControls() })
    }
    
    @objc func updateAfterSuccessLogin(_ notification: NSNotification?) {
        
        if spotifyClient.isSpotifyTokenValid() {
            
            //
            // application entry point during development
            //
            
            showLandingPage()
            
        } else {
            
           _handleErrorAsDialogMessage(
                "Spotify Login Fail!",
                "Oops! I'm unable to verify valid authentication for your spotify account!"
            )
        }
        
        self.presentedViewController?.dismiss(animated: true, completion: { self.setupUILoginControls() })
    }
    
    func setupUILoginControls() {
        
        let _tokenIsValid = spotifyClient.isSpotifyTokenValid()
        
        btnSpotifyLogin.isEnabled =  _tokenIsValid
        btnSpotifyLogin.isEnabled = !_tokenIsValid
        
        lblSpotifySessionStatus.text = "NOT CONNECTED"
        imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusLocked_v1")
        spotifyClient.spfIsLoggedIn = false
        
        if _tokenIsValid == true {
            spotifyClient.spfIsLoggedIn = true
            lblSpotifySessionStatus.text = "CONNECTED"
            imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusConnected_v1")
        }
    }
    
    func webViewControllerDidFinish(_ controller: WebViewController) { }

}
