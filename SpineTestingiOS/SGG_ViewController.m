//
//  SGG_ViewController.m
//  SpineTestingiOS
//
//  Created by Michael Redig on 2/10/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_ViewController.h"
#import "SGG_MyScene.h"

@implementation SGG_ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
//    gameData = [REP_GameData sharedData];
	
}



-(void)viewWillLayoutSubviews {
	
    [super viewWillLayoutSubviews];
	
	
	
    // Configure the view.
    SKView* skView = (SKView*) self.view;
	if (!skView.scene){
		
		
			

        self.view.multipleTouchEnabled = NO;
        
        NSLog(@"scene size: %f %f", skView.bounds.size.width, skView.bounds.size.height);
        
		
        // Create and configure the scene.
		SKScene* scene = [SGG_MyScene sceneWithSize:CGSizeMake(320, 586)];
        
		//		NSLog(@"scene size is %f x %f", skView.bounds.size.width, skView.bounds.size.height);
		
        scene.scaleMode = SKSceneScaleModeAspectFill;
		
        
        // Present the scene.
        [skView presentScene:scene];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
