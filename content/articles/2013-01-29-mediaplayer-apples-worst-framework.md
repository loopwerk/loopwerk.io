---
tags: iOS
---

# Apple's worst iOS framework: MediaPlayer
When I started to work on Last.fm's [Scrobbler for iOS](http://www.last.fm/hardware/ios), I though it would be quite an easy app to create. After all, it's basically a couple of lists of artists, albums and tracks, and all actual music playback will be done using the MediaPlayer framework. Boy, was I wrong.

*Note: when talking about MediaPlayer, I am mostly talking about `[MPMusicPlayerController iPodMusicPlayer]`.*

## Problem 1: notifications in the background
The number one feature of the Scrobbler is of course that it scrobbles, which means sending the track you're playing to your Last.fm profile. This has to be extremely reliable, and should preferably work in realtime, even when the app is in the background. The basics are really simple: the app subscribes to the `NowPlayingItemDidChangeNotification` notification, and on every track change you get a callback and you can do whatever it is you need to: in our case sending the scrobble to the Last.fm servers. Problem: this only works when the app is running in the foreground. As soon as the screen automatically locks or you open another app, your app won't get the notifications, and thus you can't scrobble.

## Problem 2: music is played back via the native Music app
We're using the MediaPlayer framework to play back whatever track you select in the app, and quickly found a problem: the native Music app is actually doing the playback, not some background API that's invisible to the user. That means that the Music app is visible in the iOS multitasking bar, and its icon will be displayed as the app that's playing music, not Scrobbler's icon. It's a small problem, until we discovered that some people are obsessive about killing apps that they're not using via the multitasking bar. And when they kill the Music app, of course the music stops, even though in their mind they're using Scrobbler to play their tracks.

## Problem 3: AVPlayer can't play iTunes Match content in the cloud
So, we had 2 problems to solve: we need notifications in the background, and the client wants to see his icon as the app that's playing music. My proposed solution was to switch to AVPlayer for music playback. Your app is then the one doing the actual playback so the correct icon will be displayed, plus you're alive in the background and thus notifications will be received. Meaning, we can scrobble while in the background. Sounds good! So I created [GVMusicPlayerController](https://github.com/gangverk/GVMusicPlayerController), "the power of AVPlayer with the simplicity of MPMusicPlayerController", because while AVPlayer will let your app be alive in the background, it doesn't offer the MediaPlayer features like queries, queues, shuffling, repeat modes and all that good stuff. I was really happy with the result, it did exactly what I needed it to do: with minor changes in my app, I now had solved my 2 problems.

Until I found problem number three: AVPlayer can't play music in the cloud, so the Scrobbler app would be useless to anyone using iTunes Match. Needless to say, this was unacceptable, and I switched back to the standard MediaPlayer framework. Problems one and two were once again unsolved.

In the end we solved the background problem by playing a silent audio track using AVPlayer, while playing all music using the MediaPlayer framework. It's a stupid hack, but the only way to stay alive in the background and support iTunes Match as well. This solution brought its own set of problems to solve like battery drain, but let's get back to MediaPlayer's problems.

## Problem 4: broken playbackState
When you ask the MediaPlayer what its play state is, you would expect an honest answer, right? Apparently Apple doesn't think this is necessary, and so even though music is clearly playing, sometimes the system will happily tell you that it's currently paused or stopped. This causes a lot of problems in our interface, as the state of play / pause buttons is dependent on the proper response from the MediaPlayer. Right now, this scenario happens all too often: music is playing, but the play / pause button is set to "play" instead of "pause". Hitting it doesn't do anything either, because music is already playing.

Our solution is to always call play and then pause when you want to pause. And when you hit play, I first call pause, then play. The button state will often fix itself after that as well. It's an extremely annoying problem that Apple should really fix, but instead it has only gotten worse with iOS6. All third party music playback apps (that use MediaPlayer) suffer from the same problem, and I don't even want to think about the amount of time that we've wasted on it.

## Problem 5: you can't read the queue
The client had a simple request: the Scrobbler app should show the playback queue in a table, just like the native Music app does. Again one of those things that sound very easy, but no: it's completely impossible to read the queue from the MediaPlayer. So, right now the Scrobbler app keeps its queue. Every time the user plays a track, no matter if it's coming from an artist page, album or the "all tracks" list, we make a copy of the queue before setting it on MediaPlayer. This makes the app sluggish when the user plays a track from the "all tracks" list, because the queue is **all** his tracks. Saving this list locally takes time. Another fun problem: what to do when the user changes the queue directly in the Music app, for example by playing a different album? Since the queue wasn't set from the Scrobbler app it's still displaying the old queue, and since we can't read the queue from MediaPlayer, there's no way to tell the user what's really up next.

Right now we detect when a track is started that's not part of the current queue, while the app is in the background. This means the queue was changed from outside the Scrobbler app, so then we clear the local queue and message the user, telling him we can't show his play queue because it was changed from outside the app.

## Problem 6: you can't edit the queue
In the Scrobbler app we have a nifty "smart playlists" feature, kind of like iTunes Genius, where we create a playlist based on similarities in tracks. Let's say you're listening to the "slow music" smart playlist, and one of the tracks isn't slow at all. We have this "doesn't belong" button, where you can remove this track from the playlist, training the system in the process. Of course, we need to remove this track from your playback queue as well, or it will still come up next. Yeah.. that's not possible. You can't edit the queue, you can't only set a new one. Normally you would then get the current queue, create a local mutable copy, remove the one track and set the queue to your modified copy. But like I said, the queue can't be read. Luckily, I was already saving a local copy of the queue to deal with problem five.

So, we set the new queue to our current-queue-minus-one version, but the removed track is still played as part of the queue. What gives? Turns out the new queue isn't actually set until you send the `play` message to MediaPlayer as well, which results in your currently playing track restarting. Not really what you'd call a smooth experience. So, you have to save the current position of the current track, set the new queue-minus-the-one-track, send the `play` message and fast forward to the saved position. The user will have a hick up of about a second, but it's the best we could do.

It's a lot worse when the user has shuffle enabled though: in that case a completely different random track will start to play, and there's nothing we can do about that.

## Problems, problems and more problems
Not convinced yet that MediaPlayer is Apple's worst framework?

- MediaQueries are horribly simple, with no advanced queries possible ("all tracks from the 90's with no rating")
- MediaQueries can't be sorted either, so sorting on number of plays or track rating is but a dream
- Tracks are readonly, so you can't change the rating, lyrics or any other metadata
- The shuffle and repeat modes have completely useless "default" values, where you don't actually know what they're set to, so using these values to show the status in your app is not possible
- When you set MediaPlayer's shuffle or repeat modes and go to the native music app, its shuffle and repeat icons have not been updated to reflect the new states

All of these problems made sure that this "it's just a music player" app took way longer to create than anticipated, while giving a lot more headaches than ever thought possible.

In the end we've solved almost all of the problems and Scrobbler for iOS came out really good. I'm immensely proud of it, I just wish that we didn't have this much problems on the way. Most of the iOS frameworks are very good and good to work with. I have no clue why Apple created such a horrible mess with MediaPlayer. It's buggy as hell, under powered and over simplified.
