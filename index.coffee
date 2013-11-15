Mongoose = require 'mongoose'
Q        = require 'q'

exec = Mongoose.Query.prototype.exec
pre  = Mongoose.Document.prototype.pre
hook = Mongoose.Document.prototype.hook
post = Mongoose.Document.prototype.post

Mongoose.Query.prototype.exec = () ->
  deferred = Q.defer()

  exec.call @, (err, result) ->
    if err then deferred.reject(err) else deferred.resolve(result)
  
  return deferred.promise

Mongoose.Document.prototype._original_save = Mongoose.Model.prototype.save

Mongoose.Model.prototype.save = () ->
  deferred = Q.defer()

  @_original_save (err, doc, found) ->
    if err
      deferred.reject err
    else if not found
      deferred.reject new Error('Document not found')
    else
      deferred.resolve doc
  
  return deferred.promise

Mongoose.Document.prototype.pre = Mongoose.Document.pre = (name, args...) ->
  if (name == 'save')
    name = '_original_save'

  args.unshift(name)
  pre.apply(@, args)

Mongoose.Document.prototype.post = Mongoose.Document.post = (name, args...) ->
  if (name == 'save')
    name = '_original_save'

  args.unshift(name)
  post.apply(@, args)

Mongoose.Document.prototype.hook = Mongoose.Document.hook = (name, args...) ->
  if (name == 'save')
    name = '_original_save'

  args.unshift(name)
  hook.apply(@, args)

module.exports = Mongoose