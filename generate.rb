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
        @order = count_pages(PLAYBOOK_PATH)

        dirpath = File.join(PLAYBOOK_PATH, @dirname)
        FileUtils.mkdir_p( dirpath )
        template('index.md.erb', File.join(dirpath, 'index.md'))
    end

    # TODO: make this cleaner and similar to generate:section_link
    desc "page TITLE [PARENT]", "Add a new page in the playbook"
    method_option :filename, :type => :string, :aliases => '-f'
    method_option :permalink, :type => :string, :aliases => '-p'
    method_option :dirname, :type => :string, :aliases => '-d'
    method_option :order, :type => :numeric, :aliases => '-o'
    method_option :children, :type => :boolean, :aliases => '-c', :default => false
    method_option :grand_parent, :type => :string, :aliases => '-g', :default => nil
    def page(title, parent = false)
        @title = title
        @parent = parent

        @filename = options[:filename] || title.downcase.gsub(' ', '_').underscore
        @grand_parent = options[:grand_parent]
        @children = options[:children]

        if options[:dirname]
            dirpath = File.join(PLAYBOOK_PATH, options[:dirname])
        elsif parent
            dirpath = File.join(PLAYBOOK_PATH, parent.downcase.dasherize)
        else
            dirpath = PLAYBOOK_PATH
        end

        @permalink = options[:permalink] || File.join( dirpath, @filename.dasherize )
        @order = options[:order] || count_pages(dirpath)
        path = File.join(dirpath, @filename += '.md')
        say("Mapping #{@permalink} to #{path}", :yellow)

        template('page.md.erb', path)
    end

    desc "section_link TITLE PARENT", "Add markdown section link to nav child links, use pretty args"
    method_option :dirname, :type => :string, :aliases => '-d'
    method_option :filename, :type => :string, :aliases => '-f'
    method_option :children, :type => :boolean, :aliases => '-c', default: false
    method_option :grand_parent, :type => :string, :aliases => '-g'
    method_option :order, :type => :numeric, :aliases => '-o'
    method_option :permalink, :type => :string, :aliases => '-p'
    def section_link(title, parent)
        @parent = parent
        @title = title

        parent = parent.gsub(' ', '_').downcase.underscore
        title = title.gsub(' ', '_').downcase.underscore

        @grand_parent = options[:grand_parent] || false
        @children = options[:children].to_s
        @permalink = options[:permalink] || "/#{parent.dasherize}##{title.dasherize}"

        # Assumes last directory if not provided
        parent_order_str = serial( count_pages( PLAYBOOK_PATH ) )
        @dirname = options[:dirname] || "#{parent_order_str}_#{parent.underscore}"
        say("Directory #{@dirname} not found", :red) unless Dir.exist? File.join(PLAYBOOK_PATH, @dirname)

        @order = options[:order]&.to_i || count_pages(File.join( PLAYBOOK_PATH, @dirname) )
        order_str = serial(@order)

        @filename = options[:filename] || "#{order_str}_#{title.underscore}"
        file_path = File.join(PLAYBOOK_PATH, @dirname, @filename += '.md')

        say("Permalink #{@permalink} will map to #{@dirname}/#{@filename} with nav order #{@order}", :yellow)
        
        template("section_link.md.erb", file_path);
    end


    private

    # count number of non-hidden files in directory
    def count_pages(dir_path)
        Dir.children(dir_path).reject { |f| f.starts_with? '.' }.length
    end

    # convert int i to 0d or dd format string
    def serial(i)
        "%02d" % i
    end

end
