---
tags: personal, faq
summary: It's ten years since I quit my job and started freelancing. Thinking about doing the same? I'm here to answer your questions.
---

# Ten years as a remote freelancer, ask me anything

I've been working as a professional software developer since 2001. That's twenty-five years now, and yes it blows my mind when I think about that. And for the last ten of those years, I've worked as a fully remote freelance developer for clients from all over the world.

When people interested in freelancing hear this, they usually have three questions: "How do you get started?", "How do you actually find the work?", and "How much should I charge?" I'll try to answer those questions, along with some advice.

## How I got started
Freelancing started as a byproduct of wanting to move back home.

All the way back in January 2012 I moved to Iceland, to work for a small four-person software agency called [Gangverk](https://www.gangverk.com), building mobile apps for CBS. (Yes, [that](https://www.cbs.com) CBS.) By 2015, I wanted to move back to the Netherlands, but I didn't want to leave the company. The solution was simple: I registered my own business in the Netherlands and billed them monthly. I was a freelancer, but on paper only.

The real freelancing began a year later, in September 2016, when I decided to quit. My very first job was paid open source work. I had built [raml2html](https://github.com/raml2html/raml2html), a pretty popular RAML to HTML documentation generator (even Google used it at some point), and I was hired by [MuleSoft](https://www.mulesoft.com) to update my tool to support a new version of the RAML spec.

## Where the work comes from
By far the most-asked question is "how to find clients". For me, work comes mostly via three routes.

### 1. My network
The vast majority of my work comes from people I already knew. To give some examples:

- **Last.fm** was a former client of my old boss; they liked my work and reached out directly when they needed a new iOS app. They became my longest-running client, we worked together for seven years.
- **Unilever** came through an ex-colleague who had more work than his agency could handle. 
- **Jetfly** came from a recommendation by a developer friend I'd helped out years prior.
- **Gangverk** hired me for a project almost ten years after I left.

Your network isn't a LinkedIn connection count. It's real people who know you're reliable and good at what you do, and who wouldn't hesitate to recommend you.

### 2. Open source
I've built and maintain quite a few [open source projects](/open-source/), and this has resulted in paid work a few times:

- **MuleSoft**, to work on a new version of raml2html.
- **dskrpt**, who hired me to implement [django-generic-notifications](https://github.com/loopwerk/django-generic-notifications) into their site, replacing a complicated and expensive getstream setup.
- **Sentry**. I wrote the library that became their first official iOS SDK, so when they went looking for developers to work on their new SDK, the interview was already over before it began.

### 3. Social media
Social media is hit-or-miss, but it provided the rest. I landed **WeTransfer**, **Sentry** and **Video.io** through tweets from people I followed, although in Sentry's case it was the open source work that actually got me the job. Only one client found me on LinkedIn, and I found **Sound Radix** via the [Svelte Discord server](https://svelte.dev/chat).

To summarize: hardly any of my work came from "hunting" for jobs. Just one job came from Upwork, and one from Remote OK. The rest came from being visible in the right niches and maintaining relationships with people I'd worked with years ago.

## The pros and cons of freelancing
Freelancing is often romanticized, but the trade-offs are heavy. 

On the pro side, there's of course the freedom. You choose who you work for, and if a project feels off, you can say no. It (potentially) pays significantly more than a standard salary, and you are largely insulated from corporate busy work like endless meetings and other bureaucracy. You are there to solve a problem, and when it's solved, you move on.

There are some pretty serious cons to freelancing though. First of all, there is no paid time off. If you're sick, you're losing money, and if you take a vacation, it's lost billable hours. And something that maybe not everyone realizes: getting a mortgage as a freelancer is a struggle - at least here in the Netherlands. Banks don't really like to lend huge sums of money to people with no fixed guaranteed income.

But the hardest part is the downtime anxiety. When a project ends and the next one isn't lined up, it's hard not to worry. Even after ten years, the period between contracts is stressful, especially when that downtime turns into months. My worst period as a freelancer was in 2018 after a fourteen-month job suddenly ended without warning, and I had nothing else lined up. It took me seven months to find the next project, during which I used up most of my savings. The anxiety was very real, and more than once I thought about leaving freelancing behind.

## What to charge
Speaking of freelancing paying more than a standard salary, let's talk about another common question: what should you charge your clients? This is a difficult question to answer, since it really depends on your own situation. Here's how I think you should come up with your hourly rate:

1. Determine how much money you need in a year to pay your bills, insurances, groceries, etc.
2. Divide that by the number of hours you're going to work. It's good to be conservative with this! Keep in mind the unpaid vacation time, unpaid sick leave, and time between projects. For me I would go with 25 billable weeks times 32 hours: 800 billable hours in a year.

That should give you the minimum rate you should ask for. Increase it by, for example, 10% so you can put some money aside each month. The nice thing about being conservative when coming up with the hours you'll work is that in a good year with little downtime between projects, you'll make really good money.

Once your network grows and you're getting busier with projects, you can increase your price. Dare to ask what you're worth!

Personally, I have two rates: my standard one for short-term projects, and a 25% lower one for long-term projects. If a project takes a year, for example, you don't have to worry about downtime between projects. That's easily worth a lower rate.

## The horror stories
Every freelancer has a "client from hell" story. I have two that taught me a lot about running a business.

### The shelf treatment
For one long-term project, I was building an iOS app that was heavily dependent on a custom backend the client was building in-house. In theory, this was fine. In practice, I became a victim of their poor project management.

Multiple times, I'd reach a point where I couldn't proceed until a specific API endpoint was finished. I'd be told on a Friday afternoon: "Hey, we're behind on the backend. Don't work next week while we catch up."

They essentially expected me to sit on a shelf like a tool they could pick up and put down at will, without any compensation for the dead air in my schedule. When I finally asked for a minimum billable guarantee, an insurance policy so I could actually pay my own bills while waiting for them, they turned it into a massive fight. They told me I should just "find other projects" to fill those random, week-long gaps, as if the world is full of clients waiting to hire someone for exactly five days on a moment's notice.

I liked the app and the work, but I had to walk away. It was a hard lesson: if a client doesn't respect your time as a professional, they don't respect you.

### The Xcode bait-and-switch
The second story involves a CEO who was a master of the grand vision. He sold me on a revolutionary platform, a world-class engineering team, and a codebase that was "clean and ready to scale".

I believed the hype. Then, on my first day, I opened the project in Xcode. My heart sank. It was a disaster zone of spaghetti code and hacks. That "world-class team" turned out to be a junior developer, who was building on top of the ruins of five previous teams that all left after six months. I spent a month trying to salvage the situation, submitting pull requests and fixing critical bugs from day one, but the technical debt was a mountain that couldn't be climbed.

When I realized I'd been sold a lie and handed in my notice, the CEO went ballistic. He refused to pay my invoice, claiming I had "duped" him and that the month I spent fixing his broken app was actually just "onboarding time". He followed up with a stream of insults and threats of legal action. After a long, exhausting battle, I managed to get half the invoice paid. I never saw the other half.

That experience taught me to trust my gut. I shouldn't have stayed even that one month.

## My advice if you're thinking of freelancing
If you're thinking of taking the plunge, don't just quit your job and hope for the best.

First, grow your savings account. You will eventually hit a dry spell that lasts months. If you don't have at least six months of living expenses in the bank, the stress will force you to take bad jobs for low pay. Freelancing is only fun when you have the power to say no.

Second, protect yourself legally and financially. Get the agreement in writing, and push for a kill fee or a minimum billable amount when you can. For new clients I also recommend asking for part of the first invoice upfront. A client who won't pay a deposit isn't automatically a bad client, but it's worth finding out why.

The minimum billable amount matters even more on retainer-style work, where you're not booked for forty hours a week but you are expected to be available when something breaks. Being available means you can't take on a full project somewhere else, so a week with zero hours logged is still a week the client has to pay for. The fee buys exclusivity: they're the only ones who get to claim that time.

Third, ask to see the code before you sign. Read access to the repository is ideal, but even a screenshare where someone walks you through the project tells you a lot. Check whether any tests exist. Look at the commit history to see how many developers have come and gone, and ask why the last one left. If an NDA is the blocker, sign the NDA. If they still won't show you anything, that is your answer.

Fourth, work on your visibility before you need it. Don't wait until you're unemployed to start a blog or contribute to open source. Go to conferences and meetups, talk to people, and be helpful without expecting an immediate return. My writing and open source work rarely brought me a project directly, but they are the reason interviews turned into a formality instead of an evaluation.

Finally, start with the people you already know. Talk to your colleagues today. Let them know you're thinking about going solo. Those conversations are what turn into work a year from now. In my case, nearly every project came from someone I'd worked with, or someone who used my code.

One warning though: I personally find new projects are getting harder and harder to come by. Part of that is the economy, and part of it is AI: work that used to be a small paid project is something clients now try to do themselves first. Remote work has fallen out of fashion again too, which matters when you don't live in a tech hub.

You should think long and hard before taking the plunge. Is it worth it? Ten years in, it's still the best working arrangement I've had, but honestly I'm not sure I'd tell you to start freelancing today. At the very least, go in knowing exactly what it takes.

## Ask me anything
If you have other questions about becoming a freelancer, feel free to ask in the comments below, or reach out directly: my details are in the author information below the article.