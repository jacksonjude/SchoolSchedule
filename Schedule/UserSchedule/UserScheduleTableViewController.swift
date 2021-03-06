//
//  UserScheduleTableViewController.swift
//  Schedule
//
//  Created by jackson on 10/10/17.
//  Copyright © 2017 jackson. All rights reserved.
//

import UIKit
import CloudKit

class UserScheduleTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var periodNames: Array<String> = []
    var uploadData = false
    @IBOutlet weak var tableView: UITableView!
    var justSetUserScheduleID = false
    var offBlocks: Array<Int> = []
    var selectedRow = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.println("Loading UserSchedule...")
                
        self.view.setBackground()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appGroupUserDefaults = UserDefaults(suiteName: "group.com.jacksonjude.BellSchedule")
        if appGroupUserDefaults?.object(forKey: "userID") == nil
        {
            showUserIDAlert()
        }
    }
    
    func showUserIDAlert()
    {
        let userIDAlert = UIAlertController(title: "Set UserID", message: "Enter a UserID to load or create a new user schedule", preferredStyle: .alert)
        
        userIDAlert.addTextField { (textField) in
            let appGroupUserDefaults = UserDefaults(suiteName: "group.com.jacksonjude.BellSchedule")
            textField.placeholder = (appGroupUserDefaults?.object(forKey: "userID") as? String) ?? "UserID"
        }
        
        userIDAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (alert) in
            self.performSegue(withIdentifier: "exitUserSchedule", sender: self)
        }))
        
        userIDAlert.addAction(UIAlertAction(title: "Set", style: .default, handler: { (alert) in
            let userID = userIDAlert.textFields![0].text
            if userID != nil && userID != ""
            {
                let appGroupUserDefaults = UserDefaults(suiteName: "group.com.jacksonjude.BellSchedule")
                appGroupUserDefaults?.set(userID, forKey: "userID")
                appGroupUserDefaults?.synchronize()
                Logger.println(" USRID: Set userID: " + userID!)
                
                self.justSetUserScheduleID = true
                self.getUserID()
            }
            else
            {
                self.performSegue(withIdentifier: "exitUserSchedule", sender: self)
            }
        }))
        
        self.present(userIDAlert, animated: true) {
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return periodNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserPeriodCell", for: indexPath)
        cell.textLabel?.text = "Period " + String(indexPath.row + 1) + ": " + periodNames[indexPath.row]
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getUserID()
    }
    
    func getUserID()
    {
        Logger.println(" USRID: Fetching userID")
        let appGroupUserDefaults = UserDefaults(suiteName: "group.com.jacksonjude.BellSchedule")
        if let userID = appGroupUserDefaults?.object(forKey: "userID") as? String
        {
            Logger.println(" USRID: userID: " + userID)
            queryUserSchedule(userID: userID)
        }
        else
        {
            Logger.println(" USRID: No userID")
        }
    }
    
    func queryUserSchedule(userID: String)
    {
        Logger.println(" USRSCH: Fetching periodNamesRecord")
        let userScheduleReturnID = UUID().uuidString
        NotificationCenter.default.addObserver(self, selector: #selector(receiveUserSchedule(notification:)), name: Notification.Name(rawValue: "fetchedPublicDatabaseObject:" + userScheduleReturnID), object: nil)
        
        let userScheduleQueryPredicate = NSPredicate(format: "userID == %@", userID)
        CloudManager.fetchPublicDatabaseObject(type: "UserSchedule", predicate: userScheduleQueryPredicate, returnID: userScheduleReturnID)
    }
    
    @objc func receiveUserSchedule(notification: NSNotification)
    {
        if let periodNamesRecord = notification.userInfo?["object"] as? CKRecord
        {
            Logger.println(" USRSCH: Received periodNamesRecord")
            if let periodNamesFromRecord = periodNamesRecord.object(forKey: "periodNames") as? [String]
            {
                OperationQueue.main.addOperation {
                    if self.justSetUserScheduleID
                    {
                        let confirmUserIDAlert = UIAlertController(title: "Confirm UserID", message: "This UserID is already linked to a schedule. Load existing schedule?", preferredStyle: .alert)
                        
                        confirmUserIDAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (alert) in
                            let appGroupUserDefaults = UserDefaults(suiteName: "group.com.jacksonjude.BellSchedule")
                            appGroupUserDefaults?.set(nil, forKey: "userID")
                            appGroupUserDefaults?.synchronize()
                            self.performSegue(withIdentifier: "exitUserSchedule", sender: self)
                        }))
                        
                        confirmUserIDAlert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (alert) in
                            
                        }))
                        
                        self.present(confirmUserIDAlert, animated: true, completion: {
                            
                        })
                    }
                    self.periodNames = periodNamesFromRecord
                }
            }
            else
            {
                periodNames = ["", "", "", "", "", "", "", "", "Registry"]
            }
            
            
            if let offBlocksFromRecord = periodNamesRecord.object(forKey: "offBlocks") as? [Int]
            {
                OperationQueue.main.addOperation {
                    self.offBlocks = offBlocksFromRecord
                }
            }
            else
            {
                offBlocks = [0, 0, 0, 0, 0, 0, 0, 0]
            }
        }
        else
        {
            Logger.println(" USRSCH: Did not receive periodNamesRecord")
            
            periodNames = ["", "", "", "", "", "", "", "", "Registry"]
            offBlocks = [0, 0, 0, 0, 0, 0, 0, 0]
        }
        
        if let returnID = notification.userInfo?["returnID"] as? String
        {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("fetchedPublicDatabaseObject:" + returnID), object: nil)
        }
        
        OperationQueue.main.addOperation {
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
        
        let userPeriodChangeAlert = UIAlertController(title: "Period Name Change", message: "Edit the name of the period\n\n", preferredStyle: .alert)
        
        userPeriodChangeAlert.addTextField { (textField) in
            textField.text = self.periodNames[indexPath.row]
        }
        
        userPeriodChangeAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (alert) in
            
        }))
        
        userPeriodChangeAlert.addAction(UIAlertAction(title: "Set", style: .default, handler: { (alert) in
            let periodName = userPeriodChangeAlert.textFields![0].text
            if periodName != nil || periodName != ""
            {
                self.periodNames[indexPath.row] = periodName!
                
                OperationQueue.main.addOperation {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                    self.tableView.reloadData()
                }
            }
        }))
        
        userPeriodChangeAlert.view.addSubview(createSwitch(indexPath.row))
        
        let offBlockLabel = UILabel(frame: CGRect(x: 15, y: 50, width: 200, height: 70))
        offBlockLabel.text = "Off Block:"
        offBlockLabel.font = UIFont(name: "System", size: 15)
        userPeriodChangeAlert.view.addSubview(offBlockLabel)
        
        self.present(userPeriodChangeAlert, animated: true) {
            
        }
    }
    
    func createSwitch(_ indexRow: Int) -> UISwitch
    {
        let newSwitch = UISwitch(frame: CGRect(x: 95, y: 70, width: 0, height: 0))
        if offBlocks.count - 1 >= indexRow
        {
            newSwitch.setOn(offBlocks[indexRow] == 1, animated: false)
        }
        else
        {
            newSwitch.isEnabled = false
        }
        newSwitch.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .valueChanged)
        return newSwitch
    }
    
    @objc func switchValueDidChange(sender: Any)
    {
        if offBlocks.count - 1 >= selectedRow
        {
            Logger.println(" USRSCH: Off Block toggle for " + String(selectedRow))
            
            offBlocks[selectedRow] = offBlocks[selectedRow] == 0 ? 1 : 0
        }
    }
    
    @IBAction func performUnwind(_ sender: Any) {
        let barButtonItem = sender as! UIBarButtonItem
        if barButtonItem.tag == 618
        {
            uploadData = true
            appDelegate.refreshUserScheduleOnScheduleViewController = true
            appDelegate.refreshDataOnScheduleViewController = true
        }
        performSegue(withIdentifier: "exitUserSchedule", sender: self)
    }
}
