//
//  ViewController.swift
//  StreamTutorial
//
//  Created by Rémy Virin on 08/01/2018.
//  Copyright © 2018 RemyVirin. All rights reserved.
//

import UIKit
import ONVIFCamera

class ViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var playButton: UIButton!
    
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
    
    // "No camera connected"
    
    func cameraIsConnected() {
        playButton.setTitle("Getting profiles...", for: .normal)
        let info = "Connected to: \n" + camera.manufacturer! + "\n" + camera.model!
        infoLabel.text = info
        
        updateProfiles()
    }
    
    
    func updateProfiles() {
        if camera.state == .Connected {
            camera.getProfiles(profiles: { (profiles) -> () in
                let title = self.camera.state == .HasProfiles ? "Getting streaming URI..." : "No Profiles... 😢"
                self.playButton.setTitle(title, for: .normal)
                
                if profiles.count > 0 {
                    self.camera.getStreamURI(with: profiles.last!.token, uri: { (uri) in
                        print("URI: \(uri)")
                        self.playButton.setTitle("Play 🎥", for: .normal)
                    })
                }
            })
        }
    }
    
    //********************************************************************************
    //MARK: - Actions
    
    @IBAction func playButtonTapped(_ sender: Any) {
        
        if camera.state == .NotConnected {
            if textFieldAreEmpty {
                camera = ONVIFCamera(with: "60.191.94.122:8086", credential: (login: "admin", password: "admin321"))
            } else {
                camera = ONVIFCamera(with: ipTextField.text!, credential: (login: loginTextField.text!,
                                                                           password: passwordTextField.text!))
            }
            
            camera.getCameraInformation(callback: { (camera) in
                self.cameraIsConnected()
            }, error: { (reason) in
                
                let text = NSAttributedString(string: reason, attributes: [NSAttributedStringKey.foregroundColor : UIColor.red])
                self.infoLabel.attributedText = text
            })
        } else if camera.state == .ReadyToPlay {
            performSegue(withIdentifier: "showStreamVC", sender: camera.streamURI)
        }
    }
    
    private var textFieldAreEmpty: Bool {
        return ipTextField.text!.count == 0 &&
            loginTextField.text!.count == 0 &&
            passwordTextField.text!.count == 0
    }
    
    //********************************************************************************
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        camera = ONVIFCamera(with: ipTextField.text!, credential: (login: loginTextField.text!,
                                                                   password: passwordTextField.text!))
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let uri = sender as? String, let controller = segue.destination as? StreamViewController {
            controller.URI = uri
        }
    }
}

