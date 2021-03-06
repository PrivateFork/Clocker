//
//  CLTableViewDataSource.h
//  Clocker
//
//  Created by Abhishek Banthia on 7/25/16.
//
//

#import <Foundation/Foundation.h>

@interface CLTableViewDataSource : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (assign) NSInteger futureSliderValue;
@property (strong) NSMutableArray *timezoneObjects;

- (instancetype)initWithItems:(NSArray *)objects;

@end
