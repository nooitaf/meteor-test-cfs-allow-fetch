cl = (something) ->
  console.log(something)

config = admin: email: 'webmaster@example.com', password: '123456'

if Meteor.isServer
  Meteor.startup ->
    if Meteor.users.find().count() is 0
      seedUserId = Accounts.createUser
        email: config.admin.email,
        password: config.admin.password

if Meteor.isClient
  # photoStore = new FS.Store.FileSystem 'photos'
  photoStore = new FS.Store.GridFS 'photos'

if Meteor.isServer
  photoStore = new FS.Store.GridFS 'photos',
    # mongoUrl: 'mongodb://127.0.0.1:27017/test/', # optional, defaults to Meteor's local MongoDB
    # mongoOptions: {...},  # optional, see note below
    # transformWrite: myTransformWriteFunction, # optional
    # transformRead: myTransformReadFunction, # optional
    # maxTries: 1, # optional, default 5
    # chunkSize: 1024*1024  # optional, default GridFS chunk size in bytes (can be overridden per file).
    #                      # Default: 2MB. Reasonable range: 512KB - 4MB
    {}

Photos = new FS.Collection 'photos',
  stores: [photoStore]
  filter: allow: contentTypes: ['image/*'] # allow only images in this FS.Collection

Photos.allow
  insert: (userId, file) ->
    userId and file.metadata?.userId is userId
  update: (userId, file, fieldNames, modifier) ->
    userId and file.metadata?.userId is userId
  remove: (userId, file) ->
    userId and file.metadata?.userId is userId
  download: (userId, file, shareId) ->
    true
  fetch: ['metadata.userId','original'] # TODO: https://github.com/CollectionFS/Meteor-CollectionFS/issues/518

if Meteor.isClient
  Template.hello.events
    'change input[type="file"]': (event, template) ->
      files = event.target.files
      count = files.length
      i = 0
      while i < count
        newFile = new FS.File(files[i])
        newFile.metadata = userId: Meteor.userId()
        # file.status = 'notReady'
        Photos.insert newFile, (error, file) ->
          throw error if error
          # If !error, we have inserted new doc with ID fileObj._id, and
          # kicked off the data upload using HTTP
          cl file._id
        i++
  Template.hello.helpers
    photos: ->
      Photos.find()

if Meteor.isServer
  Meteor.publish 'photos', (limit) ->
    check(arguments, [Match.Any])
    [
      Photos.find({}, {limit: limit})
    ]

if Meteor.isClient
  Meteor.subscribe 'photos', 100
