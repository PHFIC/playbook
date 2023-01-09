# generate.rb (alias: generate.thor)
# Quick thor generator to make playbook pages less tedious
#
# USAGE:
#   thor generate:section_link Introduction "Purpose and Scope"
#

require 'thor'
require 'active_support'

class Generate < Thor

    PLAYBOOK_PATH = File.join(__dir__, "_playbook")
    TEMPLATE_PATH = File.join(__dir__, "templates")

    include Thor::Actions

    def self.source_root
        TEMPLATE_PATH
    end


    desc "generate:section_link CHAPTER SECTION", "Add markdown section link to nav child links"
    def section_link(parent, section)
        @parent = parent
        @title = section
        @permalink = "#{parent.underscore}##{section.dasherize}"

        # count files in _playbook/<parent>/ to derive link order number
        parent_dirname = Dir.children(PLAYBOOK_PATH).select { |subdir| subdir.upcase.match? parent.underscore.upcase }.first
        say("Error: path not found for #{parent}", :red) and return if parent_dirname.nil?
        order = Dir.children( File.join(PLAYBOOK_PATH, parent_dirname) ).length
        @order = (order > 9) ? order.to_s : "0#{order}"

        file_path = File.join(PLAYBOOK_PATH, parent_dirname, "#{@order}_#{section.underscore}.md")
        
        template("section_link.md.erb", file_path);
    end

end
