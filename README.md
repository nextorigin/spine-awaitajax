# spine-awaitajax

Turns Spine/jQuery Ajax requests into single-callback form, for use with await/defer

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