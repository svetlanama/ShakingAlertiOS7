//
//  ShakingAlertView.m
//
//  Created by Luke on 21/09/2012.
//  Copyright (c) 2012 Luke Stringer. All rights reserved.
//
//  https://github.com/stringer630/ShakingAlertView
//

//  This code is distributed under the terms and conditions of the MIT license.
//
//  Copyright (c) 2012 Luke Stringer
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "ShakingAlertView.h"
#include <CommonCrypto/CommonDigest.h>
#import "NSData+Base64.h"
#import "AppDelegate.h"



@interface ShakingAlertView ()
// Private property as other instances shouldn't interact with this directly
{
    NSString *secondMessage; NSString *secondMessageNew;
    NSString *thirdMessage;
}
@end

// Enum for alert view button index
typedef enum {
    ShakingAlertViewButtonIndexDismiss = 0,
    ShakingAlertViewButtonIndexSuccess = 10
} ShakingAlertViewButtonIndex;

@implementation ShakingAlertView

@synthesize passwordDelegate;
#pragma mark - Constructors

- (id)initWithAlertTitle:(NSString *)title
        checkForPassword:(NSString *)password{
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        self.alertViewStyle = UIAlertViewStylePlainTextInput;
    }
    self = [super initWithTitle:title
                        message:@"" // password field will go here
                       delegate:self
              cancelButtonTitle:@"Cancel"
              otherButtonTitles:@"Enter", nil];
    if (self) {
        self.password = password;
        self.hashTechnique = HashTechniqueNone; // use no hashing by default
        secondMessage = @"Please Enter New Password";
        thirdMessage = @"Please Re-Enter Password";
        secondMessageNew = @"Please Enter Password";
    }
    
    NSLog(@" _password_ %@",_password);
    NSLog(@"_old_password_ %@",[[NSUserDefaults standardUserDefaults] objectForKey:kPassword]);
    
    return self;
}

- (id)initWithAlertTitle:(NSString *)title
        checkForPassword:(NSString *)password
       onCorrectPassword:(void(^)())correctPasswordBlock
onDismissalWithoutPassword:(void(^)())dismissalWithoutPasswordBlock {
    
    self = [self initWithAlertTitle:title checkForPassword:password];
    if (self) {
        self.onCorrectPassword = correctPasswordBlock;
        self.onDismissalWithoutPassword = dismissalWithoutPasswordBlock;
    }
    
    
    return self;
    
}

- (id)initWithAlertTitle:(NSString *)title
        checkForPassword:(NSString *)password
   usingHashingTechnique:(HashTechnique)hashingTechnique {
    
    self = [self initWithAlertTitle:title checkForPassword:password];
    if (self) {
        self.hashTechnique = hashingTechnique;
    }
    return self;
    
}

- (id)initWithAlertTitle:(NSString *)title
        checkForPassword:(NSString *)password
   usingHashingTechnique:(HashTechnique)hashingTechnique
       onCorrectPassword:(void(^)())correctPasswordBlock
onDismissalWithoutPassword:(void(^)())dismissalWithoutPasswordBlock {
    
    self = [self initWithAlertTitle:title checkForPassword:password usingHashingTechnique:hashingTechnique];
    if (self) {
        self.onCorrectPassword = correctPasswordBlock;
        self.onDismissalWithoutPassword = dismissalWithoutPasswordBlock;
    }
    
    
    return self;
    
}

// Override show method to add the password field
- (void)show {
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        
        UITextField *passwordField = [self textFieldAtIndex:0];
        passwordField.delegate = self;
        self.passwordField = passwordField;
    }
    else{
        UITextField *passwordField = [[UITextField alloc] initWithFrame:CGRectMake(14, 45, 256, 25)];
        passwordField.secureTextEntry = YES;
        passwordField.placeholder = @"";
        passwordField.backgroundColor = [UIColor whiteColor];
        
        
        
        // Pad out the left side of the view to properly inset the text
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 6, 19)];
        passwordField.leftView = paddingView;
        passwordField.leftViewMode = UITextFieldViewModeAlways;
        
        //    // Set delegate
        self.passwordField.delegate = self;
        
        // Set as property
        
        self.passwordField = passwordField;
        // Add to subview
        [self addSubview:_passwordField];
    }
    
    
    // Show alert
    [super show];
    
    //
    //    // present keyboard for text entry
    // [_passwordField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.1];
    
}

- (void)animateIncorrectPassword {
    // Clear the password field
    _passwordField.text = nil;
    
    // Animate the alert to show that the entered string was wrong
    // "Shakes" similar to OS X login screen
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
    }
    else{
        CGAffineTransform moveRight = CGAffineTransformTranslate(CGAffineTransformIdentity, 20, 0);
        CGAffineTransform moveLeft = CGAffineTransformTranslate(CGAffineTransformIdentity, -20, 0);
        CGAffineTransform resetTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 0);
        
        [UIView animateWithDuration:0.1 animations:^{
            // Translate left
            self.transform = moveLeft;
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.1 animations:^{
                
                // Translate right
                self.transform = moveRight;
                
                
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:0.1 animations:^{
                    
                    // Translate left
                    self.transform = moveLeft;
                    
                } completion:^(BOOL finished) {
                    
                    [UIView animateWithDuration:0.1 animations:^{
                        
                        // Translate to origin
                        self.transform = resetTransform;
                    }];
                }];
                
            }];
        }];
    }
    
    
    if ([self.passwordDelegate respondsToSelector:@selector(notifyParent::)]) {
        [self.passwordDelegate notifyParent:self.title:self.password];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        UITextField *passwordField = [self textFieldAtIndex:0];
        self.passwordField = passwordField;
    }
    
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        
        if ([self enteredTextIsCorrect] || [self.title isEqualToString:secondMessage] || [self.title isEqualToString:secondMessageNew]) {
            
            if (([self.title isEqualToString:secondMessage] || [self.title isEqualToString:secondMessageNew]) && (self.passwordField.text.length > 0)) {
                self.password = self.passwordField.text;
                self.title = thirdMessage;
                self.passwordField.text = @"";
                
                if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
                {
                    if ([self.passwordDelegate respondsToSelector:@selector(notifyParent::)]) {
                        [self.passwordDelegate notifyParent:thirdMessage:self.password];
                    }
                }
            }else
            {
                if ([self.title isEqualToString:thirdMessage]) {
                    [[NSUserDefaults standardUserDefaults] setObject:self.password forKey:kPassword];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    if (self.passwordDelegate) {
                        if ([self.passwordDelegate respondsToSelector:@selector(notifyParentWithState:)]) {
                            [self.passwordDelegate notifyParentWithState:YES];
                        }
                    }
                }else{
                    if ([self.title isEqualToString:secondMessageNew]) {
                        self.title = secondMessageNew;
                    }
                    else{
                        self.title = secondMessage;
                    }
                    
                    self.passwordField.text = @"";
                    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
                    {
                        if ([self.passwordDelegate respondsToSelector:@selector(notifyParent::)]) {
                            [self.passwordDelegate notifyParent:self.title:self.password];
                        }
                    }
                }
            }
        }
        
        // If incorrect then animate
        else {
            [self animateIncorrectPassword];
        }
    }
}


// Overide to customise when alert is dimsissed
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    
    // Only dismiss for ShakingAlertViewButtonIndexDismiss or ShakingAlertViewButtonIndexSuccess
    // This means we don't dissmis for the case where "Enter" button is pressed and password is incorrect
    //    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    //    {
    //    }
    //    else{
    //    switch (buttonIndex) {
    //        case ShakingAlertViewButtonIndexSuccess:
    //            [super dismissWithClickedButtonIndex:ShakingAlertViewButtonIndexDismiss animated:animated];
    //            [self safeCallBlock:self.onCorrectPassword];
    //            break;
    //        case ShakingAlertViewButtonIndexDismiss:
    //            [super dismissWithClickedButtonIndex:ShakingAlertViewButtonIndexDismiss animated:animated];
    //            [self safeCallBlock:self.onDismissalWithoutPassword];
    //            break;
    //        default:
    //            break;
    //    }
    //}
    
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"TODO_WORK_RETURN");
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        UITextField *passwordField = [self textFieldAtIndex:0];
        self.passwordField = passwordField;
    }
    
    if ([self enteredTextIsCorrect] || [self.title isEqualToString:secondMessage] || [self.title isEqualToString:secondMessageNew]) {
        
        if (([self.title isEqualToString:secondMessage] || [self.title isEqualToString:secondMessageNew]) && (self.passwordField.text.length > 0)) {
            self.password = self.passwordField.text;
            self.title = thirdMessage;
            self.passwordField.text = @"";
            
            if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
            {
                // call alert view 
                if ([self.passwordDelegate respondsToSelector:@selector(notifyParent::)]) {
                    [self.passwordDelegate notifyParent:thirdMessage:self.password];
                }
                [super dismissWithClickedButtonIndex:ShakingAlertViewButtonIndexSuccess animated:YES];
            }
        }else
        {
            if ([self.title isEqualToString:thirdMessage]) {
                [[NSUserDefaults standardUserDefaults] setObject:self.password forKey:kPassword];
                [[NSUserDefaults standardUserDefaults] synchronize];
                // Hide keyboard
                
                if (self.passwordDelegate) {
                    if ([self.passwordDelegate respondsToSelector:@selector(notifyParentWithState:)]) {
                        [self.passwordDelegate notifyParentWithState:YES];
                    }
                    [super dismissWithClickedButtonIndex:ShakingAlertViewButtonIndexSuccess animated:YES];
                }
                
            }else{
                if ([self.title isEqualToString:secondMessageNew]) {
                    self.title = secondMessageNew;
                }
                else{
                    self.title = secondMessage;
                }
                
                self.passwordField.text = @"";
                
                if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
                {
                    if ([self.passwordDelegate respondsToSelector:@selector(notifyParent::)]) {
                        [self.passwordDelegate notifyParent:self.title:self.password];
                    }
                    [super dismissWithClickedButtonIndex:ShakingAlertViewButtonIndexSuccess animated:YES];
                }
            }
        }
    }
    else {
        [self animateIncorrectPassword];
        [super dismissWithClickedButtonIndex:ShakingAlertViewButtonIndexSuccess animated:YES];
    }
    
    return NO;
}

#pragma mark - Private helpers
- (void)safeCallBlock:(void (^)(void))block {
    // Only call the block is not nil
    if (block) {
        block();
    }
}

- (BOOL)enteredTextIsCorrect {
    switch (_hashTechnique) {
            
            // No hashing algorithm used
        case HashTechniqueNone:
            return [_passwordField.text isEqualToString:_password];
            break;
            
            
            // SHA1 used
        case HashTechniqueSHA1: {
            
            unsigned char digest[CC_SHA1_DIGEST_LENGTH];
            NSData *stringBytes = [_passwordField.text dataUsingEncoding: NSUTF8StringEncoding];
            CC_SHA1([stringBytes bytes], [stringBytes length], digest);
            
            NSData *pwHashData = [[NSData alloc] initWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
            NSString *hashedEnteredPassword = [pwHashData base64EncodedString];
            
            return [hashedEnteredPassword isEqualToString:_password];
            
        }
            break;
            
            
            // MD5 used
        case HashTechniqueMD5: {
            
            unsigned char digest[CC_MD5_DIGEST_LENGTH];
            NSData *stringBytes = [_passwordField.text dataUsingEncoding: NSUTF8StringEncoding];
            CC_MD5([stringBytes bytes], [stringBytes length], digest);
            
            NSData *pwHashData = [[NSData alloc] initWithBytes:digest length:CC_MD5_DIGEST_LENGTH];
            NSString *hashedEnteredPassword = [pwHashData base64EncodedString];
            
            return [hashedEnteredPassword isEqualToString:_password];
            
        }
            break;
            
        default:
            break;
    }
    
    
    // To stop Xcode complaining return NO by default
    return NO;
    
}

#pragma mark - Memory Managment


@end
