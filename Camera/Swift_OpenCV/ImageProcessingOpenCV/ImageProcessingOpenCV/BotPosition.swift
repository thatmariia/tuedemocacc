//
//  BotPosition.swift
//  ImageProcessingOpenCV
//
//  Created by Mariia Turchina on 30/05/2019.
//  Copyright © 2019 Mariia Turchina. All rights reserved.
//

import Foundation

class BotPosition {
    
    var intersectionDist : Int
    var quadrant : Int
    var speed : Int
    var closest : Bool
    var connected : Bool
    
    init() {
        self.intersectionDist = 100000
        self.quadrant = -1
        self.speed = 0
        self.closest = false
        self.connected = false
    }
    
    init(intersectionDist : Int, quadrant : Int){
        self.intersectionDist = intersectionDist
        self.quadrant = quadrant
        self.speed = 0
        self.closest = false
        self.connected = false
    }
}
