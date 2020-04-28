//
//  Bot.h
//  ImageProcessingOpenCV
//
//  Created by Mariia Turchina on 27/05/2019.
//  Copyright © 2019 Mariia Turchina. All rights reserved.
//

#ifndef Bot_h
#define Bot_h

#include <string>

class Bot {
public:
    std::string name;
    int x;
    int y;
    int quadrant;
    int intersectionDist;
    
    Bot(std::string name, int x, int y, int quadrant, int intersectionDist) {
        this->name = name;
        this->x = x;
        this->y = y;
        this->quadrant = quadrant;
        this->intersectionDist = intersectionDist;
    }
    
    Bot(std::string name, int x, int y) {
        this->name = name;
        this->x = x;
        this->y = y;
        this->quadrant = -1;
        this->intersectionDist = -1;
    }
};


#endif /* Bot_h */
