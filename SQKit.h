//
//  SQKit.h
//  Safemode
//
//  Created by Alex Gallon on 27/06/2018.
//  Copyright © 2018 Squ1dd13. All rights reserved.
//

#ifndef SQKit_h
#define SQKit_h

NSArray *arrayFromString(NSString *string){
    NSMutableArray *letters = [NSMutableArray array];
    for (int i = 0; i < [string length]; i++) {
        [letters addObject:[NSString stringWithFormat:@"%C", [string characterAtIndex:i]]];
    }
    return [letters copy];
}

NSArray *alphabetValuesFromString(NSString *string) {
    //this is the array equivalent of alphabet values, meaning A would be 0
    string = [string lowercaseString];
    NSMutableArray *indexes = [NSMutableArray array];
    NSArray *alphabet = arrayFromString(@"abcdefghijklmnopqrstuvwxyz");
    for(NSString *x in arrayFromString(string)) {
        NSUInteger index = [alphabet indexOfObject:x];
        [indexes addObject:@(index)];
    }
    return [indexes copy];
}

/**
 A function to shorten an array to a certain count, regardless of what is in it.
 Removes objects from the end of the array.
 **/
NSArray *arrayShortenedToCount(NSArray *array, NSUInteger count) {
    int arrayCount = 0;
    NSMutableArray *mutArray = [array mutableCopy];
    for(NSObject *object in array) {
        arrayCount += 1;
        if(arrayCount > count) {
            [mutArray removeObject:object];
        }
    }
    return [mutArray copy];
}

///Shortens a string to a certain length by removing letters from the end.
NSString *stringShortenedToLength(NSString *string, NSUInteger length) {
    NSArray *letters = arrayFromString(string);
    letters = arrayShortenedToCount(letters, length);
    return [letters componentsJoinedByString:@""];
}

NSString *translateString(NSString *string, NSArray *characterSet) {
    NSArray *alphabetValues = alphabetValuesFromString(string);
    
    NSMutableArray *translatedArray = [NSMutableArray array];
    for(NSNumber *value in alphabetValues) {
        NSString *translatedChar = [characterSet objectAtIndex:[value integerValue]];
        [translatedArray addObject:translatedChar];
    }
    //make a string from the array and return
    return [translatedArray componentsJoinedByString:@""];
}

NSInteger colorProfile;

struct pixel {
    unsigned char r, g, b, a;
};

BOOL enabled;
CGFloat alpha = 1.0;
static UIColor *dominantColorFromImage(UIImage *image) {
    CGImageRef iconCGImage = image.CGImage;
    NSUInteger red = 0, green = 0, blue = 0;
    size_t width = CGImageGetWidth(iconCGImage);
    size_t height = CGImageGetHeight(iconCGImage);
    size_t bitmapBytesPerRow = width * 4;
    size_t bitmapByteCount = bitmapBytesPerRow * height;
    struct pixel *pixels = (struct pixel *)malloc(bitmapByteCount);
    if (pixels) {
        CGContextRef context = CGBitmapContextCreate((void *)pixels, width, height, 8, bitmapBytesPerRow, CGImageGetColorSpace(iconCGImage), kCGImageAlphaPremultipliedLast);
        if (context) {
            CGContextDrawImage(context, CGRectMake(0.0, 0.0, width, height), iconCGImage);
            NSUInteger numberOfPixels = width * height;
            for (size_t i = 0; i < numberOfPixels; i++) {
                red += pixels[i].r;
                green += pixels[i].g;
                blue += pixels[i].b;
            }
            red /= numberOfPixels;
            green /= numberOfPixels;
            blue /= numberOfPixels;
            CGContextRelease(context);
        }
        free(pixels);
    }
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha];
}

UIColor *imageColor(UIImage *image) {
    UIColor *color = dominantColorFromImage(image);
    return color;
}

#endif /* SQKit_h */
