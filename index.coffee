Mongoose = require 'mongoose'
Q        = require 'q'

qHandler = () ->
  deferred = Q.defer()
  handler  = (err, result...) ->
    if err
      deferred.reject err
    else if result.length == 1
      deferred.resolve result[0]
    else
      deferred.resolve result

  return {
    promise : deferred.promise
    handler : handler
  }

saveWrapper = (fnName) ->
  fn = Mongoose.Document.prototype[fnName]
  return (name, args...) ->
    if (name == 'save')
      name = '_original_save'

    args.unshift(name)
    fn.apply(@, args)

create = Mongoose.Model.create
Mongoose.Model.create = (args...) ->
  if typeof args[args.length - 1] == 'function'
    return create.apply @, args

  {promise, handler} = qHandler()

  args.push handler
  create.apply @, args

  return promise

exec = Mongoose.Query.prototype.exec
Mongoose.Query.prototype.exec = (fn) ->
  return exec.call(@, fn) if fn

  {promise, handler} = qHandler()

  exec.call @, handler
  
  return promise

Mongoose.Document.prototype._original_save = Mongoose.Model.prototype.save
Mongoose.Document.prototype.pre  = Mongoose.Document.pre  = saveWrapper('pre')
Mongoose.Document.prototype.post = Mongoose.Document.post = saveWrapper('post')
Mongoose.Document.prototype.hook = Mongoose.Document.hook = saveWrapper('hook')
Mongoose.Model.prototype.save = (fn) ->
  return @_original_save(fn) if fn

  deferred = Q.defer()

  @_original_save (err, doc, found) ->
    if err
      deferred.reject err
    else if not found
      deferred.reject new Error('Document not found')
    else
      deferred.resolve doc
  
  return deferred.promise

module.exports = Mongoose