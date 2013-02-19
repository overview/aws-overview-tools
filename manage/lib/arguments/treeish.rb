require_relative '../argument'

module Arguments
  class Treeish
    def name
      'GIT-TREEISH'
    end

    def description
      'is a git tree-ish identifier (e.g., "origin/master", "a1cb321")'
    end

    def parse(runner, string)
      if string.nil? || string.empty?
        'origin/master'
      else
        string
      end
    end
  end
end
