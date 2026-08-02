#import "TSAnnouncementViewController.h"
#import "TSHahaSticker.h"

@implementation TSAnnouncementViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.view.backgroundColor = UIColor.systemBackgroundColor;

	UIImage* stickerImage = hahaStickerImage(120);
	UIImageView* iconView = [[UIImageView alloc] initWithImage:stickerImage];
	iconView.contentMode = UIViewContentModeScaleAspectFit;
	iconView.translatesAutoresizingMaskIntoConstraints = NO;

	UILabel* titleLabel = [[UILabel alloc] init];
	titleLabel.text = @"Chào mừng đến với CheatiOSVipStore";
	titleLabel.font = [UIFont boldSystemFontOfSize:22];
	titleLabel.textColor = UIColor.labelColor;
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.numberOfLines = 0;
	titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

	UILabel* subtitleLabel = [[UILabel alloc] init];
	subtitleLabel.text = @"Tham Gia Cộng Đồng:";
	subtitleLabel.font = [UIFont systemFontOfSize:15];
	subtitleLabel.textColor = UIColor.secondaryLabelColor;
	subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;

	UIButton* linkButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[linkButton setTitle:@"Tại đây" forState:UIControlStateNormal];
	linkButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
	[linkButton addTarget:self action:@selector(communityLinkPressed) forControlEvents:UIControlEventTouchUpInside];
	linkButton.translatesAutoresizingMaskIntoConstraints = NO;

	UIStackView* communityRow = [[UIStackView alloc] initWithArrangedSubviews:@[subtitleLabel, linkButton]];
	communityRow.axis = UILayoutConstraintAxisHorizontal;
	communityRow.alignment = UIStackViewAlignmentCenter;
	communityRow.spacing = 4;

	UIStackView* stack = [[UIStackView alloc] initWithArrangedSubviews:@[iconView, titleLabel, communityRow]];
	stack.axis = UILayoutConstraintAxisVertical;
	stack.alignment = UIStackViewAlignmentCenter;
	stack.spacing = 16;
	stack.translatesAutoresizingMaskIntoConstraints = NO;

	UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[closeButton setTitle:@"Đóng" forState:UIControlStateNormal];
	closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
	closeButton.backgroundColor = UIColor.systemBlueColor;
	[closeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
	closeButton.layer.cornerRadius = 14;
	closeButton.layer.cornerCurve = kCACornerCurveContinuous;
	closeButton.translatesAutoresizingMaskIntoConstraints = NO;
	[closeButton addTarget:self action:@selector(closePressed) forControlEvents:UIControlEventTouchUpInside];

	[self.view addSubview:stack];
	[self.view addSubview:closeButton];

	[NSLayoutConstraint activateConstraints:@[
		[iconView.widthAnchor constraintEqualToConstant:120],
		[iconView.heightAnchor constraintEqualToConstant:120],

		[stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
		[stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-40],
		[stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:32],
		[stack.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-32],

		[closeButton.topAnchor constraintEqualToAnchor:stack.bottomAnchor constant:40],
		[closeButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
		[closeButton.widthAnchor constraintEqualToConstant:200],
		[closeButton.heightAnchor constraintEqualToConstant:48],
	]];
}

- (void)closePressed
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)communityLinkPressed
{
	NSURL* url = [NSURL URLWithString:@"https://t.me/crackcyipa"];
	if(url)
	{
		[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
	}
}

@end
