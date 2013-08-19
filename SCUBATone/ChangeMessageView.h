//
//  ChangeMessageView.h
//  SCUBATone
//
//  Created by Jonah Rubin on 8/16/13.
//  Copyright (c) 2013 #scubahack. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ChangeMessageView : UIView
{
    UIButton *savebutton;
    UIButton *cancelbutton;

    
    @public
    NSArray *messages;
    
}

-(void) setsubMessages: (NSArray*) supermessages;
-(NSArray*) getMessages;

@end
