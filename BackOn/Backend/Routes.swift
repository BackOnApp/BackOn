//
//  Routes.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 28/03/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.

struct ServerRoutes {
    private static let baseURL = "https://serverlessbackon.now.sh/api"
    static let signUp = {baseURL+"/signin.js"}()
    static let getMyBonds = {baseURL+"/getMyBonds.js"}()
    static let removeTask = {baseURL+"/cancelTask.js"}()
    static let removeRequest = {baseURL+"/deleteRequest.js"}()
    static let discover = {baseURL+"/discover.js"}()
    static let addRequest = {baseURL+"/addRequest.js"}()
    static let addTask = {baseURL+"/addTask.js"}()
    static let reportTask = {baseURL+"/reportTask.js"}()
    static let updateProfile = {baseURL+"/updateProfile.js"}()
    static let sendNotification = {baseURL+"/sendPush.js"}()
}

//static let getUserByID = {baseURL+"/getUserByID.js"}()
//static let getBondByID = {baseURL+"/getBondByID.js"}()
//static let getMyTasks = {baseURL+"/getMyTasks.js"}()
//static let getMyRequests = {baseURL+"/getMyRequests.js"}()
