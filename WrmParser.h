//
//  WmaParser.h
//  MediaParser
//
//  Created by Jakob Hilarius Nielsen on 9/16/11.
//  Copyright 2011 NA. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WRM_CHUNK_GUID {0x14,0xe6,0x8a, 0x29,0x22,0x26,0x17,0x4c,0xb9,0x35,0xda,0xe0,0x7e,0xe9,0x28,0x9c}

@interface WrmParser : NSObject <NSXMLParserDelegate> {
@public
    NSString *wrmVersion;
    NSString *cid; // Content id
    NSString *kid;
    NSString *securityVersion;
    NSString *laInfo; // Licence acquisition info
    NSString *checksum;
    NSString *hashAlgorithm;
    NSString *signAlgorithm;
    NSString *signatureValue;
@private
    NSString *currentElement;
}

-(id)initWithFile:(NSString*) filename;
-(id)initWithStream:(NSInputStream*) is;
-(id)initWithData:(NSData*) data;

-(NSString *)wmId;

@property(nonatomic, retain) NSString *wrmVersion;
@property(nonatomic, retain) NSString *cid;
@property(nonatomic, retain) NSString *kid;
@property(nonatomic, retain) NSString *securityVersion;
@property(nonatomic, retain) NSString *laInfo;
@property(nonatomic, retain) NSString *checksum;
@property(nonatomic, retain) NSString *hashAlgorithm;
@property(nonatomic, retain) NSString *signAlgorithm;
@property(nonatomic, retain) NSString *signatureValue;

@end
