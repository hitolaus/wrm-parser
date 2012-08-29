/**
 * Extracts and parses the WRM header data from ASF 1.0 files
 *
 * <WRMHEADER version="2.0.0.0">
 *  <DATA>
 *      <SECURITYVERSION>2.2</SECURITYVERSION>
 *      <CID>WMID:246083143</CID>
 *      <LAINFO>http://...</LAINFO>
 *      <KID>...</KID>
 *      <CHECKSUM>...</CHECKSUM>
 *  </DATA>
 *  <SIGNATURE>
 *      <HASHALGORITHM type="SHA"></HASHALGORITHM>
 *      <SIGNALGORITHM type="MSDRM"></SIGNALGORITHM>
 *      <VALUE>...</VALUE>
 *  </SIGNATURE>
 * </WRMHEADER>
 *
 * @author Jakob Hilarius Nielsen
 */
#import "WrmParser.h"

@interface WrmParser ()
-(NSData*)readData:(NSInputStream*) is bytes:(NSInteger)numberOfBytes;
-(NSNumber*)readNumber:(NSInputStream*) is bytes:(NSInteger)numberOfBytes;

-(NSData*)extractWrmHeader: (NSInputStream*) is;
-(void)parseWrmHeader: (NSData*)xml;

@property(nonatomic, retain) NSString *currentElement;
@end

@implementation WrmParser

@synthesize wrmVersion, cid, kid, securityVersion, laInfo, checksum;
@synthesize hashAlgorithm, signAlgorithm, signatureValue;

@synthesize currentElement;

-(id)initWithFile:(NSString*) filename
{
    self = [super init];
    if (self) {
        NSInputStream *is = [[NSInputStream alloc] initWithFileAtPath:filename];
        [is open];

        [self initWithStream:is];
        
        [is close];
        [is release];
    }
    
    return self;
}

-(id)initWithData:(NSData*) data
{
    self = [super init];
    if (self) {
        NSInputStream *is = [[NSInputStream alloc] initWithData:data];
        [is open];
        
        [self initWithStream:is];
        
        [is close];
        [is release];
    }
    
    return self;   
}

-(id)initWithStream:(NSInputStream*) is;
{
    self = [super init];
    if (self) {
        NSData* wrmHeader = [self extractWrmHeader:is];
        
        [self parseWrmHeader:wrmHeader];
    }
    
    return self;
}

-(void)dealloc
{
    self.wrmVersion = nil;
    self.cid = nil;
    self.kid = nil;
    self.securityVersion = nil;
    self.laInfo = nil;
    self.checksum = nil;
    self.hashAlgorithm = nil;
    self.signAlgorithm = nil;
    self.signatureValue = nil;
    
    self.currentElement = nil;
    
    [super dealloc];
}

/**
 * Returns the Windows Media id which is contained in the content id
 * CID = WMID:foobar -> foobar
 *
 * @return The Windows Media id or nil if the WM id cannot be found.
 */
-(NSString*) wmId
{
    NSArray *components = [cid componentsSeparatedByString:@":"];
    
    if ([components count] != 2) {
        return nil;
    }
    
    if (![[components objectAtIndex:0] isEqualToString:@"WMID"]) {
        return nil;
    }
    
    return [components objectAtIndex:1];
}

-(void)parseWrmHeader: (NSData*)xml
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xml];
	[parser setDelegate:self];
	[parser parse];
	[parser release];
}

/**
 * Finds the WRM header in ASF file header.
 *
 * @param is InputStream
 * @return The WRM header XML strip
 */
-(NSData*)extractWrmHeader: (NSInputStream*) is
{
    NSData *data;
    
    /* File header chunk:
     * -16 bytes: Chunk type
     * -8 bytes: Chunk length
     * -4 bytes: Number of subchunks
     * -2 bytes: Unknown
     * -x bytes: Chunks
     */
    NSData *type = [self readData:is bytes:16];
    NSNumber *length = [self readNumber:is bytes:8];

    long numberOfSubChunks = [[self readNumber:is bytes:4] longValue];
    
    [self readData:is bytes:2]; // Not used
    
    while (numberOfSubChunks > 0) {
        /* General chunk:
         * -16 bytes: Chunk type
         * -8 bytes: Chunk length
         * -x bytes: Data
         */
        type = [self readData:is bytes:16];
        length = [self readNumber:is bytes:8];
        
        uint8_t tmp[] = WRM_CHUNK_GUID;
        NSData *wrmChunkGuid = [NSData dataWithBytes:tmp length:16];

        // 24 bytes since we have already read chunk type (16 bytes)
        // and chunk length (8 bytes)
        data = [self readData:is bytes:[length integerValue]-24];
        
        if ([type isEqualToData:wrmChunkGuid]) {
            // The WRM header starts at an offset from the chunk data
            int offset = 6;
            int len = (int)[data length]/2-offset;
            
            const char *dataBytes = [data bytes];
            char xml[len];
            
            for (int i = offset, j = 0; i < [data length]; i = i + 2, j++) {
                xml[j] = dataBytes[i];
            }

            return [NSData dataWithBytes:xml length:len];
        }
        
        numberOfSubChunks--;
    }
    return nil;
}

#pragma mark -
#pragma mark Read methods

/**
 * Reads x number of bytes from the input stream and returns 
 * the data as an NSData object.
 * 
 * @param is InputStream
 * @param numberOfBytes The number of bytes to read
 * @return Data as an NSData object. The size may be less than
 *         numberOfBytes if the data stream ends.
 */
-(NSData*)readData:(NSInputStream*) is bytes:(NSInteger)numberOfBytes
{
    NSData *data = nil;
    
    if ([is hasBytesAvailable]) {
        uint8_t buf[numberOfBytes];
        
        [is read:buf maxLength:numberOfBytes];
        
        data = [NSData dataWithBytes:buf 
                              length:numberOfBytes];
    }
    
    return data;
}

/**
 * Reads x number of bytes from the input stream and returns 
 * the data as an NSNumber object.
 *
 * The data is converted to a number in reverse byte order i.e
 * 0x00 0x01 0x00 0x00 will return 256.
 * 
 * @param is InputStream
 * @param numberOfBytes The number of bytes to read
 * @return Data converted to a number
 */
-(NSNumber*)readNumber:(NSInputStream*) is bytes:(NSInteger)numberOfBytes {
    NSData *data = [self readData:is bytes:numberOfBytes];

    uint8_t *buf = (uint8_t*)[data bytes];

    long number = 0;
    for (int i = 0; i < (int)numberOfBytes; i++) {
        int factor = i << 8;
        if (factor == 0) factor = 1;
        
        number += buf[i]*factor;
    }
    
    return [NSNumber numberWithLong:number];
}


#pragma mark -
#pragma mark NSXMLParser delegate methods

-(void)     parser:(NSXMLParser *)parser 
   didStartElement:(NSString *)elementName 
      namespaceURI:(NSString *)namespaceURI 
     qualifiedName:(NSString *)qName 
        attributes:(NSDictionary *)attributeDict
{
    elementName = [elementName lowercaseString];
    
    NSEnumerator *enumerator = [attributeDict keyEnumerator];
    id key;
    
    while ((key = [enumerator nextObject])) {   
        key = [key lowercaseString];
        
        NSString *value = [attributeDict valueForKey:key];
        
        if ([key isEqualToString:@"type"] && [elementName isEqualToString:@"hashalgorithm"]) {
            self.hashAlgorithm = value;
        }
        else if ([key isEqualToString:@"type"] && [elementName isEqualToString:@"signalgorithm"]) {
            self.signAlgorithm = value;
        }
        else if ([key isEqualToString:@"version"] && [elementName isEqualToString:@"wrmheader"]) {
            self.wrmVersion = value;
        }
    }
    
    self.currentElement = elementName;
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)value
{
    self.currentElement = [currentElement lowercaseString];
    
    if ([currentElement isEqualToString:@"cid"]) {
        self.cid = value;
    }
    else if ([currentElement isEqualToString:@"kid"]) {
        self.kid = value;        
    }
    else if ([currentElement isEqualToString:@"securityversion"]) {
        self.securityVersion = value ;
    }
    else if ([currentElement isEqualToString:@"lainfo"]) {
        self.laInfo = value;
    }
    else if ([currentElement isEqualToString:@"checksum"]) {
        self.checksum = value;
    }
    else if ([currentElement isEqualToString:@"value"]) {
        self.signatureValue = value;
    }
}

@end
