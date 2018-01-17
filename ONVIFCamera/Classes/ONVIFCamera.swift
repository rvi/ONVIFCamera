//
//  ONVIFCamera.swift
//  StreamTutorial
//
//  Created by Rémy Virin on 12/01/2018.
//  Copyright © 2018 RemyVirin. All rights reserved.
//

import Foundation

enum CameraRequest {
    case getDeviceInformation
    case getProfiles
    case getStreamURI(params: [String: String])
    
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
    
    var retrieveAttributes: Bool {
        switch self {
        case .getProfiles:
            return true
        default:
            return false
        }
    }
    
    var params: [String: String]? {
        switch self {
        case .getStreamURI(let params):
            return params
        default:
            return nil
        }
    }
}

public class ONVIFCamera {
    
    public enum CameraState {
        case NotConnected
        case Connected
        case HasProfiles
        case ReadyToPlay // Has URI
        case NoProfiles
    }
    
    public struct Profile {
        public let name: String
        public let token: String
    }
    
    let ipAdress: String
    let credential: (login: String, password: String)?
    public var manufacturer: String? = nil
    public var model: String? = nil
    var serialNumber: String? = nil
    var profiles: [Profile]?
    public var state = CameraState.NotConnected
    public var streamURI: String?
    
    public init(with ipAdress: String, credential: (login: String, password: String)?) {
        self.ipAdress = ipAdress
        self.credential = credential
    }
    
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
    
    private func appendCredentialsToStreamURI(uri: String) -> String {
        guard let credential = credential else { return uri }
        
        let index = uri.index(uri.startIndex, offsetBy: "rtsp://".count)
        let endOfUri = uri[index...]
        let beginningOfUri = uri[..<index]
        
        return String(beginningOfUri) + credential.login + ":" + credential.password + "@" + endOfUri
    }
    

    private func performRequest(request: CameraRequest, response: @escaping ([String: Any]) -> (),
                                error:((String) -> ())? = nil) {
    
        let soap = SOAPEngine()
        
        if let  credential = credential {
            soap.authorizationMethod = SOAPAuthorization.AUTH_WSSECURITY
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
                                error?("Can't connect to the camera for an unknow reason. Status code: \(statusCode)")
                            } else if let dict = dict as? [String : Any] {
                                response(dict)
                            } else {
                                print("Result not valid: \(String(describing: dict))")
                            }
                            
        }) { (error : Error?) -> Void in
            print(error ?? "")
        }
    }
}
