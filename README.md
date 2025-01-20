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

## License
This code is made publicly available to get ideas on how to create a site using [Saga](https://github.com/loopwerk/Saga), but the design and content are NOT available to copy to your site. Or in more technical terms:

The source code of this website is licensed under the MIT License. However, this license explicitly excludes the design, visual elements, and written content of the website. The design, layout, and content, including text, images, and graphics, are copyright notice may not be copied, reproduced, or distributed without prior permission.