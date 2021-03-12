---
tags: faq, iOS, swift
summary: My take on the very common question "What should I learn or focus on? UIKit or SwiftUI?"
---

# Mentee Question 1: UIKit or SwiftUI
*Earlier this month I started a free [mentorship program](/mentor/) for underprivileged people who want to become iOS developers and simply need someone to ask questions, get guidance, someone to pair program their way through a problem with. I'm happy to say that I accepted four mentees from Egypt, Ghana, India and Russia, and have had three meetings so far. They average about 90 minutes or so, and a bunch of questions have already come my way. It felt useful to repeat the questions and answers here as well.*

Today's question:

> # "What should I learn or focus on? UIKit or SwiftUI?"

SwiftUI is the new kid on the block and grabbing all the attention. Most new tutorials and articles seem to be all about SwiftUI, it's what people new to iOS development are guided towards and what experienced people want to pick up and at least play around with. But UIKit has a huge history so it's natural to wonder: what should I learn first?

I've tried to build a reasonably complex app using SwiftUI late 2019, early 2020, using the first version of SwiftUI. That means that some of the problems I encountered have undoubtedly been fixed, but I think most of my experience is still the same today. The first thing that comes to mind when I think back on building this particular app is the massive amount of time spent on working around SwiftUI [bugs and problems](/articles/2020/swiftui-review/). Some of the problems were impossible to fix or work around, for example showing rich Markdown text with inline links was such a huge problem that I never completed the app, and it's still waiting in the freezer for me to pick it up again. But it left such a bad taste in my mouth, that I am not sure when I'll finish it, maybe when SwiftUI version 3 comes around? And I *know* that if I would've built the app using UIKit, it would've been in the App Store for a long time by now.

If you're building an app using mostly the native UI controls Apple gives you, or you go the completely custom UI route, I think SwiftUI is worth a consideration. But if you're using mostly native UI controls but want them to work slightly different, tweak them and their design, you'll quickly be frustrated. Another thing that I don't like about SwiftUI is the overall lack of good architecture; all views end up being tightly coupled due to the way NavigationView works, using a pattern like Coordinators isn't really an option, supporting Deep Linking throughout your app is not possible either. Simple things got simpler (forms!), some hard things got a *lot* simpler (animations!) but other simple things are now impossible (for example having a custom navigation bar title view) or at least a lot harder. I also feel SwiftUI has a confusing story when it comes to state management. Personally I'm a huge fan of [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) but I wouldn't really recommend it to beginners. 

My advice: I would use UIKit for the overall skeleton of the app, using good ol' UINavigationControllers, Coordinators, deep linking and all that. Use standard UIViewControllers where it makes sense, with the amazing compositional UICollectionView layout and diffable datasources for example, but use individual SwiftUI views where those make sense. For forms, tables, custom views; integrate them into the UIKit app (check out [this](https://www.avanderlee.com/swiftui/integrating-swiftui-with-uikit/) article from Antoine van der Lee). It gives you the best bits of both worlds, and an easy way to replace a SwiftUI view with "standard" UIKit when you walk into a problem.

So, what should you learn? I would 100% start with UIKit and then learn SwiftUI later on and integrate it into your UIKit app. The overwhelming majority of existing apps are of course also written using UIKit, so you're going to need that knowledge anyway to be able to get a job. Plus not all UIKit controls have SwiftUI counterparts yet, so even if you want to build a pure SwiftUI app, you're going to be using (some) UIKit anyway.

I hope this answer helped, reach out to me if you have feedback. Stay tuned for the next article in this series!
