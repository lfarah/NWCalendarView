//
//  NWCalendarMonthContentView.swift
//  NWCalendarDemo
//
//  Created by Nicholas Wargnier on 7/24/15.
//  Copyright (c) 2015 Nick Wargnier. All rights reserved.
//

import Foundation
import UIKit


protocol NWCalendarMonthContentViewDelegate {
  func didChangeFromMonthToMonth(fromMonth: NSDateComponents, toMonth: NSDateComponents)
  func didSelectDate(fromDate: NSDateComponents, toDate: NSDateComponents)
}

class NWCalendarMonthContentView: UIScrollView {
  private let unitFlags: NSCalendarUnit = .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitWeekday | .CalendarUnitCalendar
  private let kCurrentMonthOffset = 4
  
  var monthContentViewDelegate:NWCalendarMonthContentViewDelegate?
  
  var month         : NSDateComponents!
  var monthViewsDict   = Dictionary<String, NWCalendarMonthView>()
  var monthViews    : [NWCalendarMonthView] = []
  
  var dayViewHeight    : CGFloat = 44
  var maxMonths        : Int!    = 0
  var pastEnabled                = false
  var presentMonthIndex: Int!    = 0
  var selectionRangeLength: Int! = 0
  var selectedDayViews: [NWCalendarDayView] = []
  var lastMonthOrigin: CGFloat?
  var futureEnabled: Bool {
    return maxMonths == 0
  }

  var disabledDatesDict: [String: [NSDateComponents]] = [String: [NSDateComponents]]()
  var disabledDates:[NSDate]? {
    didSet {
      if let dates = disabledDates {
        for date in dates {
          let comp = NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitWeekday | .CalendarUnitCalendar, fromDate: date)
          let key = monthViewKeyForMonth(comp)
          if var compArray = disabledDatesDict[key] {
            compArray.append(comp)
            disabledDatesDict[key] = compArray
          } else {
            let compArray:[NSDateComponents] = [comp]
            disabledDatesDict[key] = compArray
          }
        }
      }
    }
  }
  
  var currentMonthView: NWCalendarMonthView! {
    return monthViews[currentPage]
  }
  
  
  var monthViewOrigins: [CGFloat] = []
  var currentPage:Int! {
    didSet(oldPage) {
      if currentPage == oldPage { return }
      let oldMonthView = monthViews[oldPage]
      
      monthContentViewDelegate?.didChangeFromMonthToMonth(oldMonthView.month, toMonth: currentMonthView.month)
      UIView.animateWithDuration(0.3, animations: {
        self.currentMonthView.isCurrentMonth = true
        oldMonthView.isCurrentMonth = false
      })
    }
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
    delegate = self
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    decelerationRate = UIScrollViewDecelerationRateFast
    presentMonthIndex = kCurrentMonthOffset
    dayViewHeight = frame.height / 6
    currentPage = kCurrentMonthOffset
    
  }
  
  convenience init(month: NSDateComponents, frame: CGRect) {
    self.init(frame: frame)
    self.month = month
  }
  
  func createCalendar() {
    setupMonths(month)
  }
  
  func setupMonths(month: NSDateComponents) {
    var nextVerticalPosition    : CGFloat = 0
    for (var monthOffset = -kCurrentMonthOffset; monthOffset <= 7; monthOffset+=1) {
      var offsetMonth = month.copy() as! NSDateComponents
      offsetMonth.month = offsetMonth.month + monthOffset
      
      
      offsetMonth = offsetMonth.calendar!.components(unitFlags, fromDate: offsetMonth.date!)
      
      
      // Check for overlap with previous month
      var overlapOffset:CGFloat = 0
      var lastMonthMaxY:CGFloat = 0
      if monthViews.count > 0 {
        let lastMonthView = monthViews[monthViews.count-1]
        lastMonthMaxY = CGRectGetMaxY(lastMonthView.frame)
        
        if lastMonthView.numberOfWeeks == 6 || monthStartsOnFirstDayOfWeek(offsetMonth) {
          overlapOffset = dayViewHeight
        } else {
          overlapOffset = dayViewHeight * 2
        }
      }
      
      // Create & Position Month View
      let monthView = cachedOrCreateMonthViewForMonth(offsetMonth)
      
      monthView.frame.origin.y = lastMonthMaxY - overlapOffset
      monthViewOrigins.append(monthView.frame.origin.y)
      
      contentSize.height = lastMonthMaxY
      
      if !futureEnabled {
        let maxMonth = maxMonths-1
        if maxMonth == monthOffset {
          lastMonthOrigin = monthView.frame.origin.y
        } else if monthOffset > maxMonth {
          monthView.disableMonth()
        }
        
      }
      
      
      if offsetMonth.month == month.month {
        monthView.isCurrentMonth = true
      }
      
      let key = monthViewKeyForMonth(offsetMonth)
      if let disabledArray = disabledDatesDict[key] {
        monthView.disabledDates = disabledArray
      }
    }
    
    scrollToOffset(monthViewOrigins[kCurrentMonthOffset], animated: false)
  }
  
}

// MARK: - Navigation
extension NWCalendarMonthContentView {
  func nextMonth() {
    var totalMonths = monthViews.count-1
    if !futureEnabled {
      totalMonths = maxMonths - 1 + kCurrentMonthOffset
    }
    currentPage = min(currentPage+1, totalMonths)
    scrollToOffset(monthViewOrigins[currentPage], animated:true)
  }

  func prevMonth() {
    currentPage = pastEnabled ? max(currentPage-1, 0) : max(currentPage-1, presentMonthIndex)
    scrollToOffset(monthViewOrigins[currentPage], animated:true)
  }
  
  func scrollToOffset(yOffset: CGFloat, animated: Bool) {
    setContentOffset(CGPoint(x: 0, y: yOffset), animated: animated)
  }
}

// MARK: - Caching
extension NWCalendarMonthContentView {
  func monthStartsOnFirstDayOfWeek(month: NSDateComponents) -> Bool{
    let month = month.calendar!.components(unitFlags, fromDate: month.date!)
    return (month.weekday - month.calendar!.firstWeekday) == 0
  }
  
  func monthViewKeyForMonth(month: NSDateComponents) -> String {
    let month = month.calendar?.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: month.date!)
    return "\(month!.year).\(month!.month)"
  }
  
  func cachedOrCreateMonthViewForMonth(month: NSDateComponents) -> NWCalendarMonthView {
    let month = month.calendar?.components(unitFlags, fromDate: month.date!)
    
    let monthViewKey = monthViewKeyForMonth(month!)
    var monthView = monthViewsDict[monthViewKey]
    
    if monthView == nil {
      monthView = NWCalendarMonthView(month: month!, width: bounds.width, height: bounds.height)
      monthViewsDict[monthViewKey] = monthView
      monthViews.append(monthView!)
      monthView?.delegate = self
      addSubview(monthView!)
    }

    return monthView!
    
  }
}


// MARK: - UIScrollViewDelegate
extension NWCalendarMonthContentView: UIScrollViewDelegate {
  func scrollViewDidScroll(scrollView: UIScrollView) {
    
    // Disable scrolling to past
    if !pastEnabled {
      let presentMonthOrigin = monthViewOrigins[presentMonthIndex]
      if scrollView.contentOffset.y < presentMonthOrigin{
        setContentOffset(CGPoint(x: 0, y: presentMonthOrigin), animated: false)
      }
    }
    
    // Disable scrolling to future beyond max month
    if !futureEnabled {
      if scrollView.contentOffset.y > lastMonthOrigin {
        setContentOffset(CGPoint(x: 0, y: lastMonthOrigin!), animated: false)
      }
    }

  }
  
  func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let currentOrigin = monthViewOrigins[currentPage]
    
    var targetOffset = targetContentOffset.memory.y
    
    if targetOffset < currentOrigin-dayViewHeight {
      currentPage = (pastEnabled == false) ? max(currentPage-1, presentMonthIndex) : max(currentPage-1, 0)
      targetOffset = monthViewOrigins[currentPage]
    } else if targetOffset > currentOrigin+dayViewHeight {
      currentPage = !futureEnabled ? min(currentPage+1,maxMonths - 1 + kCurrentMonthOffset) : min(currentPage+1, monthViews.count-1)
      targetOffset = monthViewOrigins[currentPage]
    } else {
      targetOffset = currentOrigin
    }
    
    targetContentOffset.memory = CGPoint(x: 0, y: targetOffset)
  }
}

// MARK: - NWCalendarMonthViewDelegate
extension NWCalendarMonthContentView: NWCalendarMonthViewDelegate {
  func didSelectDay(dayView: NWCalendarDayView) {
    clearSelectedDays()
    var day = dayView.day?.copy() as! NSDateComponents
    
    for i in 0..<selectionRangeLength {
      day = day.date!.nwCalendarView_dayWithCalendar(day.calendar!)
      let month = day.date!.nwCalendarView_monthWithCalendar(day.calendar!)
      let monthViewKey = monthViewKeyForMonth(month)
      let monthView = monthViewsDict[monthViewKey]
      let dayView = monthView?.dayViewForDay(day)
      
      if let unwrappedDayView = dayView {
        unwrappedDayView.isSelected = true
        selectedDayViews.append(unwrappedDayView)
      }
      
      day.day += 1
    }
    
    day.day -= 1
    day = day.date!.nwCalendarView_dayWithCalendar(day.calendar!)
    changeMonthIfNeeded(dayView.day!, toDay: day)
    monthContentViewDelegate?.didSelectDate(dayView.day!, toDate: day)
  }
  
  func clearSelectedDays() {
    if selectedDayViews.count > 0 {
      for dayView in selectedDayViews {
        dayView.isSelected = false
      }
    }
  }
  
  func changeMonthIfNeeded(fromDay: NSDateComponents, toDay: NSDateComponents) {
    
    if fromDay.month < currentMonthView.month.month {
      prevMonth()
    } else if fromDay.month > currentMonthView.month.month {
      nextMonth()
    } else if fromDay.month != toDay.month {
      println("not equal")
    }
  }

}