//
//  ViewTicker.swift
//  DailyGoals
//
//  Created by harsh selarka on 22/11/2025.
//


import Foundation
import Combine

class ViewTicker: ObservableObject {
    @Published var tick = 0
    private var timer: AnyCancellable?

    init() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.tick += 1
            }
    }
}
