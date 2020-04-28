
#import "OpenCVCam.h"
#import "UIImage+OpenCV.h"
#import "color.h"
#include "Bot.h"

#define PI 3.1415926535

using namespace cv;
using namespace std;

@implementation OpenCVCam

cv::Point intersection = cv::Point(0, 0);

cv::Point quadrants[4] = {cv::Point(0, 0), cv::Point(0, 0), cv::Point(0, 0), cv::Point(0, 0)};


Color redl("redl",
           Scalar(0, 100, 100),
           Scalar(3, 255, 255));

Color redh("redh",
           Scalar(160, 100, 100),
           Scalar(179, 255, 255));

Color green("green",
            Scalar(65, 100,50),
            Scalar(79,255,255));

Color purple("purple",
             Scalar(110, 50, 100),
             Scalar(140, 255, 255));

//Color pink("pink",
//           Scalar(165, 25, 25),
//           Scalar(175, 255, 255));

Color pink("pink",
           Scalar(255, 255, 255),
           Scalar(0,0,0));


Color blue("blue",
           Scalar(100, 150, 100),
           Scalar(140, 255, 255));

Color yellow("yellow",
             Scalar(20, 100, 100),
             Scalar(30, 255, 255));

Color orange("orange",
             Scalar(5, 50, 100),
             Scalar(20, 255, 255));

Color whiteColor("white",
            Scalar(0, 0, 215),
            Scalar(180, 100, 255));

vector<Color> colors;

+ (id)sharedInstance {
    static OpenCVCam *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance initCam];
    });
    return instance;
}

- (id) init
{
    colors = {yellow, purple, blue, green, pink, orange};
    return self;
}

- (void) start
{
    [self.cam start];
}

- (void) stop
{
    [self.cam stop];
}

- (void) initCam
{
    self.cam = [[CvVideoCamera alloc] init];
    
    self.cam.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.cam.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.cam.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.cam.defaultFPS = 30;
    self.cam.grayscaleMode = NO;
    self.cam.delegate = self;
}

- (vector<Vec3f>) findColouredCirclesFrom:(cv::Mat &) mat color:(Color)color  {
    Mat hsv;
    Mat mask;
    
    cvtColor(mat, hsv, COLOR_BGR2HSV);
    
    // Detect red area in frame
    inRange(hsv, color.low, color.high, mask);
    
    erode(mask, mask, getStructuringElement(MORPH_ELLIPSE, cv::Size(5,5)));
    dilate(mask, mask, getStructuringElement(MORPH_ELLIPSE, cv::Size(5,5)));
    
    // Blur for accuracy
    GaussianBlur(mask, mask, cv::Size(9, 9), 2, 2);
    threshold(mask, mask, 127, 225, THRESH_BINARY);
    
    return [self findCirclesFrom:mask minThres:14];
}

- (vector<Vec3f>) findCirclesFrom:(cv::Mat &)mat minThres:(int)minThres{
    int diameter = mat.cols;
    
    // Create a vector for detected circles
    vector<Vec3f>  circles;
    
    // Apply Hough Transform
    HoughCircles(mat, circles, HOUGH_GRADIENT, 1
                 , diameter / 8, // min distance
                 100, minThres,  10, diameter/8); //blueRadius*0.1
    
    // Draw detected circles
    for(size_t i=0; i<circles.size(); i++) {
        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
        int radius = cvRound(circles[i][2]);
        // Fill circles for the mask
        circle(mat, center, radius, Scalar(255, 72, 255), -1);
    }
    return circles;
}

- (void)ensureInFrame:(cv::Mat &)image rectroi:(cv::Rect &)rectroi {
    // Going up
    if ( rectroi.y < 0 ){
        rectroi.height -= abs(rectroi.y);
        rectroi.y = 0;
    }
    // Going down
    if (( rectroi.y + rectroi.height) > image.rows){
        rectroi.height -= abs(rectroi.y + rectroi.height - image.rows);
    }
    // Going right
    if (( rectroi.x + rectroi.width) > image.cols){
        rectroi.width -= abs( rectroi.x + rectroi.width - image.cols);
    }
    // Going left
    if ( rectroi.x < 0){
        rectroi.width -= abs(rectroi.x);
        rectroi.x = 0;
    }
}


- (void)composeBotsInfo:(vector<Bot> &)bots {
    for (int i = 0; i < bots.size(); i++){
        //bots[i].x *= scale;
        //bots[i].y *= scale;
        float yDist = intersection.y - bots[i].y;
        float xDist = intersection.x - bots[i].x;
        bots[i].intersectionDist = int( sqrt( pow(yDist, 2) + pow(xDist, 2) ));
        
        int minDist = 100000;
        
        //cout << "for " << bots[i].name << endl;
        for (int j = 0; j < 4; j++){
            float yqDist = quadrants[j].y - bots[i].y;
            float xqDist = quadrants[j].x - bots[i].x;
            float qDistance = sqrt( pow(yqDist, 2) + pow(xqDist, 2) );
            //cout << "qDist " << j << " : " << qDistance << endl;
            if (qDistance < minDist){
                minDist = qDistance;
                bots[i].quadrant = j + 1;
            }
            
        }
    }
}


bool compareContourAreas ( std::vector<cv::Point> contour1, std::vector<cv::Point> contour2 ) {
    double i = fabs( contourArea(cv::Mat(contour1)) );
    double j = fabs( contourArea(cv::Mat(contour2)) );
    return ( i > j );
}

bool computeField(Mat &image, RotatedRect &rect, Mat &premask) {
    dilate(premask, premask, getStructuringElement(MORPH_ELLIPSE, cv::Size(10,10)));
    
    Mat hsv, white, mask;
    cvtColor(image, hsv, COLOR_BGR2HSV);
    
    inRange(hsv, whiteColor.low, whiteColor.high, white);
    bitwise_or(white, premask, mask);
    mask.copyTo(white);
    
    dilate(white, white, getStructuringElement(MORPH_ELLIPSE, cv::Size(5,5)));
    
    vector<vector<cv::Point>> contours;
    Mat hierarchy;
    findContours(white, contours, hierarchy, RETR_CCOMP, CHAIN_APPROX_SIMPLE);
    drawContours(image, contours, -1, Scalar(0,0,255), 10);
    
    if(contours.size() <= 0) {
        return false;
    }
    
    std::sort(contours.begin(), contours.end(), compareContourAreas);
    auto cnt = contours.at(0);
    auto rotatedRect = cv::minAreaRect(cnt);
    
    if(rotatedRect.size.area() < 0.5 * image.size().area()) {
        return false;
    }
    
    rect = rotatedRect;
    
    // optional drawing
    cv::Point2f vertices[4];
    rotatedRect.points(vertices);
    //cv::Scalar contoursColor(255, 255, 255);
    cv::Scalar rectangleColor(255, 0, 0);
    
    cv::drawContours(image, contours, 0, Scalar(0,255,0), 1, 8, hierarchy, 100);
    
    //Draw rotatedRect
    for (int i = 0; i < 4; i++) {
        cv::line(image, vertices[i], vertices[(i + 1) % 4], rectangleColor, 2, cv::LINE_AA, 0);
    }
    
    //cv::line(image, vertices[0], vertices[(0 + 1) % 4], Scalar(255,0,0), 2, cv::LINE_AA, 0);
    //cv::line(image, vertices[1], vertices[(1 + 1) % 4], Scalar(0,255,0), 2, cv::LINE_AA, 0);
    //cv::line(image, vertices[2], vertices[(2 + 1) % 4], Scalar(0,0,255), 2, cv::LINE_AA, 0);
    //cv::line(image, vertices[3], vertices[(3 + 1) % 4], Scalar(0,0,0), 2, cv::LINE_AA, 0);
    
    
    return true;
}

void testColorSetup(Mat &image, Scalar low, Scalar high ) {
    Mat hsv;
    Mat mask;
    
    cvtColor(image, hsv, COLOR_BGR2HSV);
    
    // Detect red area in frame
    inRange(hsv, low, high, mask);
    
    // Blur for accuracy
    GaussianBlur(mask, mask, cv::Size(9, 9), 2, 2);
    threshold(mask, mask, 127, 225, THRESH_BINARY);
    
    // Apply new mask to image
    cv::Mat frame;
    bitwise_or(image, image, frame, mask);
    
    frame.copyTo(image);
}

bool distanceToOrigen(const cv::Point& lhs, const cv::Point& rhs)
{
    auto ldis = sqrt(pow((lhs.y),2) + pow((lhs.x),2));
    auto rdis = sqrt(pow((rhs.y),2) + pow((rhs.x),2));
    return ldis < rdis;
}

bool compareCircleSize(const cv::Vec3f& lhs, const cv::Vec3f& rhs)
{
    return lhs[2] < rhs[2];
}

void fieldCalculation (RotatedRect &field, Mat &img) {
    
    intersection = field.center;
    
    //cout << "INTERSECTION = " << intersection.x << "   " << intersection.y << endl;
    
    cv::Point2f vertices[4];
    field.points(vertices);
    
    
    
    
    
    cv::Point v1 = vertices[0]; // red - red
    cv::Point v2 = vertices[3]; // white - white
    cv::Point v3 = vertices[1]; // green - green
    cv::Point v4 = vertices[2]; // blue - blue
    std::vector<cv::Point> points = {v1,v2,v3,v4};
    
    
    
    
    //std::sort(points.begin(), points.end(), distanceToOrigen);
    //v1 = points.at(0);
    
    /*cv::circle(img, v1, 10, Scalar(255,0,0), -1);
     cv::circle(img, v2, 10, Scalar(0,255,0), -1);
     cv::circle(img, v3, 10, Scalar(0,0,255), -1);
     cv::circle(img, v4, 10, Scalar(255,255,255), -1);*/
    
    cv::circle(img, v1, 10, Scalar(255,0,0), -1);
    cv::circle(img, v2, 10, Scalar(255,255,255), -1);
    cv::circle(img, v3, 10, Scalar(0,255,0), -1);
    cv::circle(img, v4, 10, Scalar(0,0,255), -1);
    
    //cout << "V1 " << v1.x << " " << v1.y << endl;
    //cout << "V2 " << v2.x << " " << v2.y << endl;
    //cout << "V3 " << v3.x << " " << v3.y << endl;
    //cout << "V4 " << v4.x << " " << v4.y << endl;
    
    float dxAB = (float) abs(v1.x - v2.x);
    float dyAB = (float) abs(v1.y - v2.y);
    float rad2 = sqrt( pow(dxAB,2) + pow(dyAB,2) );
    float sinA = dyAB / rad2;
    float sinB = sqrt( 1 - pow(sinA,2) );
    float rad = rad2 / 2;
    //cout << "sinB = " << sinB << endl;
    
    //cout << "rad = " << rad << "    width = " << field.size.width << endl;
    //cout << "angle = " << asin(sinA)*180/PI << "     field angle = " << field.angle << endl;
    float dyMap = rad * sinB;
    //cout << "dyMap = " << dyMap << endl;
    float dxMap = sqrt( pow(rad,2) - pow(dyMap,2) );
    //cout << "dxMap = " << dxMap << endl;
    
    if (dxMap > dyMap){
        swap(dxMap, dyMap);
    }
    
     quadrants[3].x = v1.x + dxMap/2;
     quadrants[3].y = v1.y - dyMap/2;
     //cout << "q1 = ( " << quadrants[0].x << ", " << quadrants[0].y << " )" << endl;
     //cout << "v1 = ( " << v1.x << ", " << v1.y << " )" << endl;
     
     quadrants[1].x = v2.x - dxMap/2;
     quadrants[1].y = v2.y + dyMap/2;
     //cout << "q2 = ( " << quadrants[1].x << ", " << quadrants[1].y << " )" << endl;
     //cout << "v2 = ( " << v2.x << ", " << v2.y << " )" << endl;
     
     quadrants[2].x = v3.x + dxMap/2;
     quadrants[2].y = v3.y - dyMap/2;
     //cout << "q3 = ( " << quadrants[2].x << ", " << quadrants[2].y << " )" << endl;
     //cout << "v3 = ( " << v3.x << ", " << v3.y << " )" << endl;
     
     quadrants[0].x = v4.x - dxMap/2;
     quadrants[0].y = v4.y + dyMap/2;
     //cout << "q4 = ( " << quadrants[3].x << ", " << quadrants[3].y << " )" << endl;
     //cout << "v4 = ( " << v4.x << ", " << v4.y << " )" << endl;
    
    //cout << "********************************" << endl;
    
    cv::circle(img, quadrants[0], 20, Scalar(255,0,0), -1);
    cv::circle(img, quadrants[1], 20, Scalar(255,255,255), -1);
    cv::circle(img, quadrants[2], 20, Scalar(0,255,0), -1);
    cv::circle(img, quadrants[3], 20, Scalar(0,0,255), -1);
}



- (void) processImage : (cv::Mat &) image
{
    /*
    Scalar testl(0, 0, 220);
    Scalar testh(180, 100, 255);

    testColorSetup(image, testl, testh);
    //testColorSetup(image, pink.low, pink.high);
    
    erode(image, image, getStructuringElement(MORPH_ELLIPSE, cv::Size(5,5)));
    dilate(image, image, getStructuringElement(MORPH_ELLIPSE, cv::Size(10,10)));

    
    cvtColor(image, image, COLOR_BGR2RGB);
    [self.delegate imageProcessed:[UIImage imageWithCVMat: image]];
    return;
    */
     

    //cvtColor(image, image, COLOR_BGR2RGB);
    //[self.delegate imageProcessed:[UIImage imageWithCVMat: image]];
    //return;
    
    // Declare color mats and masks
    Mat hsv;
    Mat redmask, redmasklow, redmaskhigh;
    
    cvtColor(image, hsv, COLOR_BGR2HSV);
    
    // Detect red area in frame
    inRange(hsv, redl.low, redl.high,  redmasklow);
    inRange(hsv, redh.low, redh.high, redmaskhigh);
    
    addWeighted(redmasklow, 1.0, redmaskhigh, 1.0, 0.0, redmask);
    
    // Blur for accuracy
    GaussianBlur(redmask, redmask, cv::Size(9, 9), 2, 2);
    threshold(redmask, redmask, 127, 225, THRESH_BINARY);
    
    // Detect red circles
    [self findCirclesFrom:redmask minThres:16];
    
    // Apply new mask to image
    cv::Mat redframe;
    bitwise_or(image, image, redframe, redmask);
    
    // Find field
    RotatedRect field;
    if(computeField(image, field, redmask)) {
        // Calcu
        fieldCalculation(field, image);
    }
    
    // Bot detection
    vector<Bot> bots;
    
    for(auto color : colors) {
        vector<Vec3f> circles = [self findColouredCirclesFrom:redframe color:color];
        //std::cout << circles.size() << std::endl;
        if(circles.size() > 0) {
            std::sort(circles.begin(), circles.end(), compareCircleSize);
            
            auto c = circles.at(circles.size() - 1);
            rectangle(image, cv::Point(c[0]-c[2], c[1]-c[2]), cv::Point(c[0]+c[2],c[1]+c[2]), Scalar(255,100,0), 10);
            auto font = FONT_HERSHEY_SIMPLEX;
            putText(image,color.name, cv::Point(c[0],c[1]), font, 1, Scalar(255,255,255), 2, LINE_AA);
            
            bots.push_back(Bot(color.name, c[0], c[1]));
            //std::cout << color.name << std::endl;
        }
    }
    
    // at this point i have coordinates of q1 and q4
    
    // calculate q2 and q3
    // calculate the line points for quadrants
    // @TODO TBD

    
    [self composeBotsInfo:bots];
    
    for (int i = 0; i < bots.size(); i++){
        //cout << "name " << bots[i].name << " , quad = " << bots[i].quadrant << endl;
     }
    // Send bots info via bluetooth
    std::string cppString = "";
    if (bots.size() > 0) {
        for (int i = 0; i < bots.size(); i++){
            cppString += bots[i].name;
            cppString += ":";
            cppString += to_string(bots[i].intersectionDist);
            cppString += ":";
            cppString += to_string(bots[i].quadrant);
            if (i < bots.size()) {
                cppString += ";";
            }
        }
    } else {
        cppString = "noinfo";
    }
    
    // Debug
    /*for(auto bot : bots) {
     cout << bot.name << endl;
     cout << bot.x << endl;
     cout << bot.y << endl;
     }*/
    
    // Convert c++ string to objective-c NSString. Then fire to UI and BT controller
    NSString *objcMessage = [NSString stringWithCString:cppString.c_str()
                                               encoding:[NSString defaultCStringEncoding]];;
    
    // Fire events
    
    /*for (int i = 0; i < bots.size(); i++){
     cout << bots[i].name << endl;
     cout << "P = ( " << bots[i].x << ", " << bots[i].y << " )" << endl;
     cout << "intersection dist = " << bots[i].intersectionDist << endl;
     cout << "quadrant = " << bots[i].quadrant << endl;
     cout << "________________________________________________________" << endl;
     }*/
    
    if (self.delegate != nil) {
        [self.delegate botUpdate:objcMessage];
        cvtColor(image,image, COLOR_BGR2RGB);
        [self.delegate imageProcessed:[UIImage imageWithCVMat: image]];
    }
}

@end
