

import UIKit

class InstagramApi {
    
    //MARK:- Member variables
    static let shared = InstagramApi()
    private let instagramAppID = "811325936317531"
    private let redirectURIURLEncoded = "https%3A%2F%2Fwww.hotcocoasoftware.com%2F"
    private let redirectURI = "https://www.hotcocoasoftware.com/"
    private let app_secret = "c34c0b966a7a9abe624929069554f05c"
    private let boundary = "boundary=\(NSUUID().uuidString)"
    
    
    //MARK:- Enums
    private enum BaseURL: String {
        case displayApi = "https://api.instagram.com/"
        case graphApi = "https://graph.instagram.com/"
    }
    
    private enum Method: String {
        case authorize = "oauth/authorize"
        case access_token = "oauth/access_token"
    }
    
    //MARK:- Constructor
    private init() {}
    
    //MARK:- Private Methods
    private func getFormBody(_ parameters: [[String : String]], _ boundary: String) -> Data {
        var body = ""
        let error: NSError? = nil
        for param in parameters {
            let paramName = param["name"]!
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"\(paramName)\""
            if let filename = param["fileName"] {
                let contentType = param["content-type"]!
                var fileContent: String = ""
                do { fileContent = try String(contentsOfFile: filename, encoding: String.Encoding.utf8)}
                catch {
                    print(error)
                }
                if (error != nil) {
                    print(error!)
                }
                body += "; filename=\"\(filename)\"\r\n"
                body += "Content-Type: \(contentType)\r\n\r\n"
                body += fileContent
            } else if let paramValue = param["value"] {
                body += "\r\n\r\n\(paramValue)"
            }
        }
        return body.data(using: .utf8)!
    }
    
    private func getTokenFromCallbackURL(request: URLRequest) -> String? {
        let requestURLString = (request.url?.absoluteString)! as String
        if requestURLString.starts(with: "\(redirectURI)?code=") {
            
            print("Response uri:",requestURLString)
            if let range = requestURLString.range(of: "\(redirectURI)?code=") {
                let tokenFromCallbackURL = String(requestURLString[range.upperBound...].dropLast(2))
                print ("\ntokenFromCallbackURL == \(tokenFromCallbackURL)\n")
                return tokenFromCallbackURL
            }
        }
        return nil
    }
    
    
    //MARK:- Public Methods

    func authorizeApp(completion: @escaping (_ url: URL?) -> Void ) {
        let urlString = "\(BaseURL.displayApi.rawValue)\(Method.authorize.rawValue)?app_id=\(instagramAppID)&redirect_uri=\(redirectURIURLEncoded)&scope=user_profile,user_media&response_type=code"
        let request = URLRequest(url: URL(string: urlString)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if let response = response {
                completion(response.url)
            }
        })
        task.resume()
    }
    
    func getTestUserIDAndToken(request: URLRequest, completion: @escaping (InstagramTestUser) -> Void){
        guard let authToken = getTokenFromCallbackURL(request: request) else {
            return
        }
        
        let headers = [
            "content-type": "multipart/form-data; boundary=\(boundary)"
        ]
        let parameters = [
            ["name": "app_id",
                "value": instagramAppID],
            ["name": "app_secret",
                "value": app_secret],
            ["name": "grant_type",
                "value": "authorization_code"],
            ["name": "redirect_uri",
                "value": redirectURI],
            ["name": "code",
                "value": authToken]
        ]
        
        var request = URLRequest(url: URL(string: BaseURL.displayApi.rawValue + Method.access_token.rawValue)!)
        
        let postData = getFormBody(parameters, boundary)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: {(data, response, error) in
            if (error != nil) {
                print(error!)
            } else {
                do { let jsonData = try JSONDecoder().decode(InstagramTestUser.self, from: data!)
                    print(jsonData)
                    completion(jsonData)
                }
                catch let error as NSError {
                    print(error)
                }
                
            }
        })
        dataTask.resume()
    }

    
    func getInstagramUser(testUserData: InstagramTestUser, completion: @escaping (InstagramUser) -> Void) {
        let urlString = "\(BaseURL.graphApi.rawValue)\(testUserData.user_id)?fields=id,username,media_count&access_token=\(testUserData.access_token)"
        let request = URLRequest(url: URL(string: urlString)!)
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: {(data, response, error) in
            if (error != nil) {
                print(error!)
            } else {
                let httpResponse = response as? HTTPURLResponse
            }
            do { let jsonData = try JSONDecoder().decode(InstagramUser.self, from: data!)
                completion(jsonData)
            }
            catch let error as NSError {
                print("\n getInstagramUser: error = \(error)")
                
            }
        })
        dataTask.resume()
    }
    
    func getMedia(testUserData: InstagramTestUser, completion: @escaping (InstagramMedia) -> Void) {
        getMediaData(testUserData: testUserData) { (mediaFeed) in
            let urlString = "\(BaseURL.graphApi.rawValue + mediaFeed.data[0].id)?fields=id,media_type,media_url,username,timestamp&access_token=\(testUserData.access_token)"
            let request = URLRequest(url: URL(string: urlString)!)
            let session = URLSession.shared
            let task = session.dataTask(with: request, completionHandler: { data, response, error in
                if let response = response {
                }
                do { let jsonData = try JSONDecoder().decode(InstagramMedia.self, from: data!)
                    completion(jsonData)
                }
                catch let error as NSError {
                    
                    print("\n InstagramApi - getMedia: error = \(error)")
                }
            })
            task.resume()
        }
    }
    
    private func getMediaData(testUserData: InstagramTestUser, completion: @escaping (Feed) -> Void) {
        let urlString = "\(BaseURL.graphApi.rawValue)me/media?fields=id,caption&access_token=\(testUserData.access_token)"
        let request = URLRequest(url: URL(string: urlString)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if let response = response {

            }
            do { let jsonData = try JSONDecoder().decode(Feed.self, from: data!)
                completion(jsonData)
            }
            catch let error as NSError {
                print("\n InstagramApi - getMediaData: error == \(error)")
            }
        })
        task.resume()
    }

    
    
    func fetchImage(urlString: String, completion: @escaping (Data?) -> Void) {
        let request = URLRequest(url: URL(string: urlString)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if let response = response {
                print(response)
            }
            completion(data)
        })
        task.resume()
    }


    func getMediaList(testUserData: InstagramTestUser, completion: @escaping (_ media : InstagramMedia, _ caption: String) -> Void) {
        getMediaData(testUserData: testUserData) { (mediaFeed) in

            for index in mediaFeed.data.indices {
                
                let urlString = "\(BaseURL.graphApi.rawValue + mediaFeed.data[index].id)?fields=id,media_type,media_url,username,timestamp&access_token=\(testUserData.access_token)"
                let request = URLRequest(url: URL(string: urlString)!)
                let session = URLSession.shared
                
                let task = session.dataTask(with: request, completionHandler: { data, response, error in

                    do {
                        let jsonData = try JSONDecoder().decode(InstagramMedia.self, from: data!)
                        completion(jsonData, mediaFeed.data[index].caption ?? "")
                    }
                        catch let error as NSError {}
                            })
                task.resume()

            }
        }
            
    }
    
}



