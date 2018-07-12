//
//  PlaylistEditViewFirstPage.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.06.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import WSTagsField

class PlaylistEditViewFirstPage: BasePlaylistEditViewController,
                                 UITextFieldDelegate {
    
    //
    // MARK: Class LowLevel Variables
    //
    
    var noCoverImageAvailable: Bool = true
    var noCoverOverrideImageAvailable: Bool = true
    var playlistUpdateDetected: Bool = false
    
    fileprivate let playlistTagsField = WSTagsField()
    
    @IBOutlet weak var imgPlaylistCoverBig: UIImageView!
    @IBOutlet weak var inpPlaylistName: UITextField!
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet fileprivate weak var viewPlaylistTags: UIView!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUICoverImages()
        setupUIPlaylistTags()
        
        loadMetaPlaylistFromDb()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated); UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        subscribeToKeyboardNotifications()
        playlistTagsField.beginEditing()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        unSubscribeToKeyboardNotifications()
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        playlistTagsField.frame = viewPlaylistTags.bounds
    }
    
    // set orientation to portrait(fix) in this editView
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        
        return UIInterfaceOrientationMask.portrait
    }
    
    // disable orientation switch in this editView
    override var shouldAutorotate: Bool {
        
        return false
    }
    
    //
    // MARK: Class Function Delegate Overloads
    //
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == playlistTagsField {
            
           return true
        }
        
        view.endEditing(true)
        
        return false
    }
    
    //
    // MARK: Class Setup UI/UX Functions
    //
    
    func setupUIBase() {
        
        btnSavePlaylistChanges.isEnabled = false
        inpPlaylistName.delegate = self
        imgPlaylistCoverBig.becomeFirstResponder()
    }
    
    func setupUIPlaylistTags() {
        
        viewPlaylistTags.frame = viewPlaylistTags.bounds
        viewPlaylistTags.addSubview(playlistTagsField)
        
        playlistTagsField.cornerRadius = 3.0
        playlistTagsField.spaceBetweenLines = 10
        playlistTagsField.spaceBetweenTags = 10
        playlistTagsField.numberOfLines = 4
        
        playlistTagsField.layoutMargins = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        playlistTagsField.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        playlistTagsField.backgroundColor = UIColor(netHex: 0x1ED761)
        playlistTagsField.tintColor = UIColor(netHex: 0x1ED761)
        playlistTagsField.textColor = .black
        playlistTagsField.fieldTextColor = .white
        playlistTagsField.selectedColor = .white
        playlistTagsField.selectedTextColor = .black
        
        playlistTagsField.placeholder = "Enter a tag"
        playlistTagsField.isDelimiterVisible = false
        playlistTagsField.placeholderColor = .white
        playlistTagsField.placeholderAlwaysVisible = true
        playlistTagsField.backgroundColor = .clear
        
        playlistTagsField.acceptTagOption = .space
        playlistTagsField.returnKeyType = .next
        playlistTagsField.textDelegate = self

        handlePlaylistTagEvents()
    }
    
    func setupUICoverImages() {
        
        var _playListCoverURL: String?
        
        // evaluate the "perfect" cover for our detailView
        if (playListInDb!.largestImageURL != nil) {
           _playListCoverURL = playListInDb!.largestImageURL!
            noCoverImageAvailable = false
        }   else if (playListInDb!.smallestImageURL != nil) {
           _playListCoverURL = playListInDb!.smallestImageURL!
            noCoverImageAvailable = false
        }
        
        // cover image url available - using kf processing technics and render one
        if  noCoverImageAvailable == false {
            imgPlaylistCoverBig.kf.setImage(
                with: URL(string: _playListCoverURL!),
                placeholder: UIImage(named: _sysDefaultCoverImage),
                options: [
                    .transition(.fade(0.2)),
                    .processor(ResizingImageProcessor(referenceSize: _sysPlaylistCoverDetailImageSize))
                ]
            )
        }
        
        if  playListInDb!.coverImagePathOverride != nil {
            noCoverOverrideImageAvailable = false
            
            if  let _image = getImageByFileName(playListInDb!.coverImagePathOverride!) {
                imgPlaylistCoverBig.alpha = _sysPlaylistCoverOriginInActiveAlpha
            }   else {
                handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted image for your playlist")
            }
        }
    }
    
    //
    // MARK: Class Setup Data/Meta Functions
    //
    
    func loadMetaPlaylistFromDb() {
        
        // load playlistName
        inpPlaylistName.text = playListInDb!.metaListInternalName
        
        // fetch all available tags for this playlist and load them to our tagView
        if  let _playListTagsInCache = CoreStore.defaultStack.fetchAll(
            From<StreamPlayListTags>().where(
                (\StreamPlayListTags.playlist == playListInDb!))
            ) {
            
            for _tag in _playListTagsInCache {
                self.playlistTagsField.addTag(_tag.playlistTag)
            }
        }
    }
    
    func handlePlaylistTagEvents() {
        
        playlistTagsField.onDidAddTag = { _, tag in
            self.btnSavePlaylistChanges.isEnabled = true
            self.handlePlaylistTagInput( tag.text.lowercased(), add: true )
        }
        
        playlistTagsField.onDidRemoveTag = { _, tag in
            self.btnSavePlaylistChanges.isEnabled = true
            self.handlePlaylistTagInput( tag.text.lowercased(), add: false )
        }
    }
    
    func handlePlaylistMetaUpdate() {
        
        var _playListTitle: String = inpPlaylistName.text!
        
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
                    
                playlistToUpdate.metaListInternalName = _playListTitle
                playlistToUpdate.updatedAt = Date()
                playlistToUpdate.metaNumberOfUpdates += 1
                playlistToUpdate.metaPreviouslyUpdatedManually = true
                
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
    
    func handlePlaylistTagInput(_ tag: String, add: Bool) {
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                
                // find persisted playlist object from local cache (db)
                guard let playlistInContext = transaction.fetchOne(
                      From<StreamPlayList>().where(
                        \.metaListHash == self.playListInDb!.metaListHash
                      )) as? StreamPlayList else {
                        self.handleErrorAsDialogMessage("Cache Error", "unable to fetch playlist from local cache")
                    
                        return
                }
                
                // try to evaluate current tag in right playlist context
                var playlistTagToUpdate = transaction.fetchOne(
                    From<StreamPlayListTags>()
                        .where((\StreamPlayListTags.playlistTag == tag) &&
                            (\StreamPlayListTags.playlist == self.playListInDb!)
                    )
                )
                
                //  add tag to StreamPlayListTags cache/db table
                if  add == true {
                    playlistTagToUpdate = transaction.create(Into<StreamPlayListTags>()) as StreamPlayListTags
                    playlistTagToUpdate!.playlistTag = tag
                    playlistTagToUpdate!.createdAt = Date()
                    playlistTagToUpdate!.updatedAt = Date()
                    playlistTagToUpdate!.playlist = playlistInContext
                    
                    self.handleBtnSavePlaylistChangesState( active: true )
                    if self.debugMode == true { print ("TAG [\(tag)] ADDED") }
                }
                
                //  remove tag from StreamPlayListTags cache/db table
                if  add == false {
                    transaction.delete(playlistTagToUpdate)
                    
                    self.playlistTagsField.removeTag(tag)
                    self.handleBtnSavePlaylistChangesState( active: true )
                    if self.debugMode == true { print ("TAG [\(tag)] REMOVED") }
                }
            },
            completion: { (result) -> Void in
                switch result {
                    
                case .failure(let error):
                    self.handleBtnSavePlaylistChangesState( active: false )
                    self.handleErrorAsDialogMessage(
                        "Cache Error", "unable to update playlist tag local cache"
                    )
                
                case .success(let userInfo):
                    if  self.debugMode == true {
                        print ("dbg [db] : TAG [\(tag)] loaded")
                    }
                }
            }
        )
    }
    
    func handleBtnSavePlaylistChangesState(active: Bool) {
        
        btnSavePlaylistChanges.isEnabled = active
        playlistUpdateDetected = active
    }
    
    func subscribeToKeyboardNotifications() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PlaylistEditViewFirstPage.keyboardWillAppear),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PlaylistEditViewFirstPage.keyboardWillDisappear),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
    }
    
    func unSubscribeToKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name.UIKeyboardWillShow, object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name.UIKeyboardWillHide, object: nil
        )
    }
    
    @objc
    func keyboardWillDisappear(notification: NSNotification) {
        
        view.frame.origin.y = 0
    }
    
    @objc
    func keyboardWillAppear(notification: NSNotification) {

        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height {
           view.frame.origin.y =  keyboardSize * -1
        }
        
        /*view.setNeedsLayout()
        view.layoutIfNeeded()
        view.superview!.setNeedsLayout()
        view.superview!.layoutIfNeeded()*/
    }
    
    //
    // MARK: Class IABaction Methods
    //
    
    @IBAction func inpPlaylistNameChanged(_ sender: Any) {
        
        handleBtnSavePlaylistChangesState( active: true )
    }

    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {
        
        handlePlaylistMetaUpdate()
        dismiss(animated: true, completion: nil)
    }
}

