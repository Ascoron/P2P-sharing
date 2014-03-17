//
//  NSStream+Data.m
//  p2p_share_test
//
//  Created by Paul Kovalenko on 06.03.14.
//  Copyright (c) 2014 Paul Kovalenko. All rights reserved.
//

#import "NSStream+Data.h"

@implementation NSStream (Data)

- (UInt32)writeData:(uint8_t *)data maxLength:(UInt32)maxLength
{
    return (UInt32)[(NSOutputStream *)self write:data maxLength:maxLength];
}

- (UInt32)readData:(uint8_t *)data maxLength:(UInt32)maxLength
{
    return (UInt32)[(NSInputStream *)self read:data maxLength:maxLength];
}

@end
