# loopwerk.io
The source of loopwerk.io, a static website generated with [Saga](https://github.com/loopwerk/Saga).

## Getting started
1. `git clone git@github.com:loopwerk/loopwerk.io.git`
2. `cd loopwerk.io`
3. `open Package.swift`

A standard build from Xcode or the command line (`swift run`) skips the `createArticleImages` step, since it's rather slow. To include this step as well, run `swift run Loopwerk createArticleImages` from the command line. You will need to have the Python package Pillow installed for that.

## Development server with auto reload
```
npm install --global lite-server
swift run watch content Sources deploy
```

This builds the website and creates a static server showing the contents of the `deploy` folder. It then watches for changes in the `content` and `Sources` folders, recreates the website, and refreshes the browser.