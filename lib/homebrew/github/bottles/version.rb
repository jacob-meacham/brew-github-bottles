module Homebrew
    module Github
        module Bottles
            VERSION = `git describe`.gsub! '-', '.'
        end
    end
end
