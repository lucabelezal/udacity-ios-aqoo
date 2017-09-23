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
        
        appDelegate.spfAuth.renewSession(appDelegate.spfCurrentSession) { error, session in
            
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
        
        performSegue(withIdentifier: segueIdentPlayListPage, sender: self)
    }
    
    func getAuthViewController(withURL url: URL) -> UIViewController {
        
        let webView = WebViewController(url: url)
            webView.delegate = self
        
        return UINavigationController(rootViewController: webView)
    }
    
    func updateAfterCancelLogin() {
        
        self.presentedViewController?.dismiss(animated: true, completion: { _ in self.setupUILoginControls() })
    }
    
    func updateAfterSuccessLogin(_ notification: NSNotification?) {
        
        if appDelegate.isSpotifyTokenValid() {
            
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
        
        self.presentedViewController?.dismiss(animated: true, completion: { _ in self.setupUILoginControls() })
    }
    
    func setupUILoginControls() {
        
        let _tokenIsValid = appDelegate.isSpotifyTokenValid()
        
        btnSpotifyLogin.isEnabled =  _tokenIsValid
        btnSpotifyLogin.isEnabled = !_tokenIsValid
        
        lblSpotifySessionStatus.text = "NOT CONNECTED"
        imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusLocked_v1")
        appDelegate.spfIsLoggedIn = false
        
        if _tokenIsValid == true {
            appDelegate.spfIsLoggedIn = true
            lblSpotifySessionStatus.text = "CONNECTED"
            imgSpotifyStatus.image = UIImage(named: "imgUISpotifyStatusConnected_v1")
        }
    }
    
    func webViewControllerDidFinish(_ controller: WebViewController) { }

}