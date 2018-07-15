inline bool GetPrefBool(NSString *key)
{
	return [[prefsDict valueForKey:key] boolValue];
}

NSString *prefsString(NSString *key) {
	return [[prefsDict objectForKey:key] stringValue];
}

int file_exist(const char *filename) {
	struct stat buffer;
	int r = stat(filename, &buffer);
	return (r == 0);
}

void clearFile(NSString *path) {
	FILE *f = fopen([path UTF8String], "w");
	fprintf(f, "");
	fclose(f);
}

//a few methods that will be used frequently
//parsin' json ain't easy ya know what i'm sayin'?
NSString *removeStr(NSString *mainString, NSString *toRemove) {
	return [mainString stringByReplacingOccurrencesOfString:toRemove withString:@""];
}

NSString *replaceStr(NSString *mainString, NSString *toReplace, NSString *with) {
	return [mainString stringByReplacingOccurrencesOfString:toReplace withString:with];
}

NSString *removeStrings(NSString *mainString, NSArray<NSString *> *toRemove) {
	for(NSString *string in toRemove) {
		mainString = [mainString stringByReplacingOccurrencesOfString:string withString:@""];
	}
	return mainString;
}

NSString *stringBetweenStrings(NSString *data, NSString *leftData, NSString *rightData) {
	NSInteger leftPos = [leftData length];
	NSInteger left;
	NSInteger right;
	NSString *foundData;
	NSScanner *scanner=[NSScanner scannerWithString:data];
	[scanner scanUpToString:leftData intoString: nil];
	left = [scanner scanLocation];
	[scanner setScanLocation:left + leftPos];
	[scanner scanUpToString:rightData intoString: nil];
	right = [scanner scanLocation] + 1;
	left += leftPos;
	foundData = [data substringWithRange: NSMakeRange(left, (right - left) - 1)];
	return foundData;
}


NSString *quoteFromSourceOne() {
	//abuse my key as much as you like
	NSString *apiKey = @"nice try sparky, no key here";

	//we have to make sure no quotes are cached
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://andruxnet-random-famous-quotes.p.mashape.com/"]
										   		cachePolicy:NSURLRequestReloadIgnoringCacheData
									    		 timeoutInterval:60.0];

	//we need to add the API key to the request
	[request setValue:apiKey forHTTPHeaderField:@"X-Mashape-Key"];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];

	NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	//this will return JSON, which we need to parse
	/*
	Example:
	[{"quote":"I'm king of the world!","author":"Titanic","category":"Movies"}]
	*/

	//quickly remove what we don't need using the function removeStrings()
	NSString *parsedJSON = removeStrings(html, @[@"[{", @"}]", @"\"", @",author", @",category"]);

	NSMutableArray *segments = [[parsedJSON componentsSeparatedByString:@":"] mutableCopy];
	[segments removeObjectAtIndex:0];
	[segments removeObject:[segments lastObject]];

	//now we just need to rearrange the strings to make a nice, formatted quote
	NSString *bodyWithQuoteMarks = [NSString stringWithFormat:@"“%@”", segments[0]];
	NSString *finalQuote = [NSString stringWithFormat:@"%@ - %@", bodyWithQuoteMarks, segments[1]];
	return finalQuote;
}

NSString *quoteFromSourceTwo() {
	//this one doesn't need a key
	//http://quotesondesign.com/wp-json/posts?filter[orderby]=rand&filter[posts_per_page]=1
	//we don't need to fill the parameters
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://quotesondesign.com/wp-json/posts?filter[orderby]=rand&filter[posts_per_page]=1"]
										   cachePolicy:NSURLRequestReloadIgnoringCacheData
									    timeoutInterval:60.0];

	//skip the request modification

	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
	NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	/*
	Example format:
	[{"ID":495,"title":"Fiel Valdez","content":"<p>Every practice has a set of rules which governs it. Mastery occurs with the realization of these rules. Innovation occurs at the point of intelligent and creative rebellion against them.  <\/p>\n","link":"https:\/\/quotesondesign.com\/fiel-valdez\/"}]
	*/
	//these quotes have codes for certain punctuation

	//starts at ","content":"<p>
	//ends at <\/p>\n",

	//max will be 170 chars

	//“ - &#8220;
	//” - &#8221;

	//we have to add in a few backslashes in order to keep the strings correct
	NSString *author = stringBetweenStrings(html, @",\"title\":\"", @"\",\"conten");
	NSString *body = stringBetweenStrings(html, @"\",\"content\":\"<p>", @"<\\\/p>\\n\",");
	NSString *almostNiceQuote = [NSString stringWithFormat:@"“%@” - %@", body, author];

	//replace the HTML entities
	almostNiceQuote = replaceStr(almostNiceQuote, @"&#8217;", @"'");
	almostNiceQuote = replaceStr(almostNiceQuote, @"\\u2019", @"'");
	almostNiceQuote = replaceStr(almostNiceQuote, @"\u2013", @"-");
	almostNiceQuote = replaceStr(almostNiceQuote, @"\u2014", @"-");
	almostNiceQuote = replaceStr(almostNiceQuote, @"&#8220;", @"“");
	almostNiceQuote = replaceStr(almostNiceQuote, @"&#8221;", @"”");
	almostNiceQuote = replaceStr(almostNiceQuote, @"&#8230;", @"…");
	NSString *niceQuote = replaceStr(almostNiceQuote, @"   ", @" ");
	return niceQuote;

}

//source three is great, but the quotes are longer than saurik's reddit comments
NSString *quoteFromSourceThree() {

	//we have to make sure no quotes are cached
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://talaikis.com/api/quotes/random/"]
												cachePolicy:NSURLRequestReloadIgnoringCacheData
											 timeoutInterval:60.0];

	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];

	NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	//quickly remove what we don't need using the function removeStrings()
	NSString *parsedJSON = removeStrings(html, @[@"{", @"}", @"\"", @",\"author\"", @",\"cat\""]);

	//split it into segments, of which we know the index of the body and author
	//remove the crap first
	NSMutableArray *segments = [[parsedJSON componentsSeparatedByString:@":"] mutableCopy];
	[segments removeObjectAtIndex:0];
	[segments removeObject:[segments lastObject]];

	//now we just need to rearrange the strings to make a nice, formatted quote
	NSString *bodyWithQuoteMarks = [NSString stringWithFormat:@"“%@”", segments[0]];
	NSString *finalQuote = [NSString stringWithFormat:@"%@ - %@", bodyWithQuoteMarks, segments[1]];
	finalQuote = removeStr(finalQuote, @",author");
	finalQuote = removeStr(finalQuote, @",cat");
	return finalQuote;
}

NSString *quoteUnderLimit(int limit) {
	NSString *goodOne = nil;
	NSLog(@"Character limit, you failed me!");
	//goodOne will only not be nil when a good string has been found
	while (!goodOne) {
		NSArray<NSString *> *quotes = @[quoteFromSourceOne(), quoteFromSourceTwo(), quoteFromSourceThree()];
		for(NSString *string in quotes) {
			if(!([string length] > limit) && ![string isEqualToString:@"/var/mobile/.recentlyused.txt"]) {
				goodOne = string;
			} else {
				continue;
			}
		}
	}
	if([goodOne isEqualToString:@"/var/mobile/.recentlyused.txt"]) {
		NSLog(@"Saved from the dreaded path bug");
		return quoteFromSourceOne(); //generally the shortest of the three
	}
	return goodOne;

}

UIColor *lighterColor(UIColor *orig) {
	CGFloat h, s, b, a;
	if ([orig getHue:&h saturation:&s brightness:&b alpha:&a]) {
		return [UIColor colorWithHue:h
				   	saturation:s
				   	brightness:/*MIN(b * 1.3,*/ 1.0//)
				   	   	alpha:a];
	}
	NSLog(@"Couldn't brighten colour: HSB values could not be established.");
	return nil;
}

BOOL isDark(UIColor *color) {
	size_t count = CGColorGetNumberOfComponents(color.CGColor);
	const CGFloat *componentColors = CGColorGetComponents(color.CGColor);

	CGFloat darknessScore = 0;
	if (count == 2) {
		darknessScore = (((componentColors[0]*255) * 299) + ((componentColors[0]*255) * 587) + ((componentColors[0]*255) * 114)) / 1000;
	} else if (count == 4) {
		darknessScore = (((componentColors[0]*255) * 299) + ((componentColors[1]*255) * 587) + ((componentColors[2]*255) * 114)) / 1000;
	}

	if (darknessScore >= 125) {
		return NO;
	}

	return YES;
}

NSString *deviceNameQuote() {
	return [NSString stringWithFormat:@"No internet - %@", [[UIDevice currentDevice] name]];
}

void writeToFile(NSString *path, NSString *string) {
	FILE *f = fopen([path UTF8String], "w");
	fprintf(f, [string UTF8String]);
	fclose(f);
}
