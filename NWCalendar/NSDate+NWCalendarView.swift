//
//  NSDate+NWCalendarView.swift
//  NWCalendarDemo
//
//  Created by Nicholas Wargnier on 7/24/15.
//  Copyright (c) 2015 Nick Wargnier. All rights reserved.
//

import Foundation
import UIKit

extension NSDate {
  func nwCalendarView_dayWithCalendar(calendar: NSCalendar) -> NSDateComponents {
    return calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitWeekday | .CalendarUnitCalendar, fromDate: self)
  }
  
  func nwCalendarView_monthWithCalendar(calendar: NSCalendar) -> NSDateComponents {
    return calendar.components(.CalendarUnitCalendar | .CalendarUnitYear | .CalendarUnitMonth, fromDate: self)
  }
  
  func nwCalendarView_dayIsInPast() -> Bool {
    return self.timeIntervalSinceNow <= NSTimeInterval(-86400)
  }
  
}