
import Foundation
import UIKit


class InstagramGridView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var instagramGridView: UITableView!
    
    var mediaList : [InstagramMedia] = []
    var instagramApi = InstagramApi.shared
    var testUserData = InstagramTestUser(access_token: "", user_id: 0)
    var instagramUser: InstagramUser?
    
    private var localMedia: [InstagramLocalMedia] = [] {
        didSet {
            DispatchQueue.main.async {
                self.instagramGridView.reloadData()
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return localMedia.count

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = instagramGridView.dequeueReusableCell(withIdentifier: "cellReusableIdentifier") as! InstagramMediaCell
        cell.mediaTimeStamp.text = localMedia[indexPath.row].timestamp
        cell.mediaCaption.text = localMedia[indexPath.row].caption

        self.instagramApi.fetchImage(urlString: localMedia[indexPath.row].media_url, completion: { (fetchedImage) in
             if let imageData = fetchedImage {
                 DispatchQueue.main.async {
                    cell.mediaImage.image = UIImage(data: imageData)
                    
                 }
             } else {
                 print("Didn't fetch the data")
             }
             
         })
         
        return cell

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height){
                instagramGridView.reloadData()
            }
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
        
    override func viewWillAppear(_ animated: Bool) {
        title = "@\(instagramUser!.username)'s media"
    }
    
    
    override func viewDidLoad() {
        instagramGridView.delegate = self
        instagramGridView.dataSource = self
        
        self.instagramApi.getMediaList(testUserData: self.testUserData, completion: {[weak self] (media, caption) in
            var aPost = InstagramLocalMedia(id: "", caption: "", media_url: "", username: "", timestamp: "")
            aPost.caption       =   caption
            aPost.id            =   media.id
            aPost.media_url     =   media.media_url
            aPost.username      =   media.username
            aPost.timestamp     =   media.timestamp
            self?.localMedia.append(aPost)
            
            print("\n self?localMedia.count == \(self?.localMedia.count) =>")
            print("self?localMedia == \(self?.localMedia)")
            
            
            
        })
        
        print("\n\n localMedia == \(localMedia)")
                       

    }
    
    
    
 
    
}
