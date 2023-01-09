# generate.rb (alias: generate.thor)
# Quick thor generator to make playbook pages less tedious
#
# USAGE:
#   thor generate:section_link Introduction "Purpose and Scope"
#

require 'thor'
require 'active_support/core_ext/string'
require 'fileutils'

class Generate < Thor

    PLAYBOOK_PATH = File.join(__dir__, "_playbook")
    TEMPLATE_PATH = File.join(__dir__, "templates")

    include Thor::Actions

    def self.source_root
        TEMPLATE_PATH
    end


    desc "chapter TITLE", "Add a new chapter in playbook collection"
    method_option :dirname, :type => :string, :aliases => '-d'
    method_option :permalink, :type => :string, :aliases => '-p'
    def chapter(title)
        @title = title
        @dirname = options[:dirname] || title.downcase.gsub(' ', '_').underscore
        @permalink = options[:permalink] || @dirname.dasherize
        dirpath = File.join(PLAYBOOK_PATH, @dirname)
        @order = count_pages(PLAYBOOK_PATH)

        FileUtils.mkdir_p( dirpath )
        template('index.md.erb', File.join(dirpath, 'index.md'))
    end

    desc "page TITLE", "Add a new page in a playbook chapter"
    method_option :filename, :type => :string, :aliases => '-f'
    method_option :permalink, :type => :string, :aliases => '-p'
    method_option :chapter, :type => :string, :aliases => '-c'
    method_option :dirname, :type => :string, :aliases => '-d', :required => true
    method_option :order, :type => :numeric, :aliases => '-o'
    def page(title)
        @title = title
        @filename = options[:filename] || title.downcase.gsub(' ', '_').underscore
        @chapter = options[:chapter] || options[:dirname].titleize
        @permalink = options[:permalink] || File.join( options[:dirname], @filename.dasherize )
        @order = options[:order] || count_pages(File.join(PLAYBOOK_PATH, options[:dirname]))
        path = File.join(PLAYBOOK_PATH, options[:dirname], @filename += '.md')

        template('page.md.erb', path)
    end

    desc "section_link CHAPTER SECTION", "Add markdown section link to nav child links, use pretty args"
    method_option :order, :type => :numeric, :aliases => '-o'
    def section_link(parent, section)
        @parent = parent
        @title = section

        parent = parent.gsub(' ', '_').downcase.underscore
        section = section.gsub(' ', '_').downcase.underscore

        @permalink = "/#{parent.dasherize}##{section.dasherize}"

        if options[:order]
            @order = options[:order].to_i
        else # count files in _playbook/<parent>/ to derive link order number
            parent_dirname = Dir.children(PLAYBOOK_PATH).select { |subdir| subdir.upcase.match? parent.upcase }.first
            @order = Dir.children( File.join(PLAYBOOK_PATH, parent_dirname) ).reject { |f| f.starts_with? '.' }.length
            say("Identified directory #{parent_dirname} for #{@parent}, using order #{@order}", :yellow)
        end
        order_str = (@order > 9) ? @order.to_s : "0#{@order}"

        file_path = File.join(PLAYBOOK_PATH, parent_dirname, "#{order_str}_#{section}.md")
        
        template("section_link.md.erb", file_path);
    end


    private

    # count number of markdown files in directory
    def count_pages(dir_path)
        Dir.children(dir_path).select { |f| f.ends_with? '.md' }.length
    end

end
