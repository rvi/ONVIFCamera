//
//  ONVIFCamera.swift
//  StreamTutorial
//
//  Created by Rémy Virin on 06/04/2018.
//  Copyright © 2018 RemyVirin. All rights reserved.
//
internal struct RealmRetriever {
  private let xmlString = "<?xml version=\"1.0\" encoding=\"utf-8\"?>" +
    "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\">" +
    "<soap:Body>" +
    "<GetDeviceInformation xmlns=\"http://www.onvif.org/ver10/device/wsdl\">" +
    "</GetDeviceInformation>" +
    "</soap:Body>" +
  "</soap:Envelope>"

  internal func realm(for url: String) -> String? {
    return post(urlString: url)
  }

  private func post(urlString: String) -> String? {
    var realm: String?

    let group = DispatchGroup()
    group.enter()

    DispatchQueue.global(qos: .background).async {
      guard let url = URL(string: urlString) else { return }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.httpBody = self.xmlString.data(using: .utf8)
      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard
          let httpStatus = response as? HTTPURLResponse,
          httpStatus.statusCode == 401,
          let authenticateHeader = httpStatus.allHeaderFields["WWW-Authenticate"] as? String
          else {
            group.leave()
            return
        }
        realm = self.extractAuthenticateParams(authenticateHeader: authenticateHeader)["realm"]
        group.leave()
      }
      task.resume()
    }
    group.wait()
    return realm
  }

  private func extractAuthenticateParams(authenticateHeader: String) -> [String: String] {
    let header = String(authenticateHeader.dropFirst(7))

    return header.split(separator: ",").reduce(into: [String: String](), {
      let pair = $1.split(separator: "=")

      if let key = pair.first?.trimmingCharacters(in: .whitespaces),
        let value = pair.last?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "") {
        $0[key] = value
      }
    })
  }
}
