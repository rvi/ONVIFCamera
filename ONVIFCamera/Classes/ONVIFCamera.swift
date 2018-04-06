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
  case getServices

  /// The soap action for the corresponding route
  var soapAction: String {
    switch self {
    case .getDeviceInformation:
      return namespace + "/GetDeviceInformation"
    case .getProfiles:
      return namespace + "/GetProfiles"
    case .getStreamURI:
      return namespace + "/GetStreamUri"
    case .getServices:
      return namespace + "/GetServices"
    }
  }

  var namespace: String {
    switch self {
    case .getDeviceInformation, .getServices:
      return "http://www.onvif.org/ver10/device/wsdl"
    case .getProfiles, .getStreamURI:
      return "http://www.onvif.org/ver20/media/wsdl"
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
    case .getServices:
      return ["IncludeCapability": "false"]
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
  let ipAddress: String

  var iPAddressWithoutPort: String {
    get {
      guard let index = ipAddress.index(of: ":") else { return ipAddress }
      return String(ipAddress[..<index])
    }
  }

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

  /// Paths for the services we call on the camera, will be updated with getServices response
  private struct Paths {
    var getDeviceInformation = "/onvif/device_service"
    var getProfiles = "/onvif/device_service"
    var getStreamURI = "/onvif/device_service"
  }

  private var paths = Paths()

  private var realm: String?

  /// The SOAPEngine license key
  var soapEngineLicenseKey: String?

  public init(with ipAdress: String, credential: (login: String, password: String)?, soapLicenseKey: String? = nil) {
    self.ipAddress = ipAdress
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

  /// Retrieve the services provides by the camera
  public func getServices(callback: @escaping () -> ()) {
    performRequest(request: CameraRequest.getServices, response: { (result) in
      guard let body = result["Body"] as? [String: Any],
        let response = body["GetServicesResponse"]  as? [String: Any],
        let services = response["Service"] as? [[String: Any]] else { return }

      services.forEach({ (service) in
        guard let namespace = service["Namespace"] as? String,
          let addr = service["XAddr"] as? String,
          let address = URL(string: addr) else { return }

        if namespace == CameraRequest.getDeviceInformation.namespace {
          self.paths.getDeviceInformation = address.path
        } else if namespace == CameraRequest.getProfiles.namespace {
          self.paths.getProfiles = address.path
          self.paths.getStreamURI = address.path
        }
      })

      callback()
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

    // Retrieve the path and arguments of the uri
    // ex: /onvif/cam/monitor?channel=1&audio=1
    guard let url = URL(string: uri),
      let range = uri.range(of: url.path) else { return uri }

    var ipAddressWithPort = iPAddressWithoutPort

    // Add the port given in argument (uri)
    if let port = url.port {
      ipAddressWithPort += ":" + String(port)
    }

    let pathAndArgs = uri[range.lowerBound...]

    // Return the right uri with credentials, the correct IP address (in case of a firewall),
    // the correct rtsp port and the paths and args or uri
    return "rtsp://" + credential.login + ":" + credential.password + "@" + ipAddressWithPort + pathAndArgs
  }

  /// Private method to perform a SOAP request
  private func performRequest(request: CameraRequest, response: @escaping ([String: Any]) -> (),
                              error:((String) -> ())? = nil) {
    DispatchQueue.global(qos: .default).async {
      let soap = SOAPEngine()
      soap.licenseKey = self.soapEngineLicenseKey
      soap.version = .VERSION_1_2
      soap.authorizationMethod = .AUTH_DIGEST

      if let credential = self.credential {
        soap.username = credential.login
        soap.password = credential.password
        if self.realm == nil {
          self.realm = RealmRetriever().realm(for: "http://" + self.ipAddress)
        }
        soap.realm = self.realm
      }
      soap.responseHeader = true
      soap.retrievesAttributes = request.retrieveAttributes

      if let params = request.params {
        soap.setValuesForKeys(params)
      }
      soap.requestURL("http://" + self.ipAddress + self.pathFor(request: request),
                      soapAction: request.soapAction,
                      completeWithDictionary: { (statusCode : Int,
                        dict : [AnyHashable : Any]?) -> Void in
                        DispatchQueue.main.async {
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
                        }

      }) { (error : Error?) -> Void in
        print(error ?? "")
      }
      print("SOAP REQUEST: \(soap.soapActionRequest)")
    }
  }

  /// returns the correct path depending on the service we're calling
  private func pathFor(request: CameraRequest) -> String {
    switch request {
    case .getProfiles:
      return paths.getProfiles
    case .getStreamURI:
      return paths.getStreamURI
    default:
      return paths.getDeviceInformation
    }
  }
}

