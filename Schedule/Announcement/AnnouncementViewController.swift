//
//  AnnouncementViewController.swift
//  Schedule
//
//  Created by jackson on 12/21/17.
//  Copyright © 2017 jackson. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

class AnnouncementViewController: UIViewController
{
    var announcementRecord: NSManagedObject?
    
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var announcementNavigationItem: UINavigationItem!
    
    override func viewDidLoad() {
        bodyTextView.addCorners()
        dateLabel.addCorners()
        
        Logger.println("Opening AnnouncementView...")
        
        self.view.setBackground()
    }
    
    func loadDataFromRecord()
    {
        if announcementRecord != nil
        {
            OperationQueue.main.addOperation {
                self.bodyTextView.text = self.announcementRecord!.value(forKey: "bodyText") as? String
                self.announcementNavigationItem.title = self.announcementRecord!.value(forKey: "title") as? String
                let postDate = self.announcementRecord!.value(forKey: "postDate") as! Date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "YYYY-MM-dd hh:mm"
                self.dateLabel.text = dateFormatter.string(from: postDate)
                
                self.bodyTextView.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            }
        }
    }
}
