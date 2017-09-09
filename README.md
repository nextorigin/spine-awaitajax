# spine-awaitajax

[![Greenkeeper badge](https://badges.greenkeeper.io/nextorigin/spine-awaitajax.svg)](https://greenkeeper.io/)

[![Build Status][ci-master]][travis-ci]
[![Coverage Status][coverage-master]][coveralls]
[![Dependency Status][dependency]][david]
[![devDependency Status][dev-dependency]][david]
[![Downloads][downloads]][npm]

Turns Spine/jQuery Ajax requests into single-callback form, for use with await/defer

[![NPM][npm-stats]][npm]

### What?

Iced CoffeeScript and tamejs offer the await/defer construct that lends itself well to the node-style async pattern callback(err, response), particularly when using a construct like errify/make_esc from iced error.

awaitajax lets you have your await and easy jQuery.ajax() -style options too. By building on iced, AJAX calls can be easily handled in one line.

### Example

Regular
```coffee
await Ajax.awaitGet {url: "https://www.google.com"}, defer err, response
```

Serial
```coffee
await Ajax.awaitQueuedGet {url: "https://www.google.com"}, defer err, response
await Ajax.awaitQueuedGet {url: "http://siteaftergoogle.com"}, defer err, response
```


### License

MIT


  [ci-master]: https://img.shields.io/travis/nextorigin/spine-awaitajax/master.svg?style=flat-square
  [travis-ci]: https://travis-ci.org/nextorigin/spine-awaitajax
  [coverage-master]: https://img.shields.io/coveralls/nextorigin/spine-awaitajax/master.svg?style=flat-square
  [coveralls]: https://coveralls.io/r/nextorigin/spine-awaitajax
  [dependency]: https://img.shields.io/david/nextorigin/spine-awaitajax.svg?style=flat-square
  [david]: https://david-dm.org/nextorigin/spine-awaitajax
  [dev-dependency]: https://img.shields.io/david/dev/nextorigin/spine-awaitajax.svg?style=flat-square
  [david-dev]: https://david-dm.org/nextorigin/spine-awaitajax#info=devDependencies
  [downloads]: https://img.shields.io/npm/dm/spine-awaitajax.svg?style=flat-square
  [npm]: https://www.npmjs.org/package/spine-awaitajax
  [npm-stats]: https://nodei.co/npm/spine-awaitajax.png?downloads=true&downloadRank=true&stars=true
