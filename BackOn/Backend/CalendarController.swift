//
//  CalendarController.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 03/03/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import EventKit

class Calendar {
    static let controller = Calendar()
    private let eventStore = EKEventStore()
    private var calendar: EKCalendar?
    private var status = AuthState.notDetermined
    
    enum AuthState {
        case notDetermined
        case denied
        case authorized
    }
    
    private init() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            status = .authorized
            initCalendar()
        case .denied:
            status = .denied
        default:
            break
        }
    }
    
    private func initCalendar() {
        let calendars = eventStore.calendars(for: .event)
        for calendar in calendars {
            if calendar.title == "BackOn Tasks" {
                self.calendar = calendar
            }
        }
        if calendar == nil {
            calendar = EKCalendar(for: .event, eventStore: eventStore)
            calendar!.title = "BackOn Tasks"
            calendar!.source = eventStore.defaultCalendarForNewEvents?.source
            do {
                try eventStore.saveCalendar(calendar!, commit: true)
            } catch {print("Error adding calendar!\n", error.localizedDescription)}
        }
    }
    
    func requestPermission() {
        if status == .notDetermined {
            eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    print("Calendar access granted")
                    self.status = .authorized
                    self.initCalendar()
                } else {
                    print("Calendar access denied")
                    self.status = .denied
                }
            }
        }
    }
    
    func addTask(_ task: Task) {
        let _ = addEvent(title: "Help \(task.needer.name) with \(task.title)", startDate: task.date, notes: task.id)
    }
    
    func addRequest(_ request: Request) {
        let _ = addEvent(title: "You requested help with \(request.title)", startDate: request.date, notes: request.id)
    }
    
    func remove<Element:Need>(_ need: Element) -> Bool {
        guard status == .authorized else {print("You don't have the permission to access the calendar!"); return false}
        let predicate = eventStore.predicateForEvents(withStart: need.date, end: need.date.addingTimeInterval(120), calendars: [calendar!])
        let events = eventStore.events(matching: predicate)
        for event in events {
            print(event)
            if let note = event.notes, note == need.id {
                do {
                    try eventStore.remove(event, span: .thisEvent)
                    return true
                } catch {print("Error while removing the event from the calendar"); return false}
            }
        }
        print("No event matching the needID")
        return false
    }
    
    func addEvent(title: String, startDate: Date, endDate: Date? = nil, relativeAlarmTime: TimeInterval = -60, notes: String? = nil) -> Bool {
        guard status == .authorized else {print("You don't have the permission to access the calendar!"); return false}
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate ?? startDate
        event.notes = notes
        event.addAlarm(EKAlarm(relativeOffset: relativeAlarmTime))
        event.calendar = calendar!
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {print(error.localizedDescription); return false}
    }
    
    func isBusy(when date: Date) -> Bool { //controlla che non ho impegni in [data-10min:data+10min]
        guard status == .authorized else {print("You don't have the permission to access the calendar!"); return false}
        let predicate = eventStore.predicateForEvents(withStart: date.addingTimeInterval(-600), end: date.addingTimeInterval(600), calendars: nil)
        let events = eventStore.events(matching: predicate)
        guard !events.isEmpty else { return false }
        for event in events {
            if !event.isAllDay {
                return true
            }
        }
        return false
    }
}
