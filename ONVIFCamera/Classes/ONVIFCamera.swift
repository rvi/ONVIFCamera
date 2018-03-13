//
//  ONVIFCamera.swift
//  StreamTutorial
//
//  Created by Rémy Virin on 12/01/2018.
//  Copyright © 2018 RemyVirin. All rights reserved.
//

import Foundation

/**
 * This enum contains all the ONVIF requests implemented in this library.
 * It allows us to retrieve information on the camera (Manufacturer, Model, serial number)
 * We can also retrieve the different media profiles and a stream URI associated to a media profile.
 */
enum CameraRequest {
    case getDeviceInformation
    case getProfiles
    case getStreamURI(params: [String: String])
    
    /// The soap action for the corresponding route
    var soapAction: String {
        switch self {
        case .getDeviceInformation:
            return "http://www.onvif.org/ver10/device/wsdl/GetDeviceInformation"
        case .getProfiles:
            return "http://www.onvif.org/ver20/media/wsdl/GetProfiles"
        case .getStreamURI:
            return "http://www.onvif.org/ver20/media/wsdl/GetStreamUri"
        }
    }
    
    /** Indicate if we should retrieve the attributes inside the xml element, for instance it's needed
     in `getProfiles` to retrieve the token: `<trt:Profiles token="MediaProfile000" fixed="true">`
     */
    var retrieveAttributes: Bool {
        switch self {
        case .getProfiles:
            return true
        default:
            return false
        }
    }
    
    /// Needed in `getStreamURI` to pass the profile token and the protocol
    var params: [String: String]? {
        switch self {
        case .getStreamURI(let params):
            return params
        default:
            return nil
        }
    }
}

/** Main class of the pod, it alprofileslows us to connect to an ONVIF camera, retrieve informations, its media profiles and
 the stream URI.
 */
public class ONVIFCamera {
    
    /**
     The state of the camera. The camera can be in these states, it helps us to keep track up to which state we have been.
     * `NotConnected`: The camera have been instantiate, but we never try to connect to it yet.
     * `Connected`: we have been able to connect and get informations from the camera, in other terms, the IP address,
     the login and password are valid.
     * `HasProfiles`: We retrieved the media profiles.
     * `ReadyToPlay`: We retrieved an URI to view the live stream.
     * `No Profiles`: In case the camera returns 0 profile.
     */
    public enum CameraState {
        case NotConnected
        case Connected
        case HasProfiles
        case ReadyToPlay // Has URI
        case NoProfiles
    }
    
    /// A profile is made of its name and token. The token should be passed to the `getStreamURI` method.
    public struct Profile {
        public let name: String
        public let token: String
    }
    
    /// The IP address of the camera, passed on the init.
    let ipAdress: String
    /// The credential passed on the init if needed.
    let credential: (login: String, password: String)?
    
    /// The manufacturer of the camera
    public var manufacturer: String? = nil
    /// The model of the camera
    public var model: String? = nil
    /// The serial number of the camera
    var serialNumber: String? = nil
    
    /// The media profiles retrieved from the camera
    var profiles: [Profile]?
    
    /// The current state of the camera
    public var state = CameraState.NotConnected
    
    /// The streamURI with login/password append to it.
    public var streamURI: String?
    
    /// The SOAPEngine license key
    var soapEngineLicenseKey: String?
    
    public init(with ipAdress: String, credential: (login: String, password: String)?, soapLicenseKey: String? = nil) {
        self.ipAdress = ipAdress
        self.credential = credential
        self.soapEngineLicenseKey = soapLicenseKey
    }
    
    /// Test camera connection and retrieve informations
    public func getCameraInformation(callback: @escaping (ONVIFCamera) -> (), error: @escaping (_ reason: String) -> ()) {
        performRequest(request: CameraRequest.getDeviceInformation, response: { (result) in
            guard let body = result["Body"] as? [String: Any],
                let response = body["GetDeviceInformationResponse"]  as? [String: Any] else { return }
            print("Camera information:")
            print(response)
            
            self.state = .Connected
            self.manufacturer = response["Manufacturer"] as? String
            self.model = response["Model"] as? String
            self.serialNumber = response["SerialNumber"] as? String
            
            callback(self)
        }, error: error)
    }
    
    
    /// Retrieve the media profiles of the camera
    public func getProfiles(profiles: @escaping ([Profile]) -> ()) {
        performRequest(request: CameraRequest.getProfiles, response: { (result) in
            guard let body = result["Body"] as? [String: Any],
                let response = body["GetProfilesResponse"]  as? [String: Any],
            let profilesDict = response["Profiles"] as? [[String: Any]] else { return }
            print("Profiles:")
            print(profilesDict)
            
            var parsedProfiles = [Profile]()
            
            profilesDict.forEach({ (dict) in
                if let nameDict = dict["Name"] as? [String: Any],
                let name = nameDict["value"] as? String,
                let attrDict = dict["attributes"] as? [String: Any],
                    let token = attrDict["token"] as? String {
                 
                    let profile = Profile(name: name, token: token)
                    parsedProfiles.append(profile)
                }
            })
            
            print("parsed: \(parsedProfiles)")
            self.profiles = parsedProfiles
            
            if parsedProfiles.count > 0 {
                self.state = .HasProfiles
            } else {
                self.state = .NoProfiles
            }
            
            profiles(parsedProfiles)
        })
    }
    
    public func getStreamURI(with token: String, uri: @escaping (String) -> ()) {
        let params = ["Protocol": "RTSP", "ProfileToken": token]
        
        performRequest(request: CameraRequest.getStreamURI(params: params), response: { (result) in
            guard let body = result["Body"] as? [String: Any],
                let response = body["GetStreamUriResponse"]  as? [String: Any],
                let uriReceived = response["Uri"] as? String else { return }
            
            self.streamURI = self.appendCredentialsToStreamURI(uri: uriReceived)
            self.state = .ReadyToPlay
            uri(uriReceived)
        })
    }
    
    
    /// Util method to append the credential to the stream URI
    private func appendCredentialsToStreamURI(uri: String) -> String {
        guard let credential = credential else { return uri }
        
        let index = uri.index(uri.startIndex, offsetBy: "rtsp://".count)
        let endOfUri = uri[index...]
        let beginningOfUri = uri[..<index]
        
        return String(beginningOfUri) + credential.login + ":" + credential.password + "@" + endOfUri
    }
    
    /// Private method to perform a SOAP request
    private func performRequest(request: CameraRequest, response: @escaping ([String: Any]) -> (),
                                error:((String) -> ())? = nil) {
    
        let soap = SOAPEngine()
        soap.licenseKey = soapEngineLicenseKey
        soap.version = SOAPVersion.VERSION_1_2
        soap.authorizationMethod = SOAPAuthorization.AUTH_WSSECURITY
        
        if let  credential = credential {
            soap.username = credential.login
            soap.password = credential.password
        }
        soap.responseHeader = true
        soap.retrievesAttributes = request.retrieveAttributes
        
        if let params = request.params {
            soap.setValuesForKeys(params)
        }
        soap.requestURL("http://" + ipAdress + "/onvif/device_service",
                        soapAction: request.soapAction,
                          completeWithDictionary: { (statusCode : Int,
                            dict : [AnyHashable : Any]?) -> Void in
                            
                            if statusCode != 200, let error = error,
                                let dict = dict as? [String : Any],
                            let body = dict["Body"] as? [String : Any],
                            let fault = body["Fault"] as? [String : Any],
                            let reasonDict = fault["Reason"] as? [String : Any],
                            let reason = reasonDict["Text"] as? String {
                                error(reason)
                            } else if statusCode != 200 {
                                print("Can't connect to the camera for an unknow reason. Status code: \(statusCode)")
                                print("response: " + String(describing: dict))
                                error?("Can't connect to the camera for an unknow reason. Status code: \(statusCode)")
                            } else if let dict = dict as? [String : Any] {
                                response(dict)
                            } else {
                                print("Result not valid: \(String(describing: dict))")
                            }
                            
        }) { (error : Error?) -> Void in
            print(error ?? "")
        }
        print("SOAP REQUEST: \(soap.soapActionRequest)")
    }
}
