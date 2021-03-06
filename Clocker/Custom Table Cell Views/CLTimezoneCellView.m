//
//  CLTimezoneCellView.m
//  Clocker
//
//  Created by Abhishek Banthia on 12/13/15.
//
//

#import "CLTimezoneCellView.h"
#import "PanelController.h"
#import "CommonStrings.h"
#import "CLTimezoneData.h"
#import "CLFloatingWindowController.h"
#import <Crashlytics/Crashlytics.h>

#define MIN_FONT_SIZE 13

@implementation CLTimezoneCellView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    // Drawing code here.
}

- (IBAction)labelDidChange:(NSTextField *)sender
{
    NSTextField *customLabelCell = (NSTextField*) sender;
    
    PanelController *panelController;
    CLFloatingWindowController *floatingWindow;
    
    NSNumber *displayMode = [[NSUserDefaults standardUserDefaults] objectForKey:CLShowAppInForeground];
    
    
    if (displayMode.integerValue == 0)
    {
        panelController = [PanelController getPanelControllerInstance];
    }
    else if (displayMode.integerValue == 1)
    {
        floatingWindow = [CLFloatingWindowController sharedFloatingWindow];
    }

    
    NSString *originalValue = customLabelCell.stringValue;
    NSString *customLabelValue = [originalValue stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
    
    
    if ([sender.superview isKindOfClass:[self class]])
    {
        CLTimezoneCellView *cellView = (CLTimezoneCellView *)sender.superview;
        
        /*
         
         Fix for http://crashes.to/s/f43ce0accd0
         
         More stringent null check for array values.
         
         */
        
        if (panelController.defaultPreferences == nil && floatingWindow.defaultPreferences == nil)
        {
            return;
        }
        
        NSData *dataObject = displayMode.integerValue == 0 ? panelController.defaultPreferences[cellView.rowNumber] : floatingWindow.defaultPreferences[cellView.rowNumber];
        CLTimezoneData *timezoneObject = [CLTimezoneData getCustomObject:dataObject];
        
        [Answers logCustomEventWithName:@"Custom Label Changed" customAttributes:@{@"Old Label" : timezoneObject.customLabel , @"New Label" : customLabelValue}];
        
        if (displayMode.integerValue == 0)
        {
            
            [panelController.defaultPreferences enumerateObjectsUsingBlock:^(id  _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
                
                CLTimezoneData *timeObject = [CLTimezoneData getCustomObject:object];
                if ([timeObject.formattedAddress isEqualToString:customLabelValue]) {
                    [timeObject setLabelForTimezone:CLEmptyString];
                }
            }];
        }
        else if (displayMode.integerValue == 1)
        {
            [floatingWindow.defaultPreferences enumerateObjectsUsingBlock:^(id  _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
                
                CLTimezoneData *timeObject = [CLTimezoneData getCustomObject:object];
                if ([timeObject.formattedAddress isEqualToString:customLabelValue]) {
                     [timeObject setLabelForTimezone:CLEmptyString];
                }
            }];
        }
 
        [timezoneObject setLabelForTimezone:customLabelValue];
        
        if ([timezoneObject.isFavourite isEqualToNumber:@1])
        {
            NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:timezoneObject];
            [[NSUserDefaults standardUserDefaults] setObject:encodedObject
                                                      forKey:@"favouriteTimezone"];
        }

        NSData *newObject = [NSKeyedArchiver archivedDataWithRootObject:timezoneObject];
        
        if (displayMode.integerValue == 0)
        {
            (panelController.defaultPreferences)[cellView.rowNumber] = newObject;
            [[NSUserDefaults standardUserDefaults] setObject:panelController.defaultPreferences forKey:CLDefaultPreferenceKey];
            [panelController updateDefaultPreferences];
            [panelController updateTableContent];
        }
        else if(displayMode.integerValue == 1)
        {
            (floatingWindow.defaultPreferences)[cellView.rowNumber] = newObject;
            [[NSUserDefaults standardUserDefaults] setObject:floatingWindow.defaultPreferences forKey:CLDefaultPreferenceKey];
            [floatingWindow updateDefaultPreferences];
            [floatingWindow updateTableContent];
        }
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:CLCustomLabelChangedNotification
         object:nil];
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    [self.window endEditingFor:nil];
}

- (void)setTextColor:(NSColor *)color
{
    self.relativeDate.textColor = color;
    self.customName.textColor = color;
    self.time.textColor = color;
    self.sunriseSetTime.textColor = color;
}

- (void)setUpLayout
{
    CGFloat width = [self.relativeDate.stringValue
                     sizeWithAttributes: @{NSFontAttributeName:self.relativeDate.font}].width;
    CGFloat sunriseWidth = [self.sunriseSetTime.stringValue
                     sizeWithAttributes: @{NSFontAttributeName:self.sunriseSetTime.font}].width;
    
    [self.relativeDate.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        if (constraint.constant > 20)
        {
            constraint.constant = width+8;
        }
    }];
    
    [self.sunriseSetTime.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([constraint.identifier isEqualToString:@"width"])
        {
            constraint.constant = sunriseWidth+3;
        }
    }];
    
    [self.relativeDate setNeedsUpdateConstraints:YES];
    [self.sunriseSetTime setNeedsUpdateConstraints:YES];
    
    [self setUpTheme];
    
}

- (void)setUpTheme
{
    
    NSNumber *theme = [[NSUserDefaults standardUserDefaults] objectForKey:CLThemeKey];
    
    if (theme.integerValue == 1)
    {
        [self setTextColor:[NSColor whiteColor]];
        self.customName.drawsBackground = YES;
        self.customName.backgroundColor = [NSColor blackColor];
    }
    else
    {
        self.customName.drawsBackground = YES;
        self.customName.backgroundColor = [NSColor whiteColor];
        [self setTextColor:[NSColor blackColor]];
    }

    [self setUpTextSize];
}

- (void)setUpTextSize
{
    NSNumber *userFontSize = [[NSUserDefaults standardUserDefaults] objectForKey:CLUserFontSizePreference];
    NSInteger newFontSize = MIN_FONT_SIZE + (userFontSize.integerValue*2);
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *customPlaceFont = [fontManager convertFont:self.customName.font toSize:newFontSize];
    NSFont *customTimeFont = [fontManager convertFont:self.time.font toSize:MIN_FONT_SIZE + (userFontSize.integerValue*3)];
    [self.customName setFont:customPlaceFont];
    [self.time setFont:customTimeFont];
    CGFloat timeHeight = [self.time.stringValue
                            sizeWithAttributes: @{NSFontAttributeName:self.time.font}].height;
    CGFloat timeWidth = [self.time.stringValue
                          sizeWithAttributes: @{NSFontAttributeName:self.time.font}].width;
    [self.time.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        if([constraint.identifier isEqualToString:@"height"])
        {
            constraint.constant = timeHeight;
        }
        else
        {
            constraint.constant = timeWidth;
        }
    }];
}


- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    CLFloatingWindowController *windowController = [CLFloatingWindowController sharedFloatingWindow];
    
    [windowController.floatingWindowTimer start];
}

@end
