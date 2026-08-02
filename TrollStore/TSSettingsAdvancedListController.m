#import "TSSettingsAdvancedListController.h"
#import "TSUtil.h"
#import <Preferences/PSSpecifier.h>

extern NSUserDefaults* trollStoreUserDefaults();
@interface PSSpecifier ()
@property (nonatomic,retain) NSArray* values;
@end

@implementation TSSettingsAdvancedListController

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [NSMutableArray new];

		PSSpecifier* installationMethodGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		//installationMethodGroupSpecifier.name = @"Installation";
		[_specifiers addObject:installationMethodGroupSpecifier];

		PSSpecifier* installationMethodSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Installation Method"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSStaticTextCell
											edit:nil];
		[installationMethodSpecifier setProperty:@YES forKey:@"enabled"];
		installationMethodSpecifier.identifier = @"installationMethodLabel";
		[_specifiers addObject:installationMethodSpecifier];

		PSSpecifier* installationMethodSegmentSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Installation Method Segment"
											target:self
											set:@selector(setPreferenceValue:specifier:)
											get:@selector(readPreferenceValue:)
											detail:nil
											cell:PSSegmentCell
											edit:nil];
		[installationMethodSegmentSpecifier setProperty:@YES forKey:@"enabled"];
		installationMethodSegmentSpecifier.identifier = @"installationMethodSegment";
		[installationMethodSegmentSpecifier setProperty:APP_ID forKey:@"defaults"];
		[installationMethodSegmentSpecifier setProperty:@"installationMethod" forKey:@"key"];
		installationMethodSegmentSpecifier.values = @[@0, @1];
		installationMethodSegmentSpecifier.titleDictionary = @{@0 : @"installd", @1 : @"Custom"};
		[installationMethodSegmentSpecifier setProperty:@1 forKey:@"default"];
		[_specifiers addObject:installationMethodSegmentSpecifier];

		PSSpecifier* uninstallationMethodGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
		//uninstallationMethodGroupSpecifier.name = @"Uninstallation";
		[_specifiers addObject:uninstallationMethodGroupSpecifier];

		PSSpecifier* uninstallationMethodSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Uninstallation Method"
											target:self
											set:nil
											get:nil
											detail:nil
											cell:PSStaticTextCell
											edit:nil];
		[uninstallationMethodSpecifier setProperty:@YES forKey:@"enabled"];
		uninstallationMethodSpecifier.identifier = @"uninstallationMethodLabel";
		[_specifiers addObject:uninstallationMethodSpecifier];

		PSSpecifier* uninstallationMethodSegmentSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Installation Method Segment"
											target:self
											set:@selector(setPreferenceValue:specifier:)
											get:@selector(readPreferenceValue:)
											detail:nil
											cell:PSSegmentCell
											edit:nil];
		[uninstallationMethodSegmentSpecifier setProperty:@YES forKey:@"enabled"];
		uninstallationMethodSegmentSpecifier.identifier = @"uninstallationMethodSegment";
		[uninstallationMethodSegmentSpecifier setProperty:APP_ID forKey:@"defaults"];
		[uninstallationMethodSegmentSpecifier setProperty:@"uninstallationMethod" forKey:@"key"];
		uninstallationMethodSegmentSpecifier.values = @[@0, @1];
		uninstallationMethodSegmentSpecifier.titleDictionary = @{@0 : @"installd", @1 : @"Custom"};
		[uninstallationMethodSegmentSpecifier setProperty:@0 forKey:@"default"];
		[_specifiers addObject:uninstallationMethodSegmentSpecifier];
	}

	[(UINavigationItem *)self.navigationItem setTitle:@"Advanced"];
	return _specifiers;
}

- (void)setPreferenceValue:(NSObject*)value specifier:(PSSpecifier*)specifier
{
	NSUserDefaults* tsDefaults = trollStoreUserDefaults();
	[tsDefaults setObject:value forKey:[specifier propertyForKey:@"key"]];
}

- (NSObject*)readPreferenceValue:(PSSpecifier*)specifier
{
	NSUserDefaults* tsDefaults = trollStoreUserDefaults();
	NSObject* toReturn = [tsDefaults objectForKey:[specifier propertyForKey:@"key"]];
	if(!toReturn)
	{
		toReturn = [specifier propertyForKey:@"default"];
	}
	return toReturn;
}

@end
