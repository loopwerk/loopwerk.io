---
tags: review, macOS
---

# Review roundup: email clients for OS X
Email is a huge part of my my life and I need a client that accommodates my ways and habits. It needs to be fast and user friendly. It needs to support multiple email accounts. And it needs to offer proper Google Mail support: archiving email by default and using the correct labels for Sent mail and Trash for example.

I've always been quite happy with Apple's Mail app but their latest version kept me looking for something new.

## Apple Mail
![Apple Mail](/articles/images/apple_mail.jpg)

In my opinion this is one of the best looking email clients out there. The threaded conversion is very clear, the message list shows a short preview and optionally a picture of the contact you're emailing with (a feature I like a lot). It offers a unified inbox which I prefer much more than always having to switch accounts. It also has excellent integration with all the other Apple apps like Contacts, Calendar and Messages.

Sadly though its Google Mail support is pretty bad and seems to be getting worse with every new release. Archived or trashed messages are often showing up in my inbox. Pressing the backspace key doesn't archive the message, it trashes it. But worst of all, when you move a message from the inbox to another folder that message is simply deleted.

To be fair I am using a beta version and things might be fixed before Mavericks is released but I'm not too hopeful.

## Airmail
![Airmail](/articles/images/airmail.jpg)

The first alternative I tried was [Airmail][1]. It's available on the App Store for $2.50 but I used the free beta version. My first impression was very positive: it looks good, especially the unified accounts support is very good looking. Of course it has threaded conversions, and just like Apple's Mail it shows you a picture of your contact in the message list. It's a lot smarter though, because when the person you're mailing with isn't in your contacts it tries to show another meaningful picture. For example, when I received an email from JetBrains, Airmail used their website's favicon as the contact picture. Very nice detail!

It has other nice features as well, like a send delay so if you change your mind about sending that drunken email to your ex-girlfriend you can un-send it. And Airmail works perfectly well with Google Mail too, using all the right folders straight out of the box.

Of course it's not all perfect. Airmail can be extremely slow to load your inbox on a cold start, it doesn't automatically reload the active conversion when new emails arrive, the quick reply box isn't visible by default and conversations don't hide the quoted text in emails, which results in a lot of scrolling. Composing in pure plain-text only is also a lot harder than you would think possible, with copy/paste actions doing unpredictable stuff.

Lastly, they seem to focus on adding more and more features rather than perfecting the stuff that's already there. I wish they would focus on some of the problem areas first but still, a very good email client. In fact, I am using it right now, at least until Apple will finally fix their email client.

## Inky
![Inky](/articles/images/inky.jpg)

[Inky][2] was recommended to me via Twitter but I was a bit hesitant to try it. The screenshot doesn't look that good (or very Mac-like) but since it's available for free I decided to give it a go. Sadly it doesn't start at all on Mavericks. I'll revisit this at a later time.

## Thunderbird
After looking at their [website][3] I didn't even want to try this. It looks like a clunky ageing giant. It might've been a good client, on Windows, 5 years ago.. but now I expect more.

Still, in the interest of giving it a fair shot and a review I downloaded their latest release and set up one of my email accounts. The first thing I noticed was the bland, grey, very old-fashioned design and the message list that consists of 3 columns (subject, from and date). It takes so much space! I am used to way Apple's Mail and Airmail present the message list: the subject with a small preview under it. It's so much more useful.

Thunderbird also doesn't support conversations in the detail pane, you have to switch from message to message. So very old fashioned. Okay, there is an extension available that adds this feature to Thunderbird, but it shouldn't be necessary to search for and install a bunch of add-ons to make your email client usable. Plus, the extension still gives a sub optimal experience where conversation by default are all collapsed. How am I supposed to read this conversion now?

Another thing that annoyed me is that they use the system alert sound when new email arrives, which on most systems is kind of a disruptive sound. Why not supply a nicer "new email" sound? Of course you can supply your own sound file, but that's just annoying.

I quickly uninstalled this ageing beast and tried the next client instead.

## Postbox
![Postbox](/articles/images/postbox.jpg)

While [Postbox][4] is built on the open source Thunderbird, it looks a lot more modern with proper support for threads and conversions and good Google Mail support. Then again, it costs $10 so I would expect it to be good.

I used free the Postbox trial as my only email client for about a week and in general I liked it a lot. It supports a unified inbox, threads and conversations and has a good quick reply feature.

There were a couple of small problems that I wouldn't call blockers but would like to see fixed. For example, even though they support the modern message list style, they don't include a contact picture. It might sound like a very small missing feature but I constantly use this to quickly visually find the conversion that has info that I need.

However, there were also three huge problems that do block me from switching to Postbox. First: the home and end keys don't go to the beginning or end of the current line, but to the beginning or end of the entire message. I never realised how often I use these keys while writing emails but damn this got really annoying really fast. The keys behave properly in all other OS X apps after installing [Keyfixer][5] so I'm thinking they use some kind of custom text editor. I'm actually pretty sure of that, because of huge problem number two: the spellchecker that comes built-in with OS X doesn't work, they have their own spellchecker instead. And while this works fine if you always write your emails in one language, it sucks when you write in English and Dutch. OS X's spellchecker is smart and recognises the language without any input from me. Postbox is fixed to one language.

The biggest problem of all though, is that Postbox is a huge resource hog and routinely slowed down my system. I had to kill it at least twice a day to be able to use other resource heavy apps like Photoshop or Xcode. For an email client this is not acceptable.

## Other clients

### MailMate
It looks like it came straight from the nineties. I can't use this stuff anymore. Next!

### Mailplane
It's an expensive (tabbed) wrapper around the Google Mail web client. So no unified inbox. Not a real native email client. Not good enough.

### Sparrow
It's sadly no longer being developed after it was sold to Google. I would still like to try it if it wasn't for the price: $10 for something that will never be updated. I think not.

[1]: http://airmailapp.com
[2]: http://inky.com
[3]: http://www.mozilla.org/en-US/thunderbird/features/
[4]: http://www.postbox-inc.com
[5]: http://www.starryhope.com/keyfixer/
