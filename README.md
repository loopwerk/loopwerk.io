<p align="center">
  <img src="logo.png" width="200" alt="tag-changelog" />
</p>

# loopwerk.io
The source of loopwerk.io, a static website generated with [Saga](https://github.com/loopwerk/Saga).

## Getting started
1. `brew install gd`
2. `git clone git@github.com:loopwerk/loopwerk.io.git`
3. `cd loopwerk.io`
4. `open Package.swift`

A standard build from Xcode or the command line (`swift run`) skips the `createArticleImages` step, since it's rather slow. To include this step as well, run `swift run Loopwerk createArticleImages` from the command line.

## Development server with auto reload
```
pnpm add --global browser-sync
swift run watch content Sources deploy
```

This builds the website and creates a static server showing the contents of the `deploy` folder. It then watches for changes in the `content` and `Sources` folders, recreates the website, and refreshes the browser.