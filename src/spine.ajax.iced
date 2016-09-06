Spine   = @Spine or require "spine"
{Model} = Spine
iced    = require "iced-runtime"
{Pipeliner, Rendezvous} = iced


Ajax =
  getURL: (object) ->
    if object.className?
      @generateURL(object)
    else
      @generateURL(object, encodeURIComponent(object.id))

  getCollectionURL: (object) ->
    @generateURL(object)

  getScope: (object) ->
    object.scope?() or object.scope

  getCollection: (object) ->
    if object.url isnt object.generateURL
      if typeof object.url is 'function'
        object.url()
      else
        object.url
    else if object.className?
      object.className.toLowerCase() + 's'

  generateURL: (object, args...) ->
    collection = Ajax.getCollection(object) or Ajax.getCollection(object.constructor)
    scope = Ajax.getScope(object) or Ajax.getScope(object.constructor)
    args.unshift(collection)
    args.unshift(scope)
    # construct and clean url
    path = args.join('/')
    path = path.replace /(\/\/)/g, "/"
    path = path.replace /^\/|\/$/g, ""
    # handle relative urls vs those that use a host
    if path.indexOf("../") isnt 0
      Model.host + "/" + path
    else
      path

  enabled: true

  disable: (callback) ->
    if @enabled
      @enabled = false
      try
        do callback
      catch e
        throw e
      finally
        @enabled = true
    else
      do callback

  max: 100
  throttle: 0

  queue: (request) ->
    @pipeliner or= new Pipeliner @max, @throttle
    return @pipeliner.queue unless request
    await @pipeliner.waitInQueue defer()
    request @pipeliner.defer()

  clearQueue: ->
    return unless @pipeliner
    @pipeliner.queue = []
    @pipeliner.n_out = 0

class Base
  defaults:
    contentType: 'application/json'
    dataType: 'json'
    processData: false
    headers: {'X-Requested-With': 'XMLHttpRequest'}

  queue: Ajax.queue.bind Ajax

  ajax: (params, defaults) ->
    new $.ajax @ajaxSettings(params, defaults)

  ajaxQueue: (params, defaults) ->
    xhr = null
    rv  = new iced.Rendezvous
    __iced_deferrals = null

    settings     = @ajaxSettings(params, defaults)
    defersuccess = settings.success
    defererror   = settings.error

    settings.success = rv.id('success').defer data, statusText, xhr
    settings.error   = rv.id('error').defer xhr, statusText, error

    request = (next) ->
      Ajax.pipeliner.window = if settings.type is 'GET' then Ajax.max else 1
      xhr = new $.ajax(settings)
      await rv.wait defer status
      switch status
        when 'success' then defersuccess data, statusText, xhr
        when 'error' then defererror xhr, statusText, error
      next()

    request.abort = (statusText) ->
      return xhr.abort(statusText) if xhr
      index = @queue().indexOf(request)
      @queue().splice(index, 1) if index > -1
      Ajax.pipeliner.n_out-- if Ajax.pipeliner

      # deferred.rejectWith(
      #   settings.context or settings,
      #   [xhr, statusText, '']
      # )
      request

    return request unless Ajax.enabled
    @queue request
    request

  ajaxSettings: (params, defaults) ->
    $.extend({}, @defaults, defaults, params)

class Collection extends Base
  constructor: (@model) ->

  find: (id, params) ->
    record = new @model(id: id)
    @ajaxQueue params,
      type: 'GET',
      url:  Ajax.getURL(record)
      success: @recordsResponse
      error: @failResponse

  all: (params) ->
    @ajaxQueue params,
      type: 'GET',
      url:  Ajax.getURL(@model)
      success: @recordsResponse
      error: @failResponse

  fetch: (params = {}) ->
    if id = params.id
      delete params.id
      @find(id, params)
    else
      @all(params)

  # Private

  recordsResponse: (data, status, xhr) =>
    @model.trigger('ajaxSuccess', null, status, xhr)
    @model.refresh(data)

  failResponse: (xhr, statusText, error) =>
    @model.trigger('ajaxError', null, xhr, statusText, error)

class Singleton extends Base
  constructor: (@record) ->
    @model = @record.constructor

  reload: (params, options) ->
    @ajaxQueue params,
      type: 'GET'
      url:  Ajax.getURL(@record)
      success: @recordResponse(options)
      error: @failResponse(options)

  create: (params, options) ->
    @ajaxQueue params,
      type: 'POST'
      data: JSON.stringify(@record)
      url:  Ajax.getURL(@model)
      success: @recordResponse(options)
      error: @failResponse(options)

  update: (params, options) ->
    @ajaxQueue params,
      type: 'PUT'
      data: JSON.stringify(@record)
      url:  Ajax.getURL(@record)
      success: @recordResponse(options)
      error: @failResponse(options)

  destroy: (params, options) ->
    @ajaxQueue params,
      type: 'DELETE'
      url:  Ajax.getURL(@record)
      success: @recordResponse(options)
      error: @failResponse(options)

  # Private

  recordResponse: (options = {}) =>
    (data, status, xhr) =>
      if data? and Object.getOwnPropertyNames(data).length
        data = @model.fromJSON(data)
      else
        data = false

      Ajax.disable =>
        if data
          # ID change, need to do some shifting
          if data.id and @record.id isnt data.id
            @record.changeID(data.id)

          # Update with latest data
          @record.updateAttributes(data.attributes())

      @record.trigger('ajaxSuccess', data, status, xhr)
      options.success?.apply(@record) # Deprecated
      options.done?.apply(@record)

  failResponse: (options = {}) =>
    (xhr, statusText, error) =>
      @record.trigger('ajaxError', xhr, statusText, error)
      options.error?.apply(@record) # Deprecated
      options.fail?.apply(@record)

# Ajax endpoint
Model.host = ''

GenerateURL =
  include: (args...) ->
    args.unshift(encodeURIComponent(@id))
    Ajax.generateURL(this, args...)
  extend: (args...) ->
    Ajax.generateURL(this, args...)

Include =
  ajax: -> new Singleton(this)

  generateURL: GenerateURL.include

  url: GenerateURL.include

Extend =
  ajax: -> new Collection(this)

  generateURL: GenerateURL.extend

  url: GenerateURL.extend

Model.Ajax =
  extended: ->
    @fetch @ajaxFetch
    @change @ajaxChange

    @extend Extend
    @include Include

  # Private

  ajaxFetch: ->
    @ajax().fetch(arguments...)

  ajaxChange: (record, type, options = {}) ->
    return if options.ajax is false
    record.ajax()[type]?(options.ajax, options)

Model.Ajax.Methods =
  extended: ->
    @extend Extend
    @include Include


# Globals
Ajax.defaults           = Base::defaults
Ajax.Base               = Base
Ajax.Singleton          = Singleton
Ajax.Collection         = Collection
Spine.Ajax              = Ajax
Spine.Ajax.ModelAdapter = Ajax
Spine.Ajax.Q            = Base
module?.exports         = Ajax