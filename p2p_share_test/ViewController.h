//
//  ViewController.h
//  p2p_share_test
//
//  Created by Paul Kovalenko on 06.02.14.
//  Copyright (c) 2014 Paul Kovalenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, AVAudioPlayerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCSessionDelegate, MCAdvertiserAssistantDelegate>

@end
