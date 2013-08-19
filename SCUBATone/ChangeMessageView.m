//
//  ChangeMessageView.m
//  SCUBATone
//
//  Created by Jonah Rubin on 8/16/13.
//  Copyright (c) 2013 #scubahack. All rights reserved.
//

#import "ChangeMessageView.h"
#import "ViewController.h"

@implementation ChangeMessageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        savebutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [savebutton addTarget:self
                                action:@selector(save)
                      forControlEvents:UIControlEventTouchUpInside];
        [savebutton setTitle:@"Done" forState:UIControlStateNormal];
        savebutton.frame = CGRectMake(170.0, 510.0, 160.0, 40.0);
        [self addSubview:savebutton];
        
        cancelbutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancelbutton addTarget:self
                       action:@selector(back)
             forControlEvents:UIControlEventTouchUpInside];
        [cancelbutton setTitle:@"Cancel" forState:UIControlStateNormal];
        cancelbutton.frame = CGRectMake(400.0, 510.0, 160.0, 40.0);
        [self addSubview:cancelbutton];
        
        UILabel *titlelabel = [[UILabel alloc] initWithFrame:CGRectMake(200, 10, 340, 70)];
        titlelabel.text=@"Change Messages";
        [titlelabel setFont:[UIFont fontWithName:@"Arial" size:40]];
        [self addSubview:titlelabel];
        
        [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"reef.jpg"]]];
        
        for (int i = 0; i<messages.count/2; i++) {
            UITextField *textfield = [[UITextField alloc] initWithFrame:CGRectMake(30.0, i*50.0+100.0, 300.0, 30.0)];
            textfield.borderStyle = UITextBorderStyleRoundedRect;
            textfield.text = [messages objectAtIndex:i];
            textfield.tag = i+1;
            [self addSubview:textfield];
        }
        for (int j = 0; j<messages.count/2; j++) {
            int i = j+messages.count/2;
            UITextField *textfield = [[UITextField alloc] initWithFrame:CGRectMake(400.0, j*50.0+100.0, 300.0, 30.0)];
            textfield.borderStyle = UITextBorderStyleRoundedRect;
            textfield.text = [messages objectAtIndex:i];
            textfield.tag = i+1;
            [self addSubview:textfield];
        }
        
        
    }
    return self;
}

-(void) setsubMessages: (NSArray*) supermessages{
    messages = supermessages;
}

-(void) save{
    NSMutableArray *mutarray = [[NSMutableArray alloc] init];
    for (int i = 0; i < messages.count; i++) {
        UITextField *tf = [self viewWithTag:i+1];
        NSString *string = tf.text;
        [mutarray insertObject:string atIndex:i];
    }
    messages = [NSArray arrayWithArray:mutarray];
    [(ViewController*)[self viewController] getNewMessages];
    [[NSUserDefaults standardUserDefaults] setObject:messages forKey:@"messages"];
    [self back];
}


-(void) back{

    [self removeFromSuperview];
}

-(NSArray*) getMessages{
    return messages;
}



- (UIViewController*)viewController
{
    for (UIView* next = [self superview]; next; next = next.superview)
    {
        UIResponder* nextResponder = [next nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
        {
            return (UIViewController*)nextResponder;
        }
    }
    
    return nil;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
