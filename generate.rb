# generate.rb (alias: generate.thor)
# Quick thor generator to make playbook pages less tedious
#
# USAGE:
#   thor generate:section_link Introduction "Purpose and Scope"
#

require 'thor'
require 'active_support/core_ext/string'

class Generate < Thor

    PLAYBOOK_PATH = File.join(__dir__, "_playbook")
    TEMPLATE_PATH = File.join(__dir__, "templates")

    include Thor::Actions

    def self.source_root
        TEMPLATE_PATH
    end


    desc "section_link CHAPTER SECTION", "Add markdown section link to nav child links, use pretty args"
    method_option :order, :type => :numeric, :aliases => '-o'
    def section_link(parent, section)
        @parent = parent
        @title = section

        parent = parent.gsub(' ', '_').downcase.underscore
        section = section.gsub(' ', '_').downcase.underscore

        @permalink = "/#{parent}##{section.dasherize}"

        if options[:order]
            @prder = options[:order].to_i
        else # count files in _playbook/<parent>/ to derive link order number
            parent_dirname = Dir.children(PLAYBOOK_PATH).select { |subdir| subdir.upcase.match? parent.upcase }.first
            @order = Dir.children( File.join(PLAYBOOK_PATH, parent_dirname) ).reject { |f| f.starts_with? '.' }.length
            say("Identified directory #{parent_dirname} for #{@parent}, using order #{@order}", :yellow)
        end
        order_str = (@order > 9) ? @order.to_s : "0#{@order}"

        file_path = File.join(PLAYBOOK_PATH, parent_dirname, "#{order_str}_#{section}.md")
        
        template("section_link.md.erb", file_path);
    end

end
