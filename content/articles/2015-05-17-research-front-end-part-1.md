---
tags: javascript
---

# Researching front end tools, part 1: Ampersand.js, React, Webpack, PostCSS and ESLint
Since early 2014 I've been building a fairly large and complex JavaScript app in [AngularJS](https://angularjs.org), using [Less](http://lesscss.org) as the CSS pre-processor and [Gulp](http://gulpjs.com) as the build system. I haven't used ES6 or modules so far, via Browserify or otherwise. While it works and overall I'm pretty happy with Angular and the architecture of the app, I am very interested in what else is out there. Not in the least because Angular 1 is going the way of the dodo and the JavaScript world is moving very fast. It seems like a new framework pops up every month, and I want to do some proper research into the available options and best practices.

In other words: if I had to start a brand new native webapp now, what would I use? Switch to Angular 2? Or move to something smaller, more modular, and not in developer preview? What would the build system look like?

My main wishes: highly modular, everything installed via NPM. ES6/ES7. Good performance and small payload. Easy to understand tools with good documentation. As few build tool dependencies as possible. And last but not least: JS for everything.

The build system should auto-reload the browser on code changes (in dev mode) and create a minified production build with a single command that can then be uploaded to something like [surge](https://surge.sh).

I want to adopt a well documented code style, and look into tools to enforce this style. And finally, I really should look into testing. Even if I wouldn't adopt test driven development, it would be very nice to have small components that could easily be tested. I only have a tiny bit of experience with front-end testing tools, none of it very good. For me to really start to adopt this, the tools should be simple and consistent.

In a series of blog posts I'm going to describe my adventure to find my ideal set of frameworks, libraries and tools for front-end development. All code will be pushed to [kevinrenskers/js-skeleton](https://github.com/kevinrenskers/js-skeleton), with a different branch for each experiment.

Here's part one.

## Experiment 1: Ampersand.js, React, Webpack, PostCSS and ESLint
My first experiment was to use Ampersand.js, React, Webpack and PostCSS, mainly because of the free video tutorials at [learn.humanjavascript.com](http://learn.humanjavascript.com/react-ampersand). You can find the code for this experiment on my [ampersand-react-webpack](https://github.com/kevinrenskers/js-skeleton/tree/ampersand-react-webpack) branch.

### ESLint and AirBnB code style
A while ago I was looking into picking a JavaScript code style for my AngularJS project at work so that the entire team can write in the same consistent style, with automatic checks for problems. I came across the [AirBnB code style](https://github.com/airbnb/javascript) and really liked what I saw: this style is very close to the one I already used myself and it has great documentation in ES5 and ES6 variants. 

We adopted the AirBnB style at work and to do the automatic checking we used two linters: [JSCS](http://jscs.info) (which only checks the code style) and [JSHint](http://jshint.com) (which checks for code quality issues like unused variables). This is less than ideal, to have two packages to configure and depend on. So my first experiment started with searching for an easier way to lint code.

I started by looking into the [JavaScript Standard Style](https://github.com/feross/standard) project which is a linter with zero configuration: you take it all or nothing. You go from two dependencies and two configuration files to just one dependency and zero config, nice. Sadly I don't like the style and found the checker to be too monolithic as well: it has hardcoded support for React for example. What if I end up using something completely different? This doesn't feel right to me.

With the JavaScript Standard Style decided against, I tried [ESLint](http://eslint.org) since the AirBnB code style repository came with a ready-made configuration for it. That configuration file did need a little bit of tweaking but it works pretty good in the end. I'm also using eslint-plugin-react for more React specific rules. This means that I still have two dependancies but one is a plugin for the other which is better than two completely separate packages that check different things.

### React
Everybody seems to be pretty much in love with [React](https://facebook.github.io/react/index.html) so I wanted to try it out for myself. It's the main reason why I started to watch the videos on the [learn.humanjavascript.com](http://learn.humanjavascript.com/react-ampersand) site in the first place. React is just the V in MVC and the views are a weird mixture of JavaScript and inline HTML code called JSX:

```javascript
export default React.createClass({
  displayName: 'TodoPage',

  getInitialState() {
    return {
      items: [],
      text: ''
    };
  },

  onChange(e) {
    this.setState({
      text: e.target.value
    });
  },

  handleSubmit(e) {
    e.preventDefault();
    this.setState({
      items: this.state.items.concat([this.state.text]),
      text: ''
    });
  },

  render() {
    return (
      <div>
        <h1>TODO</h1>
        <TodoList items={this.state.items} />
        <form onSubmit={this.handleSubmit}>
          <input onChange={this.onChange} value={this.state.text} />
          <button>{'Add #' + (this.state.items.length + 1)}</button>
        </form>
        <p><Link href="/">Back to home</Link></p>
      </div>
    );
  }
});
```

To be honest, I'm not in love with this syntax, I actually like the Angular way of having separate HTML templates that you give extra power via new tags and attributes (for example `ng-repeat`). But I think I could get used to it and it's certainly not a deal breaker. My biggest problem with React is not the syntax but the size: my extremely simple app is 141 KB big, and most of that is React.

### ES6
One of my goals was to use ES6 as much as possible, but for React components I found it more of a burden actually. You could use `class MyComponent extends React.Component {}` instead of `var MyComponent = React.createClass({ })` but since ES6 classes can't have properties you can't put the displayName or propTypes into the class itself. You could use the ES7 class properties but that's in a very early stage and you'd still have to deal with the `this` [binding problem](https://facebook.github.io/react/blog/2015/01/27/react-v0.13.0-beta-1.html#autobinding) as well. In the end, for me, it's easier to just stick with the `React.createClass` way.

### Ampersand.js and routing
Since React only offers the view layer, I used [Ampersand.js](http://ampersandjs.com) for the app singleton and router. In a real world app you'd probably also use it for models, collections, events, etc.

I really like the philosophy of Ampersand.js where everything is a tiny module, published separately on NPM. My biggest problem when using it with React was that I needed to create a special Link component because if you simply use something like `<a href="/todo">Todo</a>` you end up with full page reloads.

```javascript
export default React.createClass({
  displayName: 'Link',

  propTypes: {
    children: React.PropTypes.string.isRequired,
    href: React.PropTypes.string.isRequired
  },

  go(e) {
    e.preventDefault();
    app.router.navigate(this.props.href);
  },

  render() {
    return <a href={this.props.href} onClick={this.go}>{this.props.children}</a>;
  }
});
```

You then use this component like this: `<Link href="/todo">Todo</Link>`. It's not a huge problem of course, but if I'd use something like [react-mini-router](https://github.com/larrymyers/react-mini-router) this wouldn't be necessary at all because all anchor elements will have their clicks automatically captured, and if their href matches one of the routes, the route handler will be called.

Still, react-mini-router is 10 KB on top of an already big React, just to get rid of that Link component. Worth it or not? If I'd write a real app I'd also want to use nested routes, in which case yes, it would be worth it.

So, what would I actually use Ampersand.js for? Just models? Wouldn't there be a more React specific solution for that? I have the feeling that I could get rid of Ampersand.js altogether very easily. I'll revisit react-mini-router in an upcoming experiment.

### Webpack
Webpack is both a blessing and a curse. Until now I've used Gulp as my build system but didn't use modules yet (because, well, AngularJS). The reason why I used Webpack instead of Browserify or something else in this first experiment was simple: it's what the video tutorials used. I like the functionality that it offers, for example the ability to import CSS into my components. I'd like to look into local CSS scope in a future experiment but already this was a nice feature to have. But the configuration file... ouch. 

I'll definitely try to make a version of this experiment using Browserify instead of Webpack. I'm curious what I'd loose, what I'd gain. Probably a bigger but easier to understand build system. I'm wondering if Browserify would also support importing CSS somehow. I'll look into this.

### PostCSS
I've used Less for a long time and I'm a pretty big fan. But recently I heard about [PostCSS](https://github.com/postcss/postcss) and was very interested. It's very modular and by choosing some plugins you can use CSS variables, nested syntax, mixins and basically everything else that Less (and Sass) have to offer. It also have very good minification plugins that can for example merge selectors and rules. In the end I'm not totally convinced that I should use PostCSS for everything, maybe I could still use Less as the pre-processor and then use PostCSS as the post-processor for production builds only. It would get rid of quite some dependancies. On the other hand, it is nice to use the same system for everything. I'll have to revisit this at some point.

### Conclusions
* AirBnB code style: simply awesome.
* ESLint: I'm very happy with this solution and don't see a need to revisit this.
* React: I could get used to JSX but React is too big. I'd love to replace this with something else.
* Ampersand: not really seeing the use for this yet.
* Webpack: nice features but horrible config. I definitely want to look into Browserify.
* PostCSS: what if I only use the minifinication plugins and keep using Less as the pre-processor?

## Up next
The biggest problem I found in this first experiment was the size of React, so in the next one I'm going to look into replacing React with [Deku](https://github.com/dekujs/deku). It's very similar to React, it even uses JSX, but is only 10 KB small. Quite a big difference!

Other frameworks and libraries that I'm going to look into in the future are [Riot](https://muut.com/riotjs/), [Mithril](https://lhorie.github.io/mithril/), [Angular 2](https://angular.io) and [Aurelia](http://aurelia.io) but first: Deku. Stay tuned for the next post!
