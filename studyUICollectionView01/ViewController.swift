//
//  ViewController.swift
//  studyUICollectionView01
//
//  Created by mac373 on 15/9/14.
//  Copyright (c) 2015年 ole. All rights reserved.
//

import UIKit
import XWSwiftRefresh
import SwiftHTTP

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var images:Array<Dictionary<String,String>> = []

    @IBOutlet weak var mCollectionView: UICollectionView!
    @IBOutlet weak var mProgressBar: UIActivityIndicatorView!
    
    var mRrefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mCollectionView.delegate = self
        mCollectionView.dataSource = self
        
        //当所有collectionCell的高度和没有占满整个parent container的时候，
        //当下拉的时候都不会触发scrollViewDidScroll。
        //所以在创建collectionView的时候添加
        mCollectionView.alwaysBounceVertical = true
        
        //添加下拉刷新
        mRrefreshControl.addTarget(self, action: "downPullRefresh", forControlEvents: UIControlEvents.ValueChanged)
        mRrefreshControl.attributedTitle = NSAttributedString(string: "松开后自动刷新")
        mCollectionView.addSubview(mRrefreshControl)
        
        //添加上拉刷新
        mCollectionView.footerView = XWRefreshAutoNormalFooter(target: self, action: "upPullRefresh")
        mCollectionView.footerView?.hidden = true
        
        //加载数据
        downPullRefresh()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MyCell",
            forIndexPath: indexPath) as! MyCollectionViewCell
        //重置cell内容为空
        cell.mImage.image = nil
        cell.mActivityIndicatorView.startAnimating()
        //异步线程读取图片
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let imageString = self.images[indexPath.row]["preview"]
            let imageUrl = NSURL(string: imageString!)
            let imageData = NSData(contentsOfURL: imageUrl!)
            //跳回主线程刷新ui
            dispatch_async(dispatch_get_main_queue(), {
                if (imageData != nil) {
                    cell.mImage.image = UIImage(data: imageData!)
                    cell.mActivityIndicatorView.stopAnimating()
                }
            })
        })
        return cell
    }
    
    /*下拉刷新*/
    func downPullRefresh() {
        do {
            let opt = try HTTP.GET("http://swiftdeveloperblog.com/list-of-images/", parameters: ["uuid":NSUUID().UUIDString])
            opt.start { response in
                if let err = response.error {
                    print("error: \(err.localizedDescription)")
                    return //also notify app of failure as needed
                }
//                print("opt finished: \(response.description)")
                //print("data is: \(response.data)") access the response of the data with response.data
                
                if let data = response.data as? NSData {
                    let str = NSString(data: data, encoding: NSUTF8StringEncoding)
//                    print("response: \(str)") //prints the HTML of the page
                    do {
                        let jsonArray = try NSJSONSerialization
                            .JSONObjectWithData(data,  options:NSJSONReadingOptions()) as! Array<Dictionary<String, String>>
                        self.images = jsonArray
                        dispatch_async(dispatch_get_main_queue()) {
                            self.mCollectionView.reloadData()
                            self.mProgressBar.stopAnimating()
                            self.mRrefreshControl.endRefreshing()
                            self.mCollectionView.footerView!.hidden = false
                        }
                    } catch let error {
                        print("\(error)")
                    }
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
        }
    }
    
//    func downPullRefresh() {
//        let startTime = NSDate.timeIntervalSinceReferenceDate()
//        var pageUrl = "http://swiftdeveloperblog.com/list-of-images/?uudi=" + NSUUID().UUIDString
//        let myUrl = NSURL(string: pageUrl)
//        let request = NSMutableURLRequest(URL: myUrl!)
//        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
//            data, response, error in
//            
//            //if error display alert message
//            if error != nil {
//                var myAlert = UIAlertController(title:"Alert", message:error.localizedDescription, preferredStyle:UIAlertControllerStyle.Alert)
//                let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
//                myAlert.addAction(okAction)
//                self.presentViewController(myAlert, animated: true, completion: nil)
//                return
//            }
//            
//            var err: NSError?
//            var jsonArray = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: &err) as? NSArray
//            
//            if let parseJSONArray = jsonArray {
//                self.images = parseJSONArray //as! [String]
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.mCollectionView.reloadData()
//                })
//            }
//        }
//        task.resume()
//    }
    
    /*上拉刷新*/
    func upPullRefresh(){
        //延迟执行 模拟网络延迟，实际开发中去掉
        xwDelay(1) { () -> Void in
            self.images.append(["preview":"http://swiftdeveloperblog.com/wp-content/uploads/2015/07/1.jpeg"])
            self.images.append(["preview":"http://swiftdeveloperblog.com/wp-content/uploads/2015/07/1.jpeg"])
            self.images.append(["preview":"http://swiftdeveloperblog.com/wp-content/uploads/2015/07/1.jpeg"])
            self.mCollectionView.reloadData()
            self.mCollectionView.footerView?.endRefreshing()
            
        }
        
    }
}

