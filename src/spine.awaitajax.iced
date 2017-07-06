Spine = @Spine or require "spine"


awaitAjax =
  awaitAjax: (options, cb) ->
    rv = new iced.Rendezvous()

    options.success = rv.id('success').defer data, statusText, xhr # data, statusText, xhr
    options.error   = rv.id('error').defer xhr, statusText, data # xhr, statusText, error

    if options.queue then @Q.ajaxQueue options
    else @Q.ajax options

    await rv.wait defer status
    switch status
      when "success" then cb null, data, statusText, xhr
      else
        err      = new Error statusText
        err.data = data
        err.xhr  = xhr
        cb err

  awaitGet: (options, cb, queue) ->
    options.method = 'GET'
    @awaitAjax options, cb, queue

  awaitPost: (options, cb, queue) ->
    options.method = 'POST'
    @awaitAjax options, cb, queue

  awaitQueuedAjax: (options, cb) ->
    @awaitAjax options, cb, true

  awaitQueuedGet: (options, cb) ->
    @awaitGet options, cb, true

  awaitQueuedPost: (options, cb) ->
    @awaitPost options, cb, true


Spine.Class.extend.call Spine.Ajax, awaitAjax
module?.exports = awaitAjax
