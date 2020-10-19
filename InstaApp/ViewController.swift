
import UIKit

class ViewController: UIViewController {

    
    var instagramApi = InstagramApi.shared
    var testUserData = InstagramTestUser(access_token: "", user_id: 0)
    var instagramUser: InstagramUser?
    var signedIn = false
    
    @IBOutlet var backgroundImageView: UIImageView!
    
    @IBAction func authenticateOrSignIn(_ sender: UIButton) {
        if self.testUserData.user_id == 0 {
            presentWebViewController()
        } else {
            self.instagramApi.getInstagramUser(testUserData: self.testUserData) { [weak self] (user) in
                self?.instagramUser = user
                self?.signedIn = true
                DispatchQueue.main.async {
                    self?.presentAlert()
                    self?.setTitleAsAlreadySignedinUser()
                }
            }
        }
    }
    
    func setTitleAsAlreadySignedinUser (){
        if self.instagramUser != nil {
            self.title = "Signed in as @\(self.instagramUser!.username)"
        } else {
            print("Not signed in")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setTitleAsAlreadySignedinUser();
    }
    
    @IBAction func fetchImageToBackground(_ sender: UIButton) {
        
        if self.testUserData.user_id != 0 {
            self.instagramApi.getInstagramUser(testUserData: self.testUserData) { [weak self] (user) in
                self?.instagramUser = user
                self?.signedIn = true
                DispatchQueue.main.async {
                    self?.setTitleAsAlreadySignedinUser()
                }
            }
        }

        if self.instagramUser != nil {
            self.instagramApi.getMedia(testUserData: self.testUserData) { (media) in
                if media.media_type != MediaType.VIDEO {
                    let media_url = media.media_url
                    self.instagramApi.fetchImage(urlString: media_url, completion: { (fetchedImage) in
                        if let imageData = fetchedImage {
                            DispatchQueue.main.async {
                                self.backgroundImageView.image = UIImage(data: imageData)
                            }
                        } else {
                            print("Didn't fetched the data")
                        }
                        
                    })
                    print("\n======\n fetchImageToBackground: media_url == \(media_url)\n======\n")
                } else {
                    print("Fetched media is a video")
                }
            }
        } else {
            print("Not signed in")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func presentAlert() {
        let alert = UIAlertController(title: "Signed In:", message: "with account: @\(self.instagramUser!.username)", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true)
        print ("presentAlert: self.instagramUser.username = \(self.instagramUser!.id):\(self.instagramUser!.username)")
    }
    
    func presentWebViewController() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let webVC = storyBoard.instantiateViewController(withIdentifier: "webView") as! WebViewController
        webVC.instagramApi = self.instagramApi
        webVC.mainVC = self
        self.present(webVC, animated:true)
    }

    
    @IBAction func showInstagramGridView(_ sender: UIButton) {
        if self.instagramUser != nil {
            // ?
        } else {
            print("Not signed in")
        }
        
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let identifier = segue.identifier{
                if let sourceVC = segue.source as? ViewController {
                    if let destVC = segue.destination as? InstagramGridView {
                        destVC.instagramUser = sourceVC.instagramUser
                        destVC.testUserData = sourceVC.testUserData
                        }
                }
            }
        }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showMediaGrid", self.instagramUser != nil {
            return true
        }
        else {
            return false
        }
        
    }
    
    
    
    
}

