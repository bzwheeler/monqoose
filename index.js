Mongoose = require('mongoose');
Q        = require('q');

Mongoose.Query.prototype.qExec = function() {
  var deferred = Q.defer();
  this.exec(function(err, result) {
    err ? deferred.reject(err) : deferred.resolve(result);
  });
  return deferred.promise;
}

Mongoose.Model.prototype.qSave = function() {
  var deferred = Q.defer();
  this.save(function(err, doc, found) {
    if (err) {
      deferred.reject(err);
    }
    if (!found) {
      deferred.reject(new Error('Document not found'));
    }
    deferred.resolve(doc);
  });
  return deferred.promise;
}
