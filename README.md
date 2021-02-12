# loopwerk.io

The source of loopwerk.io, a static website generated with [Saga](https://github.com/loopwerk/Saga).

## Getting started
1. `git clone git@github.com:loopwerk/loopwerk.io.git`
2. `cd loopwerk.io`
3. `python3 -m venv env`
4. `. env/bin/activate`
5. `pip install -r requirements.txt`
6. `open Package.swift`


## Development server with auto reload
```
npm install --global lite-server
swift run watch content Sources deploy
```


## Publish
I'm using [Netlify](https://netflify.com) to automatically deploy this website on any commit.
