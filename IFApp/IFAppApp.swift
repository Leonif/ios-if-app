//
//  IFAppApp.swift
//  IFApp
//
//  Created by Leonid-user on 30.10.2024.
//

import SwiftUI

@main
struct IFAppApp: App {
    var body: some Scene {
        WindowGroup {
            TimerView()
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                    NotificationManager.shared.scheduleDailyNoonNotification()
                    NotificationManager.shared.scheduleDailyEveningNotification()
                }
        }
    }
}
