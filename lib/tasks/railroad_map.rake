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
    controllers = Dir.glob("#{RAILS_ROOT}/app/controllers/**/*_controller.rb\0#{RAILS_ROOT}/vendor/plugins/*/app/controllers/**/*_controller.rb").map{|path|
      path=~/app\/controllers\/(.*)\.rb$/
      $1.classify.constantize
    }
    controllers.uniq!
    controllers.sort!{|a, b| a.name <=> b.name}

    # remove super classes
    super_controllers = controllers.inject([]) { |list, c| list << c.superclass }
    super_controllers.uniq!
    controllers -= super_controllers

    # generate controller docs
    FileUtils.mkpath(File.join(RAILS_ROOT, 'doc', 'railroad_map', 'controllers'))

    action_attributes = RailroadMap.action_attributes

    controllers.each do |c|

      action_attributes.each {|attr| attr.controller = c}

      action_analysis = c.action_methods_analysis

      path = File.join(RAILS_ROOT, 'doc', 'railroad_map', 'controllers', *c.to_s.underscore.split('/'))
      FileUtils.mkpath(path)
      File.open(File.join(path, 'index.html'), 'w') do |file|
        file.write("<html>\n")
        file.write("<head><title>#{RAILS_ROOT.split('/').last.humanize} Railroad Map Document - #{c.to_s}</title><style>th {text-align: left; padding:2px;} .applied {background-color: #ffa} .number {text-align: right; padding: 0 2px;}</style></head>\n")
        file.write("<body>\n")
        file.write("<h1>#{c.to_s}</h1>\n")

        RailroadMap.controller_details.each do |detail|
          detail.controller = c
          detail.write_headline_to(file)
          detail.write_contents_to(file)
        end

#        file.write("<h2>Actions</h2>\n")
#        file.write("<table border='1'>\n")
#        file.write("<tr>\n")
#        file.write("<th>No.</th>")
#        action_attributes.each do |attr|
#          attr.write_headers_to(file)
#        end
#        file.write("\n")
#
#        file.write("</tr>\n")
#        c.action_methods.sort do |a, b|
#          if action_analysis[a.to_s].to_s == action_analysis[b.to_s].to_s
#            a <=> b
#          elsif action_analysis[a.to_s].to_s == c.to_s
#            -1
#          elsif action_analysis[b.to_s].to_s == c.to_s
#            1
#          else
#            action_analysis[a.to_s].to_s <=> action_analysis[b.to_s].to_s
#          end
#        end.each_with_index do |a, pos|
#          action_attributes.each {|attr| attr.action = a}
#          file.write("<tr>\n")
#          file.write("<td class='number'>#{pos+1}</td>")
#          action_attributes.each do |attr|
#            attr.write_contents_to(file)
#          end
#
#          file.write("\n")
#          file.write("</tr>\n")
#        end
#        file.write("</table>\n")
        file.write("</body>\n")
        file.write("</html>\n")
      end
    end

    # generate index
    File.open(File.join(RAILS_ROOT, 'doc', 'railroad_map', 'index.html'), 'w') do |file|
      file.write("<html>\n")
        file.write("<head><title>#{RAILS_ROOT.split('/').last.humanize} Railroad Map Document</title><style>th {text-align: left; padding:2px;} .number {text-align: right; padding:0 2px;}</style></head>\n")
      file.write("<body>\n")
      file.write("<h1>#{RAILS_ROOT.split('/').last.humanize} Railroad Map Document</h1>\n")
      file.write("<h2>Controllers</h2>\n")
      file.write("<table border='1'>\n")
      file.write("<tr><th>No.</th><th >Name</th><th>Action Counts</th></tr>\n")
      controllers.each_with_index do |c, pos|
        file.write("<tr>")
        file.write("<td class='number'>#{pos + 1}</td>")
        file.write("<th><a href='controllers/#{c.to_s.underscore}/index.html'>#{c.to_s}</a></th>\n")
        file.write("<td class='number'>#{c.action_methods.size}</td>")
        file.write("</tr>\n")
      end
      file.write("</table>\n")
      file.write("</body>\n")
      file.write("</html>\n")
    end
  end
end