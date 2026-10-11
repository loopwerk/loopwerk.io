---
tags: review
summary: Nearly a year ago I replaced a pile of smart-home apps, hubs, and subscriptions with Home Assistant Green. This is my long-term review.
---

# Home Assistant review after one year of use

In early January of this year I bought a [Home Assistant Green](https://www.home-assistant.io/green/), a plug-and-play way to get started with home automation using the open-source Home Assistant software. Along with it, I bought the [Connect ZBT-1](https://www.home-assistant.io/connectzbt1/), an antenna that lets Home Assistant talk directly to Zigbee and Thread devices.

I've now been using Home Assistant daily for almost a year, so it's time for a proper long-term review.

## Why I bought Home Assistant

Before Home Assistant, my smart home setup already looked fairly complete. I had about ten Philips Hue lights and a couple of Hue buttons, smart radiator thermostats from Tado, a Logitech Circle View camera, and a Wi-Fi-connected solar panel installation with its own app to show daily energy production.

It wasn't exactly one integrated system though.

Philips Hue required a hub, and their own app. Tado required an internet bridge, and their own app. My solar panels had yet another app, just to get basic insights into energy production. Hue synced to Apple HomeKit but Tado didn't, so Siri could control my lights but not my heating. Ugh.

On top of that, Tado charges a monthly subscription for automatic home/away geofencing, i.e. turning the heating off when you leave the house.

Fed up, I started looking for alternatives, and quickly ran into Home Assistant.

## What changed

Things got a lot simpler after the switch.

I was able to completely ditch the Hue hub and app. All my Hue lights and buttons now connect directly to Home Assistant using the ZBT-1 dongle.

Sadly I couldn't get rid of Tado's internet bridge, so the radiators are still cloud-connected and Home Assistant talks to them via Tado's API. Ideally I'd have everything running locally, but annoyingly Tado doesn't expose a local API. In theory I could upgrade to their newer Matter + Thread radiators, which do work locally and without a bridge, but that's a big cost and not worth it to me.

The Logitech Circle View camera also stays outside of Home Assistant, it lives purely in Apple's Home app. I don't really need the camera in my automation system anyway, so I never looked into integrating this. Everything else is now coordinated through Home Assistant, which is far more powerful than HomeKit on its own.

## Home Assistant and Apple Home

Home Assistant integrates surprisingly well with Apple's ecosystem. The HomeKit Bridge integration exposes all devices managed by Home Assistant to Apple's Home app, so I can use Siri to control everything in Home Assistant, even devices that never had HomeKit support to begin with, like my Tado radiators.

Last summer I also had air conditioners installed in my office and bedroom, which connect to Wi-Fi and come with their own sucky app. Because they don't support Apple Home natively, I assumed I'd be stuck with that app forever. But Home Assistant simply discovered them and exposed them to the Home app, so now I can control them with Siri and never open the official app.

Because everything is available in Apple Home, I can also control my house when I'm away. I can make sure all the lights are turned off, or pre-heat the house on the way back.

Home Assistant does have its own iPhone app, but remote access requires setting up your own VPN and port forwarding, which is a hassle I didn't want to get into. There's also Home Assistant Cloud, which offers easy and secure remote access, but it costs €75 per year. No thanks - I just do everything via the Home app for free.

One of my main motivations for switching was getting rid of Tado's subscription, and that worked out perfectly. Apple Home now detects when I leave or arrive. Home Assistant then listens for those events and switches the heating between home and away modes, so I get Tado's paid feature for free.

## Other benefits I didn't expect

Home Assistant turned out to connect to way more than just lights and thermostats. For example it integrates with my solar panels, and with my electricity and gas meters, using a [SlimmeLezer+](https://www.zuidwijk.com/product/slimmelezer-plus/). I can see exactly how much electricity I generate and consume, how much goes back to the grid, and how much gas I use, in very detailed graphs.

Home Assistant also works with cheap, generic smart devices without requiring vendor hubs. I bought a bunch of smart plugs that have no HomeKit support, which I normally wouldn't have bought because of that. But Home Assistant connects to them, making them available to the Home app and thus Siri just fine.

It talks to my HomePod mini and Sonos speakers, and can play sounds or text-to-speech announcements throughout the house. And that enables some truly nerdy automations. To give you an idea: when a smart plug detects that the washing machine is done, based on a drop in power usage, Home Assistant could announce that over the Sonos speakers. 

Or a real-life example that I actually use? My lava lamp should be turned off after four hours according to its manual, which I'd absolutely never remember to do. So I made an automation and Home Assistant does it for me. Automations can be triggered by the weather, by sunrise and sunset, by my presence, the time of day, the state of other devices, whatever you want really. HomeKit can't do any of this!

Home Assistant does it all locally, without needing a cloud server, so I never have to be scared their servers go offline or they start to charge money for basic things. Yes, I'm looking at you, Tado.

## Verdict

If you buy a Home Assistant Green today, along with the newer ZBT-2 antenna for Zigbee and Thread, the total cost is about €154. I was able to cancel my Tado subscription, which means that after roughly three years the hardware will have paid for itself.

But for me, the real value is having everything in one local system, without forced subscriptions, and everything working through Siri and Apple Home.

Easily the best tech purchase I made this year.