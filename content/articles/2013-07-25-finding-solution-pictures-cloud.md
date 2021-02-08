---
tags: review
---

# Searching for a solution to back up all my pictures to the cloud
I have well over 35 GB of pictures, and after almost losing my hard drive (it started to behave very strangely but I was able to salvage all the pictures) I realised that I need to back them up in the cloud. I do usually share my best ones on Facebook, but I need a solution that backs up every picture (full-resolution with all its metadata intact) without ever thinking about it.

![Screenshot from Finder](/articles/images/pictures-folder.png "Currently all my photos are simply stored in subfolders like this")

I'm looking for a solution with the following must-have features:

- Backs up full resolution pictures including metadata
- Backs up RAW files
- Backs up videos
- Some kind of automated workflow where imported pictures are automatically backed up, preferably by simply moving a pictures inside a folder
- It should be possible to download the full backup

Furthermore it would be nice if I could (privately) access the pictures from a website and/or iOS devices. If it's possible to publicly share a selection of pictures that would be even better.

Lastly, true sync would be preferable: if I remove a picture (or a folder with pictures) then I want it to be deleted on the server as well.

## Dropbox
Dropbox definitely has the ease of auto uploading. I can stick with my current folder structure, put new pictures in them and they're synced to the cloud without ever thinking about it.

So it ticks all the "must-have" boxes, but it's not so good for sharing picture galleries (either public or private) and I'd have to pay for a Pro account: $99 per year for 100 GB, not super cheap.

## Facebook
Facebook seems to have unlimited photo upload, but there's no way to automatically upload my photos. I could adopt a new workflow, for example use iPhone or Aperture to store my photos and upload to Facebook from there, but that's a bit too much trouble and wouldn't be a true sync either.

There would also be no (easy) way to re-download all the pictures in case of a broken hard drive. As a photo gallery it's not as good as Flickr and to trust all my pictures to Facebook..?

The only good thing about using Facebook would be to upload all pictures privately and then selectively make some of them public. It fails in all the must-haves though.

## Google+
Their iOS app automatically uploads all your photos which you can then make public. They also offer unlimited space, so far so good.

But, no auto uploading from the desktop and all photos will be resized. I need a true, full-resolution backup, so this simply isn't an option.

## Flickr
Flickr now offers a massive 1 TB of free storage and you can upload everything as private and then selectively make some public. As a photo gallery they're pretty good but this solution suffers from the same problem as Facebook: no easy way to get your photos into Flickr, certainly not automatic.

If I could have some kind of Dropbox / Flickr hybrid that would be awesome. Simply add your pictures to a folder and it gets synced to Flickr. Which brings me to the next solution.

## Socialfolders.me
This is a third party desktop app which promises the best of Dropbox and Flickr: automatically upload all your pictures by simply adding them in a folder.

I gave it a spin and while it did upload all my pictures to Flickr, it doesn't do a true sync: moving pictures from one folder to another doesn't delete that picture from the old set on Flickr. It's also quite slow to see changes in my folders, sometimes got confused about changes and in general needed too much prodding to keep going. It's very strict and weird about folder names, different preferences are managed in the app and on their website.. it's kind of a mess.

A very good idea but not good enough just yet.

## Photostream
Apple's photostream only holds 1000 photos, but by using shared photostreams you supposedly can get around this limit. All pictures taken with my iPhone would be automatically uploaded, other pictures can be uploaded via iPhoto or Aperture.

I've tried to use photostreams multiple times with iPhoto, but it never really works for me. When I try to import my photos from my iPhone they're always seen as duplicates for example, it just doesn't fit my mental workflow. Of course, with some practice and time I'm sure I could get used to it.

But shared photostreams can't contains videos, so that kills this solution.

## Picturelife
[Picturelife][] is a desktop app that automatically syncs your photos plus an iOS app to view them. At $70 per year for 100 GB it's cheaper than Dropbox. They support RAW and video files, so it all sounds pretty good.

I signed up for a free 5 GB account to try them out and was very quickly very disappointed. All my pictures are organised in subsolders (one for each event) and while they were all picked up and uploaded to Picturelife, it didn't translate those folders into albums on their server. So I ended up with one huge stream of pictures, not what I'm looking for at all.

It also seems impossible to download your complete backup and the sync app is one way only. All in all, I need a more Dropbox-like approach that maintains my folder structure and allows me to download all my pictures if necessary.

[Picturelife]: https://picturelife.com

## Everpix
[Everpix][] is only $49 per year and offers unlimited hosting. Their image analysis seems cool as well, but they don't accept RAW photos. Too bad, because that is a must-have for me. They also seem to run all pictures through their "proprietary image optimisation process". It sounds like they're messing with your originals, not cool.

[Everpix]: https://www.everpix.com

## Loom
[Loom][] looks very similar to Everpix but at the moment has a waiting list. At $40 for 50 GB it seems like a good option to explore once the wait is over. I'll update this post once I know more.

[Loom]: http://www.loom.com

## Closing thoughts
I'm not too sure how long companies like Picturelife, Everpix and Loom will be around for, and for that reason using Dropbox or Flickr seems like a safer choice. Out of those two options I still think that Flickr would be the best one once I figure out how to automatically sync from the desktop.

Any suggestions for a pain free photo workflow with online backup are more than welcome!

### Update August 4, 2013
After about a week of waiting I got an email from Loom telling me my account was ready. I downloaded their OS X app and was pleasantly surprised how much it behaves like Dropbox. The app creates a new folder on your hard drive, and anything you put in it is automatically uploaded to the cloud. From there your pictures can be viewed on the iOS app or synced to other Macs.

Two minor problems so far: copying nested folders to the Loom folder doesn't seem to work without problems and the iOS apps sucks at quickly viewing full screen photos. Once you open a picture in the app, you can't scroll left or right to view the previous or next picture. It seems to me that this is high on their to-do list.

RAW files do get synced but look bad and pixelated in their iOS app. Not really a problem for me, as I work with them on the desktop exclusively anyway. Video files also get synced but don't play at all in the app - something they're working on.

I would like Loom to add a map view in the app and maybe public album sharing. Other than that, a very solid service for backing up your photos and videos.

I've got myself a one year 50GB subscription and can't wait to see how this service will grow.

### Update October 7, 2013
Loom has updated its OS X app and completed removed the Dropbox-like syncing experience. Up until this update you had a "Loom" folder on your Mac, and anything you dropped in there got uploaded. If you installed Loom on another computer then you could download your pictures into this Loom folder. Like I said, very much like Dropbox.

So now that they've removed this Loom folder, that automatic uploading is gone. You can select "source" folders which will get uploaded so it's not too bad. Except when you want to download your photo library from the cloud to your Mac: this is now impossible. There is no Loom folder to sync, stored albums can't be downloaded, your pictures are locked in the cloud.

I'm hoping they will rethink their update and at least give me the option of downloading entire albums. If not, I'll have to think about maybe moving to Dropbox (or Flickr) after all.
