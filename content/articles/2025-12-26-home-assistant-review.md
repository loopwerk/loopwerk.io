---
tags: review
summary: Nearly a year ago I replaced a pile of smart-home apps, hubs, and subscriptions with Home Assistant Green. This is a long-term review of what changed, what didn't, and whether the promise of one local system actually holds up.
---

# Home Assistant review after one year of use

In early January of this year I bought a [Home Assistant Green](https://www.home-assistant.io/green/), a plug-and-play way to get started with home automation using the open-source Home Assistant software. Along with it, I bought the [Connect ZBT-1](https://www.home-assistant.io/connectzbt1/), an antenna that lets Home Assistant talk directly to Zigbee and Thread devices.

I've now been using Home Assistant daily for almost a year. This is a long-term, real-world review: why I bought it, what changed in my setup, and whether it was worth it.

## Why I bought Home Assistant

Before Home Assistant, my smart home setup already looked fairly complete. I had about ten Philips Hue lights and a couple of Hue buttons, smart radiator thermostats from Tado, a Logitech Circle View camera, and a Wi-Fi connected solar panel installation with its own app to show daily energy production.

But in practice, it was messy.

I had a Philips Hue hub sitting in a closet, plus Tado's "internet bridge". Each system came with its own app. Hue synced to Apple HomeKit, but Tado didn't, which meant I could use Siri for lighting but not for heating. My solar panels had yet another app, entirely separate from the rest of my smart home, just to get basic insights into energy production. On top of that, Tado charged a monthly subscription to enable automatic home/away geofencing, so the heating would turn off when I left the house.

I was getting increasingly fed up with the situation: too many apps, too many hubs, too much cloud dependency, and a subscription for something that really shouldn't require one. That's when I started looking for alternatives and quickly ran into Home Assistant.

## What changed

After switching to Home Assistant, things became a lot simpler.

I was able to completely ditch the Hue hub and app. All my Hue lights and buttons now connect directly to Home Assistant using the ZBT-1 dongle. Home Assistant became the single place where almost all my devices live — the source of truth.

Tado is the one remaining exception. I still use their internet bridge, which means the radiators are cloud-connected. Home Assistant talks to them via Tado's API. It's not ideal — I'd much rather have everything running locally — but I'm not eager to replace perfectly good hardware just to move from cloud to Thread + Matter.

The Logitech Circle View camera also remains outside of Home Assistant entirely. It still lives purely inside Apple's Home app, and that's fine: it works well there, and I don't feel a strong need to pull camera feeds into my automation system.

The big difference is that everything else is now coordinated through Home Assistant, and it's simply far more powerful than HomeKit on its own.

## Home Assistant and Apple Home

One of the nicest surprises was how well Home Assistant integrates with Apple's ecosystem.

By installing the HomeKit Bridge integration, all devices managed by Home Assistant are exposed to Apple's Home app. That means I can use Siri to control everything that lives in Home Assistant, including devices that previously had no HomeKit support at all, such as my Tado radiators.

Last summer I also had air conditioners installed in my office and bedroom. They connect to Wi-Fi and come with their own app, which sucks. Worse, they don't support Apple Home natively. I assumed I'd be stuck using that app forever.

Instead, Home Assistant immediately discovered them and exposed them to the Home app. Suddenly I could control them with Siri, include them in automations, and forget the vendor app entirely.

Because everything is available in Apple Home, I can also control my house when I'm away. I can pre-heat the house on the way back, or make sure all the lights are turned off.

Home Assistant does have its own iPhone app, but remote access requires setting up your own VPN and port forwarding, which is a fair amount of work. There's also Home Assistant Cloud, which offers easy and secure remote access, but it costs €75 per year. No thanks — I just do everything via the Home app for free.

One of my main motivations for switching was getting rid of Tado's subscription, and that worked out perfectly.

Instead of relying on Tado's geofencing, I now let Apple Home detect when I leave or arrive. Home Assistant listens for those events and automatically switches my heating between Home and Away modes. Same result, no subscription.

## Other benefits I didn't expect

Home Assistant connects to far more than just lights and thermostats.

It integrates with my solar panels and with my electricity and gas meters, using a [SlimmeLezer+](https://www.zuidwijk.com/product/slimmelezer-plus/). That means I can see exactly how much electricity I generate, how much I consume, how much goes back to the grid, and how much gas I use — all in clear, easy-to-understand graphs broken down per year, month, day, or even hour.

What used to be a separate solar app is now just another data source inside the same system.

Home Assistant also works with cheap, generic smart devices without requiring vendor hubs. It talks to my HomePod mini and Sonos speakers, and can play sounds or text-to-speech announcements throughout the house.

This enables some wonderfully nerdy automations. When a smart plug detects that the washing machine is done, based on a drop in power usage, Home Assistant announces it over Sonos. If I turn on my lava lamp, it automatically turns it off again four hours later. Automations can be triggered by the weather, sunrise and sunset, my presence, time of day, device state, or any combination of these.

Compared to HomeKit alone, it's on a completely different level. And all of this runs locally on my own hardware, configured through a clean web interface.

## Verdict

If you buy a Home Assistant Green today, along with the newer ZBT-2 antenna for Zigbee and Thread, the total cost is about €154.

I was able to cancel my Tado subscription, which means that after roughly three years the hardware will have paid for itself. But that's not the main point.

The real value is having everything in one system.

One place to manage all devices, one automation engine, no forced subscriptions, minimal cloud dependency, and full Siri and Apple Home integration. I no longer need separate apps for Hue, Tado, my air conditioners, my solar panels, or my smart plugs.

For me, this was easily worth the one-time purchase. It's the best tech purchase I made this year, and I've only scratched the surface of what's possible.
