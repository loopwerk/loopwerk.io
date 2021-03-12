---
tags: faq
---

# Getting started with programming
At least twice per year someone will ask me how he or she can get started with programming. With the economy down jobs are hard to find, but there's always a need for developers, at least here in Iceland - so it's no wonder that more people are wondering how to get started.

*Not in the mood to read all these words? Here's my recommendation in a nutshell: begin with HTML and CSS, move on to Python and Django, and add Javascript. All available for free on [codecademy.com](http://www.codecademy.com/learn). Also check out [teachyourselftocode.com](http://teachyourselftocode.com) which has a lot of useful links.*

Here then is in story form a bunch of links to useful resources. Please keep in mind that this is my personal recommendation, other people will tell you to learn Ruby or Java, and these are also fine choices - just not mine :)

For me it all started in the year 2000 when I wanted to create my first website. I used to be more interested in the hardware side, having built my own computers before but not really doing much programming. Luckily HTML and CSS were incredibly easy to learn and my first website was online in a matter of days.


## HTML and CSS
First things first: HTML and CSS are no programming languages. HTML is a markup language, which means that you can wrap your text in special tags so a web browser knows how to display the text. A simple example:

```html
<html>
	<head>
		<title>Hello World</title>
	</head>
	<body>
		<h1>This is the title</h1>
		<p>
			This is a paragraph with a
			<a href="http://www.google.com">link to Google</a>.
		</p>
	</body>
</html>
```

If you were to save this to a file called `hello.html` and open it in your browser, you would see a very simple webpage. As you can see, there is no programming involved, by which I mean there is no logic: no if-this-then-that, no databases, no dynamic pages.

CSS is used for the layout of your website, it can transform the basic black text on white background into something completely different. Everything that has to do with color, style, positioning (everything that you would call "design") is done with CSS.

Here is a simple example:

```css
body {
	background: black;
	color: white;
}

h1 {
	font-size: 20px;
	color: red;
}

p {
	margin-top: 20px;
}
```

Again, there is no logic, no hard code to write. Just a bunch of pre-defined properties which are easy to learn. Together, HTML and CSS are the building blocks with which every website is created. Therefore, this should be the first step, your first thing to learn.

### Resources
- [Web Fundamentals at codecademy.com](http://www.codecademy.com/tracks/web)
- [htmldog.com tutorials](http://htmldog.com/guides/html/beginner/)
- [webplatform.org HTML tutorials](http://docs.webplatform.org/wiki/html/tutorials)
- [webplatform.org CSS tutorials](http://docs.webplatform.org/wiki/css/tutorials)
- [w3schools.com HTML tutorials](http://www.w3schools.com/html/default.asp)
- [Mozilla Developer Network: HTML](https://developer.mozilla.org/en-US/docs/Web/HTML)
- [Mozilla Developer Network: CSS](https://developer.mozilla.org/en-US/docs/Web/CSS)


## PHP
Like I said, HTML are CSS are not actual programming languages, you won't be able to create "dynamic" websites, where some kind of logic can create different pages for different users. Think about a website where you can login with your account, where you can leave comments, where there's a ton of articles or pictures coming from a database, etc.

That's where the programming starts, and for me it started with learning PHP in 2001. Back then it was the most popular language for creating websites, but I wouldn't recommend anyone starting out now to learn this. Better to start with a modern language like Python. So, no links to resources.


## Python and Django
After I worked as a PHP developer for nine year I decided enough was enough; I needed something new. And this something new was to be Python, a popular language for creating dynamic websites. It's also used to create apps, desktop software, games and much more. A perfect choice then with lots of room to grow and many available jobs (and usually better paying than PHP jobs too!).

When you want to build a website you normally choose a "framework": a set of tools and functions that will make your life a lot easier. A bunch of smart people have done most of the heavy lifting: all the standard repetitive stuff like talking to a database, letting users log in, saving comments to a news article and much more is all taken care off.

Arguably one of the best frameworks for Python is Django. Definitely my recommendation to pick up, also because of the many jobs that are available for Django programmers.

### Resources
- [codecademy.com: Python](https://www.codecademy.com/catalog/language/python)
- [Python Monk, interactive tutorials](http://pythonmonk.com)
- [Django documentation, including tutorials](https://docs.djangoproject.com)
- [Tango With Django, online book](http://www.tangowithdjango.com)
- [Learn Python The Hard Way, online book](http://learnpythonthehardway.org/book/)
- [Two Scoops of Django, book](https://django.2scoops.org)
- [The Hitchhiker’s Guide to Python](http://docs.python-guide.org/en/latest/)
- [Official Python documentation](http://www.python.org/doc/)
- [Programming Basics from khanacademy.org](http://www.khanacademy.org/cs/tutorials/programming-basics)


## Javascript
Python (and PHP) are so-called server-side languages, which means that all the logic is executed on a web server. Every time the user clicks on a button (for example to login), a request is made to the server which does all the computing and then returns a new web page to your web browser. It's a bit like ping-pong, where the client (the browser) and the server talk back and forth.

If you want to have some sort of logic or interactivity within the client you'll need Javascript. With this you will be able to do stuff like animations, video players, interactive games and much more.

### Resources
- [codecademy.com: Javascript](https://www.codecademy.com/learn/introduction-to-javascript)
- [w3schools.com Javascript tutorials](http://www.w3schools.com/js/default.asp)
- [jQuery Learning Center](http://learn.jquery.com)
- [webplatform.org Javascript tutorials](http://docs.webplatform.org/wiki/javascript/tutorials)
- [Mozilla Developer Network: Javascript](https://developer.mozilla.org/en-US/docs/JavaScript)


## Objective-C
In 2010 I started to create iPhone and iPad apps, and for this I needed to learn another programming language: Objective-C. More than that though, creating apps is completely different from creating websites, there are so many new concepts to learn (memory management and background threads being the big two). Thankfully there are a lot of very good resources so getting started with iOS development isn't too hard once you have some programming experience.

### Resources
- [Apple's Getting Started guide](http://developer.apple.com/library/ios/referencelibrary/GettingStarted/RoadMapiOS/index.html)
- [Coding Together: Developing Apps for iPhone and iPad (Winter 2013)](https://itunes.apple.com/course/coding-together-developing/id593208016?l=en)
- [WWDC session videos](https://developer.apple.com/wwdc/videos/)
- [C tutorial for Cocoa](http://cocoadevcentral.com/articles/000081.php)
- [Learn Objective-C](http://cocoadevcentral.com/d/learn_objectivec/)
