---
tags: review, iOS, swift
summary: I've been working with SwiftUI for almost half a year now, and in that time I've learned a lot. I love a lot about it, but there are also so many bugs and issues that need workarounds that it's kind of maddening.
---

# A review of SwiftUI problems
I've been working with SwiftUI for almost half a year now, and in that time I've learned a lot. I love a lot about it, but there are also so many bugs and issues that need workarounds that it's kind of maddening. The first 80% of the app is super easy to build - but the last 20% takes another 200% of time.

This article will make it seem like I hate SwiftUI but that's definitely not the case. I love the declarative style of writing views, I love the live previews even more. The Combine integration is awesome, as are `@State`, `@Binding`, `@Published` and friends. I love how easy it is to add animations to your app, and how quickly it is to build UIs using the `HStack` and `VStack` building blocks. There is no need for autolayout anymore. And combined with the live previews I don't even miss storyboards! In fact, it's so quick and easy to build prototypes in SwiftUI that I use it instead of something like Sketch or Figma to try out new ideas.

But, this article is about the problems I had while building my app. I'm sure I already forgot a bunch of them, but here is what I remember.

## Custom navigation bar title view
It's currently not possible to have something equivalent to `navigationItem.titleView` - you're stuck to using a simple title label. If you want to show two lines of text or an image, you're just out of luck.

It's also not possible to add any gesture recognizers to the navigation bar. So if you want to make it tappable to open a menu for example, you can't.

## List actions
List is overall a pretty good SwiftUI component, but it's missing some things. For example you can't add custom swipe actions to the cells - there is only swipe-to-delete. Which by the way can't be disabled per row using `deleteDisabled`. Either all rows can be swiped, or none.

## Keyboard handling
Showing and hiding the keyboard, making sure textfields scroll into view when the keyboard would otherwise overlap them; it's all missing.

## NSAttributedString support
There is none. You'll have to create your own `UIViewRepresentable` version of `UILabel`, which brings different problems like `preferredMaxLayoutWidth` handling and the label not properly self-sizing. Or if you want to show attributed text with links (for example, when you're rendering Markdown text), you'll have to build your own custom `UIViewRepresentable` version of `UITextView`. And oh boy, if you want that to automatically size itself to its contents, [good luck](https://stackoverflow.com/questions/60437014/frame-height-problem-with-custom-uiviewrepresentable-uitextview-in-swiftui). This problem is the reason why the iOS app for Critical Notes is on hold.

![screenshot](/articles/images/cn-height-problem.jpg)

## Navigation is pretty bad
It's not possible to have the navigation be driven as a function of state, like the rest of your UI. Adding Deep Linking support for example is kind of a nightmare (if possible at all, I didn't dare try). There are also just too many bugs where sometimes `NavigationLink` [only works once](https://stackoverflow.com/questions/59553225/swiftui-form-picker-only-shows-once) in the simulator, or how they seem to [never release their memory](https://stackoverflow.com/questions/59910943/swiftui-navigationlink-never-releases-memory), or how they [cause crashes](https://stackoverflow.com/questions/58404725/why-does-my-swiftui-app-crash-when-navigating-backwards-after-placing-a-navigat). The list goes on and on.

## Weird bugs
One particular weird one: if you open a sheet, dismiss is, and try to open it again, that doesn't work if you use a large navigation bar title style, or a custom `accentColor`. See [this StackOverflow question](https://stackoverflow.com/questions/58910255/swiftui-button-in-navigationbar-wont-fire-after-modal-dismissal/60225570#60225570).

At one point I was struggling for weeks, trying to find a workaround for a weird crash I was having. I was showing a background image inside of a GeometryReader, a ZStack and a NavigationView. And when you left that screen and then went back to it via a trailing navigation bar button, [you got a crash](https://stackoverflow.com/questions/60028961/swiftui-crash-precondition-failure-attribute-failed-to-set-an-initial-value).

There are also a lot of bugs caused when you have a view instantiate its own ViewModel instead of passing it in, like [this bug](https://stackoverflow.com/questions/60133054/bizarre-swiftui-behavior-viewmodel-class-binding-is-breaking-when-using-env) where `@Binding` simply breaks, or [this problem](https://stackoverflow.com/questions/60159490/swiftui-passing-an-environmentobject-to-a-sheet-causes-update-problems) when you show it as a sheet.

## iPad split view support is pretty bad
You have to add `.navigationViewStyle(StackNavigationViewStyle())` to every single sheet in your app, or even modal sheets are shown as a split view, with a completely blank right side. And it's not possible to always have both the left and right views open even in portrait mode, so users who open your app in portrait mode have no clue that there's a view hiding a menu (for example), that they have to swipe in from the left side of the screen to see.

## Dark mode uses pure black as the background color
And that's a problem on OLED devices because of a problem called [OLED smearing](https://twitter.com/marcedwards/status/1053519077958803456?s=21). This smearing can easily be solved by using `#050505` as the background color instead of `#000000`, but it's [not possible to change that for your entire app](https://stackoverflow.com/questions/60142142/overwrite-the-default-background-color-of-swiftui-views), so you end up having to set a custom background for each and every View. It's not a bug or even a huge problem, just a big sigh. I wish there was more `UIAppearance`-like configuration possible in SwiftUI.

## State management
There is no officially blessed way on how to properly store your application state, so most people will default to one global `ObservableObject` AppState, passed around as an `@EnvironmentObject`. Which is fine, for the most part, except that ALL your views will re-render themselves whenever ANY observed property in your AppState object changes, which can cause real performance problems. Personally I am going to play around with Pointfree's [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) after iOS 14 and hopefully SwiftUI 2.0 are available.

## Missing Views
Just a small taste of UIKit views that have no SwiftUI counterpart. So you have to create these yourself. Not a huge issue, but it would be nice if this was more feature complete.

- UIActivityIndicatorView
- ASAuthorizationAppleIDButton
- UIImagePickerController
- UITextView
- UICollectionView
- Picker with multiple wheels

Not views but also missing:

- UIViewControllerTransitioningDelegate
- UIModalPresentationStyle

