[![Build Status](https://travis-ci.org/jacob-meacham/brew-github-bottles.svg?branch=develop)](https://travis-ci.org/jacob-meacham/brew-github-bottles)

[![Coverage Status](https://coveralls.io/repos/github/jacob-meacham/brew-github-bottles/badge.svg?branch=develop)](https://coveralls.io/github/jacob-meacham/brew-github-bottles?branch=develop)

[![Code Climate](https://codeclimate.com/github/jacob-meacham/brew-github-bottles/badges/gpa.svg)](https://codeclimate.com/github/jacob-meacham/brew-github-bottles)


# brew-github-bottles

The brew-github-bottles gem allows homebrew to pull bottles from github releases - including private repositories. This is especially helpful if you've created your own private Homebrew Tap and want to publish bottles without setting up an internal service.


## Installation
Unfortunately, homebrew does not make it simple to use gems from within a formula. There are a few options:

1. Use a git submodule
2. Do a local gem install and commit the installed file
3. Require all users to run gem install brew-github-bottles before running a brew install of your formula


## Usage
### Formula
Setting brew-github-bottles up is quite simple. In your formula, add

```
require "hooks/bottles"
require "homebrew/github/bottles"

github_bottle = GithubBottle.new(formula_name, repo_base_path, authorization)

Homebrew::Hooks::Bottles.setup_formula_has_bottle do |formula|
  github_bottle.bottled?(formula)
end

Homebrew::Hooks::Bottles.setup_pour_formula_bottle do |formula|
  github_bottle.pour(formula)
end
```

And that's it!

GithubBottle takes 3 parameters:
**formula_name**
This is the name of your formula in kebab-case

**repo_base_path**
The base path to your repo in Github. This should probably look like "https://api.github.com/repos/{username}/{reponame}"

**authorization**
The authorization to pass to github. This is only required if the Github repo is private. This is passed as the Authorization header to Github (see the [Github docs](https://developer.github.com/v3/oauth/)). If using token auth, the token should not be committed in the repo, and its permissions should be as constrained as possible.

### Github
This gem searches the release tagged 'bottles' for any bottles that satisfy the standard bottle naming scheme:

```
"#{formula.name}-#{formula.pkg_version}.#{bottle_tag}.bottle.tar.gz"
```

If you want to use a different naming scheme for your bottles, you can override the function file_pattern in GithubBottle:

```
class MyGithubBottle < GithubBottle
    def file_pattern(formula)
        "my-interesting-pattern.tar.gz"
    end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jacob-meacham/brew-github-bottles. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

