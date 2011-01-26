# RailroadMap
# need to load application_controller.rb first
ApplicationController.class_eval do
  def self.action_methods_analysis
    return @action_methods_analysis if @action_methods_analysis
    @action_methods_analysis = {} # modules per action
    action_methods.each do |a|
      modules = ancestors.find_all{|m| !ApplicationController.ancestors.include?(m) && m.instance_methods(false).include?(a)}
      @action_methods_analysis[a.to_s] = modules
    end
    @action_methods_analysis
  end

  def self.named_before_filters
    @named_before_filters ||= filter_chain.find_all{|f| f.kind_of?(ActionController::Filters::BeforeFilter) && f.method.kind_of?(Symbol)}
  end

  def self.named_partial_before_filters
    @named_partial_before_filters ||= named_before_filters.find_all{|f| f.options[:only] || f.options[:except]}
  end

  def self.named_general_before_filters
    @named_general_before_filters ||= named_before_filters - named_partial_before_filters
  end
end

# output schem
module RailroadMap

  class ControllerDetail
    attr_accessor :controller

    private
    def before_filters
      raise "no controller" unless controller
      @before_filters ||= controller.filter_chain.find_all{|f| f.kind_of?(ActionController::Filters::BeforeFilter) && f.method.kind_of?(Symbol)}
    end

  end

  class ControllerGeneralBeforeFilters < ControllerDetail
    def write_headline_to(out)
      out.write("<h2>General Before Filters</h2>\n")
    end
    def write_contents_to(out)
      out.write("<ul>\n")
      controller.named_general_before_filters.each do |f|
        out.write("<li>#{f.method}</li>\n")
      end
      out.write("</ul>\n")
    end
  end

  class ControllerActions < ControllerDetail

    def controller=(c)
      super
      @action_attributes = RailroadMap.action_attributes.each {|attr| attr.controller = c}
    end

    def write_headline_to(out)
      out.write("<h2>Actions</h2>\n")
    end

    def write_contents_to(out)
      out.write("<table border='1'>\n")
      out.write("<tr>\n")
      out.write("<th>No.</th>")
      action_attributes.each do |attr|
        attr.write_headers_to(out)
      end
      out.write("\n")

      out.write("</tr>\n")
      sorted_actions.each_with_index do |a, pos|
        action_attributes.each {|attr| attr.action = a}
        out.write("<tr>\n")
        out.write("<td class='number'>#{pos+1}</td>")
        action_attributes.each do |attr|
          attr.write_contents_to(out)
        end

        out.write("\n")
        out.write("</tr>\n")
      end
      out.write("</table>\n")
    end

    private
    def action_attributes
      @action_attributes
    end

    def sorted_actions
      controller.action_methods.sort do |a, b|
        if controller.action_methods_analysis[a.to_s].to_s == controller.action_methods_analysis[b.to_s].to_s
          a <=> b
        elsif controller.action_methods_analysis[a.to_s].to_s == controller.to_s
          -1
        elsif controller.action_methods_analysis[b.to_s].to_s == controller.to_s
          1
        else
          controller.action_methods_analysis[a.to_s].to_s <=> controller.action_methods_analysis[b.to_s].to_s
        end
      end
    end
  end


  class BaseActionAttribute < ControllerDetail
    attr_accessor :action


  end

  class ActionName < BaseActionAttribute
    def write_headers_to(out)
      out.write("<th>Action Name</th>")
    end
    def write_contents_to(out)
      out.write("<td>#{action}</td>")
    end
  end

  class ActionImplementedIn < BaseActionAttribute
    def write_headers_to(out)
      out.write("<th>Implemented in</th>")
    end
    def write_contents_to(out)
      out.write("<td>#{(controller.action_methods_analysis[action.to_s]).map{|m| m.to_s}.join('<br />')}</td>")
    end
  end

  class ActionPartialFilters < BaseActionAttribute
    def write_headers_to(out)
      controller.named_partial_before_filters.each do |f|
        separated_method_name = f.method.to_s.gsub(/_/, ' _')
        out.write("<th style='width:100px; font-size: 80%;'>#{separated_method_name}</th>")
      end
    end

    def write_contents_to(out)
      controller.named_partial_before_filters.each do |f|
        applied = (f.options[:only] && f.options[:only].include?(action.to_s)) || (f.options[:except] && !f.options[:except].include?(action.to_s))
        out.write("<td class='#{applied ? 'applied' : 'notApplied'}'  style='width:100px;'>#{applied ? 'applied' : '-'}</td>")
      end
   end

  end

  CONTROLLER_DETAILS = [ControllerGeneralBeforeFilters, ControllerActions]
  ACTION_INFO = [ActionName, ActionImplementedIn, ActionPartialFilters]

  # You can override these
  def self.controller_details
    CONTROLLER_DETAILS.map{|clazz| clazz.new}
  end

  def self.action_attributes
    ACTION_INFO.map{|clazz| clazz.new}
  end
end