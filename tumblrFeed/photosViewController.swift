//
//  photosViewController.swift
//  tumblrFeed
//
//  Created by Kevin M Call on 2/1/17.
//  Copyright © 2017 Kevin M Call. All rights reserved.
//

import UIKit
import AFNetworking


class photosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var imageFeed: UITableView!
    
    var posts: [NSDictionary] = []
    var isMoreDataLoading = false
    var loadingMoreView:InfiniteScrollActivityView?
    var indexOffset = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageFeed.delegate = self
        imageFeed.dataSource = self
        
        // Do any additional setup after loading the view.
        
        // Set up Infinite Scroll loading indicator
        let frame = CGRect(x: 0, y: imageFeed.contentSize.height, width: imageFeed.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        imageFeed.addSubview(loadingMoreView!)
        
        var insets = imageFeed.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        imageFeed.contentInset = insets
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        imageFeed.insertSubview(refreshControl, at: 0)
        
        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        let task : URLSessionDataTask = session.dataTask(
            with: request as URLRequest,
            completionHandler: { (data, response, error) in
                if let data = data {
                    if let responseDictionary = try! JSONSerialization.jsonObject(
                        with: data, options:[]) as? NSDictionary {
                        // print("responseDictionary: \(responseDictionary)")
                        
                        // Recall there are two fields in the response dictionary, 'meta' and 'response'.
                        // This is how we get the 'response' field
                        let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                        
                        // This is where you will store the returned array of posts in your posts property
                        self.posts = responseFieldDictionary["posts"] as! [NSDictionary]
                        
                    }
                    
                }
                self.imageFeed.reloadData()
        });
        task.resume()
        imageFeed.rowHeight = 240
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell") as! PhotoCell
        let post = posts[indexPath.row]
        //let timeStamp = post["timestamp"] as? String
        
        if let photos = post.value(forKeyPath: "photos") as? [NSDictionary] {
            let imageUrlString = photos[0].value(forKeyPath: "original_size.url") as? String
            if let imageUrl = URL(string: imageUrlString!) {
                cell.tumbleImage.setImageWith(imageUrl)
                
                
            }
        }
        
       // cell.textLabel?.text = "This is row \(indexPath.row)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func refreshControlAction(_ refreshControl: UIRefreshControl) {
        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV&offset=\(indexOffset)")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        let task : URLSessionDataTask = session.dataTask(
            with: request as URLRequest,
            completionHandler: { (data, response, error) in
                if let data = data {
                    if let responseDictionary = try! JSONSerialization.jsonObject(
                        with: data, options:[]) as? NSDictionary {
                        
                        let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                        
                        self.posts = responseFieldDictionary["posts"] as! [NSDictionary]
                        
                    }
                    
                }
                self.imageFeed.reloadData()
                refreshControl.endRefreshing()
        });
        task.resume()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!isMoreDataLoading) {
            
            // Calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = imageFeed.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - imageFeed.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && imageFeed.isDragging) {
                
                isMoreDataLoading = true
                
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRect(x: 0, y: imageFeed.contentSize.height, width: imageFeed.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                // Code to load more results
                self.indexOffset += 20
                let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV&offset=\(indexOffset)")
                let request = URLRequest(url: url!)
                let session = URLSession(
                    configuration: URLSessionConfiguration.default,
                    delegate:nil,
                    delegateQueue:OperationQueue.main
                )
                let task : URLSessionDataTask = session.dataTask(
                    with: request as URLRequest,
                    completionHandler: { (data, response, error) in
                        // Update flag
                        self.isMoreDataLoading = false

                        // Stop the loading indicator
                        self.loadingMoreView!.stopAnimating()
                        
                        if let data = data {
                            if let responseDictionary = try! JSONSerialization.jsonObject(
                                with: data, options:[]) as? NSDictionary {
                                
                                let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                                
                                self.posts += responseFieldDictionary["posts"] as! [NSDictionary]
                                
                            }
                            
                        }
                        self.imageFeed.reloadData()
                });
                task.resume()
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        let cell = sender as! UITableViewCell
        let indexPath = imageFeed.indexPath(for: cell)
        let post = posts[indexPath!.row]
        
        let detailViewController = segue.destination as! PhotoDetailsViewController
        if let photos = post.value(forKeyPath: "photos") as? [NSDictionary] {
            let imageUrlString = photos[0].value(forKeyPath: "original_size.url") as? String
            detailViewController.photoUrl = imageUrlString
        }
        
    }
    

}
