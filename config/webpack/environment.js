const { environment } = require('@rails/webpacker')

// Workaround for https://github.com/rails/webpacker/issues/2109
environment.loaders.delete('nodeModules')

module.exports = environment
