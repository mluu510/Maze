//
//  ViewController.m
//  Labyrinth
//
//  Created by Minh Luu on 4/26/14.
//  Copyright (c) 2014 Minh Luu. All rights reserved.
//

#import "ViewController.h"
#import "BallView.h"
#import "WallView.h"
#import <CoreMotion/CoreMotion.h>

@interface ViewController ()

@property (nonatomic, strong) CMMotionManager *motion;
@property (nonatomic, strong) BallView *ball;
@property (nonatomic) CGFloat xSpeed;
@property (nonatomic) CGFloat ySpeed;
@property (nonatomic, strong) NSDate *lastUpdate;

@property (nonatomic) CGPoint currentPoint;
@property (nonatomic) CGPoint previousPoint;
@property (nonatomic) CGFloat xVelocity;
@property (nonatomic) CGFloat yVelocity;

@property (nonatomic, strong) BallView *exit;
@property (nonatomic, strong) NSMutableArray *walls;

@end

@implementation ViewController

#define kUpdateInterval 1.0f/60.0f
#define kBallSize 30

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.walls = [@[] mutableCopy];    
    [self.walls addObjectsFromArray:self.view.subviews];
    
    self.lastUpdate = [NSDate date];
    
    // Make exit
    CGRect ballFrame = CGRectMake(0, 0, kBallSize, kBallSize);
    ballFrame.origin = CGPointMake(self.view.bounds.size.width * 0.9, self.view.bounds.size.height * 0.1);
    self.exit = [[BallView alloc] initWithFrame:ballFrame withColor:[UIColor blackColor]];
    [self.view addSubview:self.exit];
    
    // Create ball view

    ballFrame.origin = CGPointMake(10, self.view.bounds.size.height * 0.9);
    self.ball = [[BallView alloc] initWithFrame:ballFrame withColor:[UIColor redColor]];
    [self.view addSubview:self.ball];
    
    self.currentPoint = ballFrame.origin;
    
    // Create wall...

//    CGRect wallFrame = CGRectMake(100, 100, 100, 20);
//    UIView *wallView = [[UIView alloc] initWithFrame:wallFrame];
//    wallView.backgroundColor = [UIColor blueColor];
//    [self.walls addObject:wallView];
//    [self.view addSubview:wallView];
    
    
    // Initiate accelerometer
    self.motion = [[CMMotionManager alloc] init];
    self.motion.accelerometerUpdateInterval = kUpdateInterval;
    [self.motion startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        [self handleAcceleration:accelerometerData];
    }];
}

#define kScalingFactor 2000
#define kFriction 1.05

- (void)handleAcceleration:(CMAccelerometerData *)data
{
    NSTimeInterval timeSinceLastDraw = -[self.lastUpdate timeIntervalSinceNow];
    
    CGFloat x = data.acceleration.x;
    CGFloat y = data.acceleration.y;
//    CGFloat z = data.acceleration.z;
    
//    self.xLabel.text = [NSString stringWithFormat:@"x: %.2f", x];
//    self.yLabel.text = [NSString stringWithFormat:@"y: %.2f", y];
//    self.zLabel.text = [NSString stringWithFormat:@"z: %.2f", z];
    
    self.xVelocity = (self.xVelocity / kFriction) - (x * timeSinceLastDraw);
    self.yVelocity = (self.yVelocity / kFriction) - (y * timeSinceLastDraw);
    
    CGFloat dx = timeSinceLastDraw * self.xVelocity * kScalingFactor;
    CGFloat dy = timeSinceLastDraw * self.yVelocity * kScalingFactor;
    
    self.currentPoint = CGPointMake(self.currentPoint.x - dx,
                                    self.currentPoint.y + dy);
    
    [self moveBall];
    
    self.lastUpdate = [NSDate date];
}

- (void)moveBall
{
    [self collisionWithExit];
    [self collisionWithBoundaries];
    [self collsionWithWalls];
    self.previousPoint = self.currentPoint;
    
    CGRect frame = self.ball.frame;
    frame.origin = self.currentPoint;
    self.ball.frame = frame;

}

#define kReflectionFactor 2

- (void)collisionWithBoundaries {
    
    if (self.currentPoint.x < 0) {
        self.currentPoint = CGPointMake(0, self.currentPoint.y);
        self.xVelocity = -(self.xVelocity / kReflectionFactor);
    }
    
    if (self.currentPoint.y < 0) {
        self.currentPoint = CGPointMake(self.currentPoint.x, 0);
        self.yVelocity = -(self.yVelocity / kReflectionFactor);
    }
    
    if (self.currentPoint.x > self.view.bounds.size.width - self.ball.frame.size.width) {
        _currentPoint.x = self.view.bounds.size.width - self.ball.frame.size.width;
        self.xVelocity = -(self.xVelocity / kReflectionFactor);
    }
    
    if (self.currentPoint.y > self.view.bounds.size.height - self.ball.frame.size.height) {
        _currentPoint.y = self.view.bounds.size.height - self.ball.frame.size.height;
        self.yVelocity = -(self.yVelocity / kReflectionFactor);
    }
    
}

- (void)collisionWithExit {
    CGFloat xDist = self.exit.frame.origin.x - self.ball.frame.origin.x;
    CGFloat yDist = self.exit.frame.origin.y - self.ball.frame.origin.y;
    CGFloat distance = abs(sqrtf((xDist * xDist) + (yDist * yDist)));
    
//    NSLog(@"Distance: %f", distance);
    
    if (distance <= 10) {
        [self.motion stopAccelerometerUpdates];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You've won!" message:nil delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)collsionWithWalls {

    for (UIView *wall in self.walls) {
        if (CGRectIntersectsRect(self.ball.frame, wall.frame)) {
            CGPoint ballCenter = CGPointMake(self.ball.frame.origin.x + self.ball.frame.size.width/2,
                                             self.ball.frame.origin.y + self.ball.frame.size.height/2);
            
            if (self.ball.frame.origin.x <= wall.frame.origin.x) {
                _currentPoint.x = self.previousPoint.x - 1;
//                self.xVelocity = -(self.xVelocity / kReflectionFactor);
                self.xVelocity = 0;
            } else if (self.ball.frame.origin.x <= wall.frame.origin.x + wall.frame.size.width) {
                _currentPoint.x = self.previousPoint.x + 1;
//                self.xVelocity = -(self.xVelocity / kReflectionFactor);
                self.xVelocity = 0;
            }
            
            
            if (self.ball.frame.origin.y <= wall.frame.origin.y) {
                _currentPoint.y = self.previousPoint.y - 1;
//                self.yVelocity = -(self.yVelocity / kReflectionFactor);
                self.yVelocity = 0;
            } else if (self.ball.frame.origin.y <= wall.frame.origin.y + wall.frame.size.height) {
                _currentPoint.y = self.previousPoint.y + 1;
//                self.yVelocity = -(self.yVelocity / kReflectionFactor);
                self.yVelocity = 0;
            }
        }
        
    }
    
}

@end
