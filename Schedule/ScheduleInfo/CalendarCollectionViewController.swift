//
//  CalendarCollectionView.swift
//  Schedule
//
//  Created by jackson on 10/11/17.
//  Copyright © 2017 jackson. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData

class CalendarCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    fileprivate let reuseIdentifier = "CalendarDayCell"
    fileprivate let loadedWeeks = 5
    fileprivate let itemsPerRow: CGFloat = 7
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var codeToggleBarButton: UIBarButtonItem!
    @IBOutlet weak var codeToggleButton: UIButton!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    var currentDateString: String?
    var weekScheduleCodes: Array<String> = []
    var weekOn = 0
    var dateToggle = 0
    var currentScheduleObject: NSManagedObject?
    
    override func viewDidLoad() {
        Logger.println("Loading Calendar...")
        fetchAllWeeks(weeksToAdd: 0)
        
        self.view.setBackground()
        
        collectionView.addCorners()
        codeToggleButton.addCorners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //collectionView.frame = CGRect(x: collectionView.frame.origin.x, y: collectionView.frame.origin.y, width: collectionView.frame.size.width, height: )
        //collectionView.frame.size.height = CGFloat(loadedWeeks+1)*(sectionInsets.top+sectionInsets.bottom) + CGFloat(loadedWeeks+1)*(collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: IndexPath(row: 0, section: 1)).frame.size.height) + 10
        collectionViewHeight.constant = CGFloat(loadedWeeks+1)*(sectionInsets.top+sectionInsets.bottom) + CGFloat(loadedWeeks+1)*(collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: IndexPath(row: 0, section: 1)).frame.size.height) + 10
        self.view.layoutIfNeeded()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section
        {
        case 0:
            return 7
        case 1:
            return loadedWeeks*7
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        cell.addCorners()
        
        switch indexPath.section
        {
        case 0:
            let stringDayOfWeek = String(Date().getStringDayOfWeek(day: indexPath.row))
            (cell.viewWithTag(618) as! UILabel).text = String(stringDayOfWeek[stringDayOfWeek.startIndex])
            (cell.viewWithTag(618) as! UILabel).textColor = UIColor.white
            cell.backgroundColor = UIColor(red: CGFloat(0.427), green: CGFloat(0.427), blue: CGFloat(0.427), alpha: 1)
        case 1:
            if dateToggle == 1 //&& self.weekScheduleCodes.count == loadedWeeks*5
            {
                if indexPath.row%7 != 6 && indexPath.row%7 != 0
                {
                    let weekendAdding = (((indexPath.row)/7)*2)+1
                    if self.weekScheduleCodes.count > indexPath.row-weekendAdding
                    {
                        (cell.viewWithTag(618) as! UILabel).text = self.weekScheduleCodes[indexPath.row-weekendAdding]
                    }
                    else
                    {
                        (cell.viewWithTag(618) as! UILabel).text = "L"
                    }
                }
                else
                {
                    (cell.viewWithTag(618) as! UILabel).text = "W"
                }
            }
            else
            {
                (cell.viewWithTag(618) as! UILabel).text = String(describing: getDate(indexPath: indexPath).day!)
            }
            
            if indexPath.row/7 == 0 && indexPath.row%7 == Date().getDayOfWeek()
            {
                cell.backgroundColor = UIColor(white: 0.6, alpha: 1.0)
            }
            else
            {
                cell.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
            }
            
            (cell.viewWithTag(618) as! UILabel).textColor = UIColor.black
        default:
            break
        }
        
        return cell
    }
    
    func getDate(indexPath: IndexPath) -> DateComponents
    {
        var cellDate = Date().startOfWeek!
        cellDate.addTimeInterval(TimeInterval(60*60*24*indexPath.row+3600))
        let cellDateComponents = Date.Gregorian.calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: cellDate)
        return cellDateComponents
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1
        {
            Logger.println(" CAL: Item selected at row " + String(indexPath.row))
            
            currentDateString = nil
            currentScheduleObject = nil
            
            let dateComponents = getDate(indexPath: indexPath)
            
            currentDateString = zeroPadding(int: dateComponents.month!) + "/" + zeroPadding(int: dateComponents.day!) + "/" + zeroPadding(int: dateComponents.year!)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let dateFromComponents = dateFormatter.date(from: currentDateString!)
            
            let startOfWeekDate = Date.Gregorian.calendar.date(from: Date.Gregorian.calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dateFromComponents!))
            
            fetchWeek(date: startOfWeekDate!, fetchingAllWeeks: false)
        }
    }
    
    func fetchWeek(date: Date, fetchingAllWeeks: Bool)
    {
        Logger.println(" FWSCH: Fetching weekScheduleRecord")
        
        let gregorian = Calendar(identifier: .gregorian)
        var startOfWeekComponents = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        startOfWeekComponents.hour = 12
        
        var timeZoneToSet = "PST"
        if TimeZone.current.isDaylightSavingTime(for: gregorian.date(from: startOfWeekComponents)!)
        {
            timeZoneToSet = "PDT"
        }
        startOfWeekComponents.timeZone = TimeZone(abbreviation: timeZoneToSet)
        
        let startOfWeekFormatted = gregorian.date(from: startOfWeekComponents)!
        
        Logger.println(startOfWeekFormatted)
        
        let weekScheduleQueryPredicate = NSPredicate(format: "weekStartDate == %@", startOfWeekFormatted as CVarArg)
        if let weekScheduleRecord = CoreDataStack.fetchLocalObjects(type: "WeekSchedules", predicate: weekScheduleQueryPredicate)?.first as? NSManagedObject
        {
            Logger.println(" FWSCH: Received weekScheduleRecord")
            
            if fetchingAllWeeks
            {
                if let schedules = CoreDataStack.decodeArrayFromJSON(object: weekScheduleRecord, field: "schedules") as? Array<String>
                {
                    for schedule in schedules
                    {
                        weekScheduleCodes.append(schedule)
                    }
                }
                
                fetchAllWeeks(weeksToAdd: weekOn)
            }
            else
            {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy"
                let currentDate = dateFormatter.date(from: currentDateString!)
                
                let gregorian = Calendar(identifier: .gregorian)
                let weekdayComponents = gregorian.dateComponents([.weekday], from: currentDate!)
                if let schedules = CoreDataStack.decodeArrayFromJSON(object: weekScheduleRecord, field: "schedules") as? Array<String>
                {
                    let dayOfWeek = weekdayComponents.weekday!-2
                    if 0 <= dayOfWeek && dayOfWeek < schedules.count
                    {
                        fetchSchedule(scheduleCode: schedules[dayOfWeek])
                    }
                    else
                    {
                        alertUser(message: "Code: N/A\nNo school!")
                    }
                }
            }
        }
        else
        {
            Logger.println(" FWSCH: Did not receive weekScheduleRecord")
            
            self.collectionView.reloadData()
        }
    }
    
    func zeroPadding(int: Int) -> String
    {
        if int > 9
        {
            return String(int)
        }
        else
        {
            return "0" + String(int)
        }
    }
    
    func fetchSchedule(scheduleCode: String)
    {
        Logger.println(" FDSCH: Fetching schedule")
        
        let scheduleQueryPredicate = NSPredicate(format: "scheduleCode == %@", scheduleCode)
        if let scheduleRecord = CoreDataStack.fetchLocalObjects(type: "Schedule", predicate: scheduleQueryPredicate)?.first as? NSManagedObject
        {
            Logger.println(" FDSCH: Received scheduleRecord")
            
            findTimes(scheduleRecord: scheduleRecord)
        }
        else
        {
            Logger.println(" FDSCH: Did not receive scheduleRecord")
            
            alertUser(message: "Code: " + scheduleCode + "\nTBD")
        }
    }
    
    func findTimes(scheduleRecord: NSManagedObject)
    {        
        let scheduleCode = scheduleRecord.value(forKey: "scheduleCode") as! String
        
        var startTime: String? = nil
        var endTime: String? = nil
        var schoolToday = true
        if scheduleCode != "H"
        {
            if let schedules = CoreDataStack.decodeArrayFromJSON(object: scheduleRecord, field: "periodTimes") as? Array<String>
            {
                startTime = String(schedules[0].split(separator: "-")[0])
                endTime = String(schedules[schedules.count-1].split(separator: "-")[1])
            }
        }
        else
        {
            schoolToday = false
        }
        
        var message = ""
        if schoolToday
        {
            let message1 = "Code: " + scheduleCode + "\nStart: "
            let message2 =  Date().convertToStandardTime(date: (startTime ?? "")) + "\nEnd: " + Date().convertToStandardTime(date: (endTime ?? ""))
            message = message1 + message2
            
            currentScheduleObject = scheduleRecord
        }
        else
        {
            message = "Code: H\nNo school!"
        }
        
        alertUser(message: message)
    }
    
    func alertUser(message: String)
    {
        let schoolTimeAlert = UIAlertController(title: currentDateString!, message: message, preferredStyle: .alert)
        
        if currentScheduleObject != nil && currentDateString != nil
        {
            schoolTimeAlert.addAction(UIAlertAction(title: "Details", style: .default, handler: { (alert) in
                
                self.performSegue(withIdentifier: "openPeriodTimesViewFromCalendar", sender: self)
            }))
        }
        
        schoolTimeAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) in
            
        }))
        
        self.present(schoolTimeAlert, animated: true) {
            
        }
    }
    
    func fetchAllWeeks(weeksToAdd: Int)
    {
        if weeksToAdd < loadedWeeks
        {
            var startOfWeekToFetch = Date().startOfWeek!
            startOfWeekToFetch.addTimeInterval(TimeInterval(60*60*24*7*weeksToAdd+3600))
            weekOn+=1
            fetchWeek(date: startOfWeekToFetch, fetchingAllWeeks: true)
        }
        else
        {
            Logger.println(" CAL: Loaded all codes for toggle: " + String(describing: weekScheduleCodes))
            if self.dateToggle == 1
            {
                OperationQueue.main.addOperation {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    @IBAction func toggleDate()
    {
        if self.dateToggle == 0
        {
            self.dateToggle = 1
            self.codeToggleBarButton.title = "Dates"
            self.codeToggleButton.setTitle("Dates", for: .normal)
        }
        else
        {
            self.dateToggle = 0
            self.codeToggleBarButton.title = "Codes"
            self.codeToggleButton.setTitle("Codes", for: .normal)
        }
        collectionView.reloadData()
    }
    
    @IBAction func exitPeriodTimesViewToCalendar(_ segue: UIStoryboardSegue)
    {
        Logger.println("Exiting PeriodTimesViewController...")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "openPeriodTimesViewFromCalendar")
        {
            Logger.println(" CAL: Opening ScheduleTimesViewController...")
            
            let scheduleTimesViewController = segue.destination as! ScheduleTimesViewController
            scheduleTimesViewController.scheduleRecord = currentScheduleObject!
            scheduleTimesViewController.scheduleDateString = currentDateString
            scheduleTimesViewController.parentViewControllerString = "CalendarCollectionViewController"
        }
    }
}
