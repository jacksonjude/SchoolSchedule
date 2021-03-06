//
//  TodayViewController.swift
//  ScheduleWidget
//
//  Created by jackson on 11/23/17.
//  Copyright © 2017 jackson. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData
import CloudKit

class TodayViewController: UITableViewController, NCWidgetProviding, ScheduleInfoDelegate {
    @IBOutlet weak var schoolStartEndLabel: UILabel!
    @IBOutlet weak var tomorrowStartTimeLabel: UILabel!
    
    var currentPeriodInfoString: String? = nil
    {
        didSet
        {
            printInFirstTextBox()
        }
    }
    var todaySchoolStartInfoString: String? = nil
    {
        didSet
        {
            printInFirstTextBox()
        }
    }
    var inSchool = false
    
    func printCurrentPeriod(periodRangeString: String, periodNumber: Int, todaySchedule: NSManagedObject) {
        if let periodNumbers = CoreDataStack.decodeArrayFromJSON(object: todaySchedule, field: "periodNumbers") as? Array<Int>
        {
            let periodRangeSplit = periodRangeString.split(separator: "-")
            let periodStartString = Date().convertToStandardTime(date: String(periodRangeSplit[0]))
            let periodEndString = Date().convertToStandardTime(date: String(periodRangeSplit[1]))
            
            let periodInfo1 = "The current period is " + String(periodNumbers[periodNumber-1]) + "\n"
            let periodInfo2 = periodStartString! + "-" + periodEndString!
            
            self.currentPeriodInfoString = periodInfo1 + periodInfo2
        }
    }
    
    func printPeriodName(todaySchedule: NSManagedObject, periodNames: Array<String>) {
        return
    }
    
    func printCurrentMessage(message: String) {
        let linesplit = message.split(separator: "\n")
        if linesplit.count > 2
        {
            self.currentPeriodInfoString = String(linesplit[0]) + "\n" + String(linesplit[1])
        }
        else
        {
            self.currentPeriodInfoString = message
        }
    }
    
    func printInternalError(message: String, labelNumber: Int) {
        return
    }
    
    func printSchoolStartEndMessage(message: String) {
        OperationQueue.main.addOperation {
            self.schoolStartEndLabel.text = message
        }
    }
    
    func printSchoolStartEndTime(schoolStartTime: String, schoolEndTime: String) {
        let currentDate = Date()
        
        let startTimeStart = getDate(hourMinute: schoolStartTime, day: currentDate)
        let endTimeEnd = getDate(hourMinute: schoolEndTime, day: currentDate)
        
        let schoolStartToPastRange = Date.distantPast ... startTimeStart
        if schoolStartToPastRange.contains(currentDate)
        {
            self.inSchool = false
            
            todaySchoolStartInfoString = "School starts today at " + Date().convertToStandardTime(date: String(schoolStartTime))
        }
        else
        {
            self.inSchool = true
            
            todaySchoolStartInfoString = "School started today at " + Date().convertToStandardTime(date: String(schoolStartTime))
        }
        
        let schoolEndToPastRange = Date.distantPast ... endTimeEnd
        if schoolEndToPastRange.contains(currentDate)
        {
            todaySchoolStartInfoString! += "\nSchool ends today at " + Date().convertToStandardTime(date: String(schoolEndTime))
        }
        else
        {
            self.inSchool = false
            todaySchoolStartInfoString! += "\nSchool ended today at " + Date().convertToStandardTime(date: String(schoolEndTime))
        }
    }
    
    func printTomorrowStartTime(tomorrowSchoolStartTime: String, tomorrowSchedule: Schedule, nextWeekCount: Int, nextDayCount: Int) {
        //Determine the date when school starts next
        var startOfNextSchoolDayRaw = Date().getStartOfNextWeek(nextWeek: nextWeekCount)
        let gregorian = Calendar(identifier: .gregorian)
        
        //Find the current day of the week from 0-6
        let todayComponents = gregorian.dateComponents([.weekday], from: Date())
        let currentDayOfWeek = todayComponents.weekday! - 1
        
        let dayInSeconds = (60*60*24+3600)
        
        //Add currentDayOfWeek to the nextDayCount in seconds
        var weekDaysToAdd = 0.0
        if nextWeekCount > 0
        {
            weekDaysToAdd = Double(dayInSeconds * (nextDayCount + 1))
        }
        else
        {
            weekDaysToAdd = Double(dayInSeconds * (nextDayCount + 1 + currentDayOfWeek))
        }
        startOfNextSchoolDayRaw.addTimeInterval(weekDaysToAdd)
        
        //Set the hour correctly
        var startOfNextSchoolDayComponents = gregorian.dateComponents([.month, .day, .weekday], from: startOfNextSchoolDayRaw)
        startOfNextSchoolDayComponents.hour = 12
        let startOfNextSchoolDayFormatted = gregorian.date(from: startOfNextSchoolDayComponents)!
        
        //Format as MM/dd
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let startOfNextSchoolDayString = formatter.string(from: startOfNextSchoolDayFormatted)
        
        //Get the start time and the weekday name
        //let tomorrowSchoolStartTime = tomorrowPeriodTimes[0].split(separator: "-")[0]
        
        var weekDayOfSchoolStart = ""
        if nextWeekCount > 0
        {
            weekDayOfSchoolStart = Date().getStringDayOfWeek(day: nextDayCount + 1)
        }
        else
        {
            weekDayOfSchoolStart = Date().getStringDayOfWeek(day: nextDayCount + 1 + currentDayOfWeek)
        }
        
        OperationQueue.main.addOperation {
            let schoolStart1 = "School starts " + weekDayOfSchoolStart + ",\n" + startOfNextSchoolDayString
            let schoolStart2 = " at " + Date().convertToStandardTime(date: String(tomorrowSchoolStartTime))
            self.tomorrowStartTimeLabel.text = schoolStart1 + schoolStart2
        }
    }
    
    func getDate(hourMinute: String, day: Date) -> Date
    {
        let hourMinuteSplit = hourMinute.split(separator: ":")
        let gregorian = Calendar(identifier: .gregorian)
        var dateComponents = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: day)
        dateComponents.hour = Int(hourMinuteSplit[0])
        dateComponents.minute = Int(hourMinuteSplit[1])
        dateComponents.second = 0
        let periodStartDate = gregorian.date(from: dateComponents)!
        
        return periodStartDate
    }
    
    var scheduleInfoManager: ScheduleInfoManager?
    var viewDidJustLoad = true
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        //self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        scheduleInfoManager = ScheduleInfoManager(delegate: self, downloadData: true, onlyFindOneDay: false)
        scheduleInfoManager?.startInfoManager()
        
        viewDidJustLoad = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !viewDidJustLoad
        {
            updateScheduleInfo()
        }
        else
        {
            viewDidJustLoad = false
        }
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded
        {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 180)
        }
        else
        {
            self.preferredContentSize = maxSize
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateScheduleInfo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        updateScheduleInfo()
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func updateScheduleInfo()
    {
        schoolStartEndLabel.text = "Loading..."
        tomorrowStartTimeLabel.text = "Loading..."
        
        if Reachability.isConnectedToNetwork()
        {
            scheduleInfoManager?.downloadCloudData()
        }
        else
        {
            scheduleInfoManager?.refreshScheduleInfo()
        }
    }
    
    func printInFirstTextBox()
    {
        OperationQueue.main.addOperation {
            if self.inSchool && self.currentPeriodInfoString != nil
            {
                self.schoolStartEndLabel.text = self.currentPeriodInfoString
            }
            else if self.todaySchoolStartInfoString != nil
            {
                self.schoolStartEndLabel.text = self.todaySchoolStartInfoString
            }
        }
    }
}
