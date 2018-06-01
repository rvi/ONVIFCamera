//
//  ViewController.swift
//  StreamTutorial
//
//  Created by Rémy Virin on 08/01/2018.
//  Copyright © 2018 RemyVirin. All rights reserved.
//

import UIKit
import ONVIFCamera

/**
 This view controller allows the user to enter the IP address, login and password of his ONVIF camera.
 Then it tests the connection by sending a `getInformations` request.
 Finally it retrieve the media profiles and the stream URI.
 */
class ViewController: UIViewController, UITextFieldDelegate {
    
    // UI elements
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var playButton: UIButton!
    // The Onvif camera from the pod
    var camera: ONVIFCamera = ONVIFCamera(with: "XX", credential: nil) {
        didSet {
            playButton.setTitle("Connect to camera", for: .normal)
            infoLabel.text = ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infoLabel.text = "No 🎥 connected"
    }
    
    func cameraIsConnected() {
        playButton.setTitle("Getting profiles...", for: .normal)
        let info = "Connected to: \n" + camera.manufacturer! + "\n" + camera.model!
        infoLabel.text = info
        updateProfiles()
    }
    
    private func getDeviceInformation() {
        camera.getCameraInformation(callback: { (camera) in
            self.cameraIsConnected()
        }, error: { (reason) in
            
            let text = NSAttributedString(string: reason, attributes: [NSAttributedStringKey.foregroundColor : UIColor.red])
            self.infoLabel.attributedText = text
        })
    }
    
    /// Once the camera credential and IP are valid, we retrieve the profiles and the streamURI
    private func updateProfiles() {
        if camera.state == .Connected {
            camera.getProfiles(profiles: { (profiles) -> () in
                let title = self.camera.state == .HasProfiles ? "Getting streaming URI..." : "No Profiles... 😢"
                self.playButton.setTitle(title, for: .normal)
                
                if let pr0files = profiles, pr0files.count > 0 {
                    // Retrieve the streamURI with the latest profile
                    self.camera.getStreamURI(with: pr0files.first!.token, uri: { (uri) in
                        
                        print("URI: \(uri ?? "No URI Provided")")
                        
                        if let _ = uri {
                        self.playButton.setTitle("Play 🎥", for: .normal)
                        }
                    })
                }
            })
        }
    }
    
    //********************************************************************************
    //MARK: - Actions
    
    /** The `play` handle several actions depending on the camera state:
     * camera `NotConnected`: Create an instance of `ONVIFCamera` with the IP address and credentials typed by the user,
     or with the ones from the `Config` struct if all the textfields are empty. Then we call `getInformations` on the camera.
     * camera `ReadyToPlay`: We open a new view controller, `StreamViewController` with the stream URI to play.
     */
    @IBAction func playButtonTapped(_ sender: Any) {
        
        if camera.state == .NotConnected {
            if textFieldAreEmpty {
                camera = ONVIFCamera(with: Config.ipAddress,
                                     credential: (login: Config.login, password: Config.password),
                                     soapLicenseKey: Config.soapLicenseKey)
            } else {
                camera = ONVIFCamera(with: ipTextField.text!, credential: (login: loginTextField.text!,
                                                                           password: passwordTextField.text!),
                                     soapLicenseKey: Config.soapLicenseKey)
            }
                      
            camera.getServices { (error) in
                
                if error == nil {
                    self.getDeviceInformation()
                }
            }
            
        } else if camera.state == .ReadyToPlay {
            performSegue(withIdentifier: "showStreamVC", sender: camera.streamURI)
        }
    }
    
    /// Util method to check if all the textfields are empty
    private var textFieldAreEmpty: Bool {
        return ipTextField.text!.count == 0 &&
            loginTextField.text!.count == 0 &&
            passwordTextField.text!.count == 0
    }
    
    //********************************************************************************
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        camera = ONVIFCamera(with: ipTextField.text!, credential: (login: loginTextField.text!,
                                                                   password: passwordTextField.text!),
                             soapLicenseKey: Config.soapLicenseKey)
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Remove the old camera as we're changing one of the textfields
        if camera.state == .Connected {
            camera.state = .NotConnected
        }
        return true
    }
    
    //********************************************************************************
    //MARK: - Navigation
    /// Pass the URI if the next view controller if `StreamViewController`
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let uri = sender as? String, let controller = segue.destination as? StreamViewController {
            controller.URI = uri
        }
    }
}

