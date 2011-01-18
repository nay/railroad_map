# RailroadMap
# 先に application_controller.rbを読み込みたいのでこう書いている
ApplicationController.class_eval do

  def self.analyze_action_methods
    result = {} # modules per action
    action_methods.each do |a|
      modules = ancestors.find_all{|m| !ApplicationController.ancestors.include?(m) && m.instance_methods(false).include?(a)}
      result[a.to_s] = modules
    end
    return result
  end

end