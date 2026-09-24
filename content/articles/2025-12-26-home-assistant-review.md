---
tags: review
summary: Nearly a year ago I replaced a pile of smart-home apps, hubs, and subscriptions with Home Assistant Green. This is my long-term review.
---

# Home Assistant review after one year of use

In early January of this year I bought a [Home Assistant Green](https://www.home-assistant.io/green/), a plug-and-play way to get started with home automation using the open-source Home Assistant software. Along with it, I bought the [Connect ZBT-1](https://www.home-assistant.io/connectzbt1/), an antenna that lets Home Assistant talk directly to Zigbee and Thread devices.

I've now been using Home Assistant daily for almost a year, so it's time for a proper long-term review.

## Why I bought Home Assistant

Before Home Assistant, my smart home setup already looked fairly complete. I had about ten Philips Hue lights and a couple of Hue buttons, smart radiator thermostats from Tado, a Logitech Circle View camera, and a Wi-Fi connected solar panel installation with its own app to show daily energy production.

It worked, but it was messy.

There was a Philips Hue hub sitting in a closet, next to Tado's internet bridge, each with their own app. Hue synced to Apple HomeKit but Tado didn't, so Siri could control my lights but not my heating. My solar panels had yet another app, just to get basic insights into energy production. And Tado charged a monthly subscription for automatic home/away geofencing, so that the heating would turn off when I left the house.

I was getting pretty fed up with all the apps and hubs and cloud dependencies, and with paying a subscription for something that really shouldn't require one. That's when I started looking for alternatives and quickly ran into Home Assistant.

## What changed

Things got a lot simpler after the switch.

I was able to completely ditch the Hue hub and app. All my Hue lights and buttons now connect directly to Home Assistant using the ZBT-1 dongle. Home Assistant became the single place where almost all my devices live - the source of truth.

Sadly I couldn't get rid of Tado's internet bridge, so the radiators are still cloud-connected and Home Assistant talks to them via Tado's API. Ideally I'd have everything running locally, but annoyingly Tado doesn't expose a local API. In theory I could upgrade to their newer Matter + Thread radiators, which do work locally and without a bridge, but that's a big cost and not worth it to me.

The Logitech Circle View camera also stays outside of Home Assistant, it lives purely in Apple's Home app. I don't really need the camera in my automation system anyway, so I never looked into integrating this.

Everything else is now coordinated through Home Assistant, which is far more powerful than HomeKit on its own.

## Home Assistant and Apple Home

Home Assistant integrates surprisingly well with Apple's ecosystem. The HomeKit Bridge integration exposes all devices managed by Home Assistant to Apple's Home app, so I can use Siri to control everything in Home Assistant, even devices that never had HomeKit support to begin with, like my Tado radiators.

Last summer I also had air conditioners installed in my office and bedroom. They connect to Wi-Fi and come with their own app, which sucks, and they don't support Apple Home natively, so I assumed I'd be stuck with that app forever. But Home Assistant simply discovered them and exposed them to the Home app, and now I can control them with Siri and never open the vendor app.

Because everything is available in Apple Home, I can also control my house when I'm away. I can pre-heat the house on the way back, or make sure all the lights are turned off.

Home Assistant does have its own iPhone app, but remote access requires setting up your own VPN and port forwarding, which is a fair amount of work. There's also Home Assistant Cloud, which offers easy and secure remote access, but it costs €75 per year. No thanks - I just do everything via the Home app for free.

One of my main motivations for switching was getting rid of Tado's subscription, and that worked out perfectly.

Apple Home now detects when I leave or arrive, Home Assistant listens for those events and switches the heating between Home and Away modes. So I get Tado's paid feature for free.

## Other benefits I didn't expect

Home Assistant turned out to connect to way more than just lights and thermostats. It integrates with my solar panels and with my electricity and gas meters, using a [SlimmeLezer+](https://www.zuidwijk.com/product/slimmelezer-plus/), so I can see exactly how much electricity I generate and consume, how much goes back to the grid, and how much gas I use, in graphs broken down per year, month, day, or even hour.

Home Assistant also works with cheap, generic smart devices without requiring vendor hubs. It talks to my HomePod mini and Sonos speakers, and can play sounds or text-to-speech announcements throughout the house.

And it enables some wonderfully nerdy automations: when a smart plug detects that the washing machine is done, based on a drop in power usage, Home Assistant announces it over the Sonos speakers. When I turn on my lava lamp, Home Assistant turns it off again four hours later. Automations can be triggered by the weather, by sunrise and sunset, by my presence, the time of day, the state of other devices, whatever you want really.

HomeKit can't do any of this, and Home Assistant does it all locally, on my own hardware, configured in the web interface.

## Verdict

If you buy a Home Assistant Green today, along with the newer ZBT-2 antenna for Zigbee and Thread, the total cost is about €154. I was able to cancel my Tado subscription, which means that after roughly three years the hardware will have paid for itself.

But the real value is having everything in one system, with all my automations in that same system, without forced subscriptions, and with everything working through Siri and Apple Home. I no longer need the Hue app, the Tado app, the air conditioner app, the solar app, or the smart plug app.

Easily the best tech purchase I made this year.
