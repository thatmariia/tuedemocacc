//
//  OpenCVCamDelegate.h
//  ImageProcessingOpenCV
//
//  Created by Mariia Turchina on 23/05/2019.
//  Copyright © 2019 Mariia Turchina. All rights reserved.
//

#ifndef OpenCVCamDelegate_h
#define OpenCVCamDelegate_h

@protocol OpenCVCamDelegate <NSObject>
- (void) imageProcessed: (UIImage*) image;
- (void) botUpdate: (NSString*) message;
@end

#endif /* OpenCVCamDelegate_h */
