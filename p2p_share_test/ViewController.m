//
//  ViewController.m
//  p2p_share_test
//
//  Created by Paul Kovalenko on 06.02.14.
//  Copyright (c) 2014 Paul Kovalenko. All rights reserved.
//

#import "ViewController.h"
#import "GoogleTTS.h"

enum ShareType {
    ShareTypeImage = 0
};

@interface ViewController ()
{
    enum ShareType _shareType;
    
    __weak IBOutlet UITextField *_peerNameTextField;
    
    __weak IBOutlet UIButton *_createPeerButton;
    __weak IBOutlet UIButton *_browseDevicesButton;
    
    __weak IBOutlet UIButton *_shareImageButton;
    __weak IBOutlet UIButton *_shareTextButton;
    __weak IBOutlet UIButton *_shareAudioButton;
    __weak IBOutlet UIButton *_shareStringsArrayButton;
    
    __weak IBOutlet UIButton *_streamAudioButton;
    
    __weak IBOutlet UIButton *_pushUserButton;
    
    UIImageView *_receivedImageView;
    
    MCPeerID *_peerID;
    MCSession *_peerSession;
    MCAdvertiserAssistant *_peerAdvertiserAssistant;
    
    UIImage *_recievedImage;
    
    GoogleTTS *_tts;
    AVAudioPlayer *_player;
    AVAudioPlayer *_beepPlayer;
}

- (IBAction) createPeerButtonTouchUpInside:(id)sender;
- (IBAction) browseDevicesButtonTouchUpInside:(id)sender;
- (IBAction) shareImageButtonTouchUpInside:(id)sender;
- (IBAction) shareTextButtonTouchUpInside:(id)sender;
- (IBAction) shareAudioButtonTouchUpInside:(id)sender;
- (IBAction) shareArrayButtonTouchUpInside:(id)sender;

- (IBAction) streamAudioButtonTouchUpInside:(id)sender;

- (IBAction) pushUserAirDropButtonTouchUpInside:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tts = [[GoogleTTS alloc] init];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_peerSession.connectedPeers. count > 0) [self setButtonsEnable:YES];
    else [self setButtonsEnable:NO];
}

- (UIImage*)rescaleImage:(UIImage*)image toSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (NSURL *) fileToURL:(NSString*)filename
{
    NSArray *fileComponents = [filename componentsSeparatedByString:@"."];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[fileComponents objectAtIndex:0] ofType:[fileComponents objectAtIndex:1]];
    
    return [NSURL fileURLWithPath:filePath];
}

- (void) setButtonsEnable:(BOOL)enable
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_shareImageButton setEnabled:enable];
        [_shareTextButton setEnabled:enable];
        [_shareAudioButton setEnabled:enable];
        [_shareStringsArrayButton setEnabled:enable];
        [_streamAudioButton setEnabled:enable];
    });
}

#pragma mark - alertView

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 22222) {
        _receivedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 150, 220, 220)];
        [_receivedImageView setImage:_recievedImage];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeUIImageViewFromScreen)];
        [tap setNumberOfTapsRequired:1];
        [self.view addSubview:_receivedImageView];
        [self.view addGestureRecognizer:tap];
    }
    else if (alertView.tag == 44444) {
        _beepPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"beep" withExtension:@"mp3"] error:nil];
        
        [_beepPlayer setVolume:1];
    
        [_beepPlayer play];
    }
    else {
        [_peerNameTextField becomeFirstResponder];
    }
}

#pragma mark - Multipeer

+ (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
        case 0x89:
            return @"image";
        case 'T':
            return @"text";
        case 'I':
            return @"audio";
        case 'b':
            return @"array";
    }
    return nil;
}
    
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state != MCSessionStateConnected || session.connectedPeers.count == 0) {
        [self setButtonsEnable:NO];
    }
    else [self setButtonsEnable:YES];
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSString *type =  [ViewController contentTypeForImageData:data];
    
    NSString *voiceString;
    
    if ([type isEqualToString:@"image"]) {
        _recievedImage = [[UIImage alloc] initWithData:data];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Would you like to view an image?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            alert.tag = 22222;
            [alert show];
        });

        voiceString = @"You have received an image, would you like to view it?";
    }
    else if ([type isEqualToString:@"text"]) {
        voiceString = @"You have received text";
        
        NSString *stringFromData = [NSString stringWithCString:[data bytes] encoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:nil message:stringFromData delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
        });
    }
    else if ([type isEqualToString:@"audio"]) {
        //audio
        
        NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"beep.mp3"]];
        [data writeToFile:databasePath atomically:YES];
        
        voiceString = @"You have received a beep sound, would you like to check it?";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:voiceString delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            alert.tag = 44444;
            [alert show];
        });
    }
    else if ([type isEqualToString:@"array"]) {
//        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        voiceString = @"You have received a array";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:nil message:voiceString delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tts convertTextToSpeech:voiceString withCompletion:^(NSMutableData *data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _player = [[AVAudioPlayer alloc] initWithData:data error:nil];
                [_player setDelegate:self];
                [_player play];
            });
        }];
    });
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - MCBrowserViewControllerDelegate methods
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:NULL];
    NSLog(@"%@", _peerSession.connectedPeers);
    if (_peerSession.connectedPeers.count == 0) [self setButtonsEnable:NO];
    else [self setButtonsEnable:YES];
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:^{
        [self setButtonsEnable:YES];
    }];
}

#pragma mark - UIImagePickerControllerDelegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *photo = info[UIImagePickerControllerOriginalImage];
    UIImage *smallerPhoto = [self rescaleImage:photo toSize:CGSizeMake(800, 800)];
    NSData *data = UIImageJPEGRepresentation(smallerPhoto, 0.2);
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSError *error = nil;
        [_peerSession sendData:data toPeers:[_peerSession connectedPeers] withMode:MCSessionSendDataReliable error:&error];
    }];
}

#pragma mark - actions

- (void) removeUIImageViewFromScreen
{
    [_receivedImageView removeFromSuperview];
}

- (IBAction) createPeerButtonTouchUpInside:(id)sender
{
    [_peerNameTextField resignFirstResponder];
    if (_peerNameTextField.text.length > 0) {
        if (_peerID) _peerID = nil;
        if (_peerSession) _peerSession = nil;
        if (_peerAdvertiserAssistant) _peerAdvertiserAssistant = nil;
        
        _peerID = [[MCPeerID alloc] initWithDisplayName:_peerNameTextField.text];
        _peerSession = [[MCSession alloc] initWithPeer:_peerID];
        _peerSession.delegate = self;
        _peerAdvertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:@"shinobi-stream" discoveryInfo:nil session:_peerSession];
        _peerAdvertiserAssistant.delegate = self;
        
        [_peerAdvertiserAssistant start];
        
        [_browseDevicesButton setEnabled:YES];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Peer name" message:@"Peer name should not be empty" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
    }
}

- (IBAction) browseDevicesButtonTouchUpInside:(id)sender
{
    MCBrowserViewController *browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"shinobi-stream" session:_peerSession];
    browserVC.delegate = self;
    [self presentViewController:browserVC animated:YES completion:NULL];
}

- (IBAction) shareImageButtonTouchUpInside:(id)sender
{
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

- (IBAction) shareTextButtonTouchUpInside:(id)sender
{
    NSString *string = @"Text for share";
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
   
    NSError *error;
    [_peerSession sendData:data toPeers:[_peerSession connectedPeers] withMode:MCSessionSendDataReliable error:&error];
}

- (IBAction) shareAudioButtonTouchUpInside:(id)sender
{
    NSURL *imgPath = [[NSBundle mainBundle] URLForResource:@"beep" withExtension:@"mp3"];
    NSString*stringPath = [imgPath absoluteString];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringPath]];
 
    NSError *error;
    [_peerSession sendData:data toPeers:[_peerSession connectedPeers] withMode:MCSessionSendDataReliable error:&error];
}

- (IBAction) shareArrayButtonTouchUpInside:(id)sender
{
    NSArray *array = [NSArray arrayWithObjects:
                      @"1111", @"2222", @"3333", @"4444", @"5555",
                      @"6666", @"7777", @"8888", @"9999", @"0000",
                      nil];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
    
    NSError *error;
    [_peerSession sendData:data toPeers:[_peerSession connectedPeers] withMode:MCSessionSendDataReliable error:&error];
}

- (IBAction) streamAudioButtonTouchUpInside:(id)sender
{
    NSURL *imgPath = [[NSBundle mainBundle] URLForResource:@"beep" withExtension:@"mp3"];
    NSString*stringPath = [imgPath absoluteString];
    
    NSError *error;
    [_peerSession startStreamWithName:stringPath toPeer:[[_peerSession connectedPeers] objectAtIndex:0] error:&error];
}

- (IBAction) pushUserAirDropButtonTouchUpInside:(id)sender
{
    NSURL *url = [self fileToURL:@"PostScript.ps"];
    NSArray *objectsToShare = @[url];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    NSArray *excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                                    UIActivityTypePostToWeibo,
                                    UIActivityTypeMessage, UIActivityTypeMail,
                                    UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
    controller.excludedActivityTypes = excludedActivities;
    
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
