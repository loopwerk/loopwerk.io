---
tags: iOS, howto
summary: The client wants an Airplay button in the navigation bar, with a custom background. The solution feels a bit hacky, but works perfectly.
archive: true
---

# MPVolumeView (Airplay button) on an UIBarButtonItem
In an app I'm currently building, the client wants an Airplay button in the navigation bar, with a nice background like so:

After trying some things, the solution seems to be to loop over the subviews. It feels a bit hacky, but works perfectly:

```objc
MPVolumeView *airPlayButton = [[MPVolumeView alloc] initWithFrame:CGRectZero];
airPlayButton.showsVolumeSlider = NO;
airPlayButton.showsRouteButton = YES;

for (id subView in airPlayButton.subviews) {
    if ([subView isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)subView;
        [button setBackgroundImage:[UIImage imageNamed:@"background"] forState:UIControlStateNormal];
        [button setFrame:CGRectMake(0, 0, 45, 33)];
        [button setImageEdgeInsets:UIEdgeInsetsMake(2, 0, 0, 0)];
    }
}

[airPlayButton sizeToFit];

self.navigationItem.rightBarButtonItems = @[
    [[UIBarButtonItem alloc] initWithCustomView:actionButton],
    [[UIBarButtonItem alloc] initWithCustomView:airPlayButton],
    [[UIBarButtonItem alloc] initWithCustomView:informationButton]
];
```