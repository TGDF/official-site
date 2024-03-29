Taipei Game Developer Forum Official Site
===
[![Rails](https://github.com/TGDF/official-site/actions/workflows/main.yml/badge.svg)](https://github.com/TGDF/official-site/actions/workflows/main.yml) [![Test Coverage](https://api.codeclimate.com/v1/badges/d73d789d1d5f95957421/test_coverage)](https://codeclimate.com/github/TGDF/official-site/test_coverage) [![Maintainability](https://api.codeclimate.com/v1/badges/d73d789d1d5f95957421/maintainability)](https://codeclimate.com/github/TGDF/official-site/maintainability)

This is a Rails application for [Taipei Game Developer Forum](https://tgdf.tw) to building a website for their annual event site.

## Requirements

* Ruby 2.7.5+
* PostgreSQL 9.6+
* Node.js 8.0+
  * Yarn 1.2.1+

## Development

### Setup

We already setup for install environments, just execute setup script.

```
$ ./bin/setup
```

And make sure you are installed `foreman` to start server

```
$ gem install foreman
```

Notice that this project use [carrierwave](https://github.com/carrierwaveuploader/carrierwave#adding-versions) gem as file uploader, make sure you have installed its dependency imagemagick [mentioned here](https://github.com/carrierwaveuploader/carrierwave#adding-versions)

### Starting Server

We use `Procile` to define which process have to start for development.

```
$ foreman start
```

### Style Guide

To keep the code quality before you commit and push code please running the lint script.


We use `overcommit` gem to automatic hook on git, please run above commit after setup.

```
$ bundle exec overcommit --install
```

## Contribute

We are welcome to receive yours issue and pull request, if you found any problem about our system.
