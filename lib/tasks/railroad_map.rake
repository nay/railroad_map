# desc "Explaining what the task does"
# task :railroad_map do
#   # Task goes here
# end

desc "Run railroad_map:app"
task :railroad_map => 'railroad_map:app'

namespace :railroad_map do
  desc "Generate summary documents of your application"
  task :app do
    FileUtils.mkpath(File.join(RAILS_ROOT, 'doc', 'railroad_map'))
    require File.join(RAILS_ROOT, 'config', 'environment.rb')

    # get controller classes
    controllers = Dir.glob("#{RAILS_ROOT}/app/controllers/**/*_controller.rb").map{|path|
      path=~/#{RAILS_ROOT}\/app\/controllers\/(.*)\.rb/
      $1.classify.constantize
    }

    # remove super classes
    super_controllers = controllers.inject([]) { |list, c| list << c.superclass }
    super_controllers.uniq!
    controllers -= super_controllers

    # generate controller docs
    FileUtils.mkpath(File.join(RAILS_ROOT, 'doc', 'railroad_map', 'controllers'))
    controllers.each do |c|
      path = File.join(RAILS_ROOT, 'doc', 'railroad_map', 'controllers', *c.to_s.underscore.split('/'))
      FileUtils.mkpath(path)
      File.open(File.join(path, 'index.html'), 'w') do |file|
        file.write("<html>\n")
        file.write("<head><title>#{RAILS_ROOT.split('/').last.humanize} Railroad Map Document - #{c.to_s}</title><style>th {text-align: left; padding:2px;} .applied {background-color: #ffa}</style></head>\n")
        file.write("<body>\n")
        file.write("<h1>#{c.to_s}</h1>\n")
        # get filter_names
        before_filters = c.filter_chain.find_all{|f| f.kind_of?(ActionController::Filters::BeforeFilter) && f.method.kind_of?(Symbol)}
        partial_filters = before_filters.find_all{|f| f.options[:only] || f.options[:exclude]}
        general_filters = before_filters - partial_filters
        file.write("<h2>General Before Filters</h2>\n")
        file.write("<ul>\n")
        general_filters.each do |f|
          file.write("<li>#{f.method}</li>\n")
        end
        file.write("</ul>\n")
        file.write("<h2>Actions</h2>\n")
        file.write("<table border='1'>\n")
        file.write("<tr>\n")

        file.write("<th>Action Name</th>")
        partial_filters.each do |f|
          separated_method_name = f.method.to_s.gsub(/_/, ' _')
          file.write("<th style='width:100px; font-size: 80%;'>#{separated_method_name}</th>")
        end
        file.write("\n")

        file.write("</tr>\n")
        c.action_methods.sort.each do |a|
          file.write("<tr>\n")
          file.write("<th>#{a}</th>")
          partial_filters.each do |f|
            applied = (f.options[:only] && f.options[:only].include?(a.to_s)) || (f.options[:exclude] && !f.options[:exclude].include?(a.to_s))
            file.write("<td class='#{applied ? 'applied' : 'notApplied'}'  style='width:100px;'>#{applied ? 'applied' : '-'}</td>")
          end
          file.write("\n")
          file.write("</tr>\n")
        end
        file.write("</table>\n")
        file.write("</body>\n")
        file.write("</html>\n")
      end
    end

    # generate index
    File.open(File.join(RAILS_ROOT, 'doc', 'railroad_map', 'index.html'), 'w') do |file|
      file.write("<html>\n")
        file.write("<head><title>#{RAILS_ROOT.split('/').last.humanize} Railroad Map Document</title></head>\n")
      file.write("<body>\n")
      file.write("<h1>#{RAILS_ROOT.split('/').last.humanize} Railroad Map Document</h1>\n")
      file.write("<h2>Controllers</h2>\n")
      file.write("<ul>\n")
      controllers.each do |c|
        file.write("<li><a href='controllers/#{c.to_s.underscore}/index.html'>#{c.to_s}</a></li>\n")
      end
      file.write("</ul>\n")
      file.write("</body>\n")
      file.write("</html>\n")
    end
  end
end