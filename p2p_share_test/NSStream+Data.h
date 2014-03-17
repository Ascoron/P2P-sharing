//
//  NSStream+Data.h
//  p2p_share_test
//
//  Created by Paul Kovalenko on 06.03.14.
//  Copyright (c) 2014 Paul Kovalenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSStream (Data)

- (UInt32)writeData:(uint8_t *)data maxLength:(UInt32)maxLength;

- (UInt32)readData:(uint8_t *)data maxLength:(UInt32)maxLength;

@end
