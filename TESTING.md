# Testing the Cookbook #

This cookbook uses [bundler](http://gembundler.com/), [berkshelf](http://berkshelf.com/), and [strainer](https://github.com/customink/strainer) to isolate dependencies and run tests.

Tests are defined in [Strainerfile](Strainerfile), which in turn calls rubocop, knife, foodcritic and chefspec.

To run the tests:

    $ bundle install --path=.bundle # install gem dependencies
    $ bundle exec berks install --path=.cookbooks # install cookbook dependencies
    $ bundle exec strainer test -s Strainerfile # run tests

## Rubocop  ##

[Rubocop](https://github.com/bbatsov/rubocop) is a static Ruby code analyzer, based on the community [Ruby style guide](https://github.com/bbatsov/ruby-style-guide). We are attempting to adhere to this where applicable, slowly cleaning up the cookbooks until we can turn on Rubocop for gating the commits.

## Knife ##

[knife cookbook test](http://docs.opscode.com/chef/knife.html#test) is used to check the cookbook's Ruby and ERB files for basic syntax errors.

## Foodcritic ##

[Foodcritic](http://acrmp.github.io/foodcritic/) is a lint tool for Chef cookbooks. We ignore the following rules:

[FC003](http://acrmp.github.io/foodcritic/#FC003) these cookbooks are not intended for Chef Solo.

## Chefspec

[ChefSpec](http://code.sethvargo.com/chefspec/) is a unit testing framework for testing Chef cookbooks. ChefSpec makes it easy to write examples and get fast feedback on cookbook changes without the need for virtual machines or cloud servers.
