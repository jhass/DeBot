require 'cinch'

class PluginManager < Cinch::PluginList
  attr_reader :root_path
  attr_writer :root_path
  
  def initialize(bot, opts={})
    @root_path = opts.delete(:root_path) || './plugins'
    @loaded_paths = {}
    @load_opts = {}
    super(bot)
  end
  
  def load_plugins(plugins)
    plugins.each { |plugin_name| load_plugin plugin_name }
  end
  
  def load_plugin(plugin_name, opts={})
    load_opts = opts.dup
    load_path = opts.delete(:require) if opts.has_key?(:require)
    load_path ||= load_path_from_name(plugin_name)
    load_path += ".rb" unless load_path.end_with?(".rb")
    raise ArgumentError, "#{load_path} already loaded" if @loaded_paths.values.include?(load_path)
    Kernel.load load_path
    Kernel.load opts.delete(:patch) if opts.has_key?(:patch)
    plugin_sym = opts.delete(:class) if opts.has_key?(:class)
    plugin_sym ||= plugin_name_to_sym(plugin_name)
    begin
      plugin = const_get plugin_sym.to_sym
    rescue NameError
      raise ArgumentError, "#{load_path} doesn't include a class named #{plugin_sym}"
    end
    @loaded_paths[plugin] = load_path
    @load_opts[plugin] = load_opts
    @bot.config.plugins.options[plugin] = opts unless opts.empty?
    self.register_plugin plugin
  end

  def unload_all(remove_options=false)
    unload_plugins(self, remove_options)
  end
  
  def unload_plugins(plugins, remove_options=false)
    plugins.each {|plugin_name| unload_plugin plugin_name, remove_options }
  end
  
  def unload_plugin(plugin_name, remove_options=false)
    # load_path = case plugin_name.class
                # when Class then load_path_from_constant plugin_name
                # when Module then load_path_from_constant plugin_name
                # else load_path_from_name plugin_name end
    # plugin_sym = case plugin_name.name.to_sym
                 # when String then plugin_name_to_sym plugin_name
                 # when Symbol then plugin_name_to_sym plugin_name.to_s
                 # else constant_to_sym plugin_name end
    # plugin = const_get plugin_sym
    if plugin_name.is_a?(String) || plugin_name.is_a?(Symbol)
    else
      plugin = plugin_name
      plugin_sym = plugin.name.to_sym
    end
    
    raise ArgumentError, "#{plugin_name} not loaded" unless @loaded_paths.keys.include?(plugin)
    
    @loaded_paths.delete(plugin)
    self.unregister_plugin self.select {|p| p.class.plugin_name == plugin.plugin_name }.first
    @bot.config.plugins.options.delete[plugin] if @bot.config.plugins.options.has_key?(plugin) && remove_options
    from, plugin_sym = get_parent_const_and_child_sym plugin_sym
    from.send(:remove_const, plugin_sym)
  end
  
  def reload_plugin(plugin)
    opts = @load_opts[plugin].dup || {}
    name = plugin.plugin_name.dup
    unload_plugin(plugin) if loaded?(plugin)
    load_plugin(name, opts)
  end
  
  def loaded?(plugin)
    @loaded_paths.keys.include?(plugin)
  end

  private
  def load_path_from_name(plugin_name)
    load_path = File.join(@root_path, plugin_name.to_s+".rb")
    raise ArgumentError, "couldn't find #{load_path}" unless File.exists?(load_path) && File.file?(load_path)
    load_path
  end
  
  def load_path_from_constant(plugin)
    @loaded_paths[plugin] || load_path_from_name(plugin.name.gsub(/(^[A-Z])/) {|m| m.downcase }.gsub(/([A-Z0-9])/) {|m| "_#{m.downcase}" })
  end
  
  def plugin_name_to_sym(plugin_name)
    plugin_name.to_s.gsub(/((^|_)[a-z])/) { |m| m.gsub("_", "").upcase }.to_sym
  end
  
  def constant_to_sym(constant)
    constant.name.to_sym
  end
  
  def const_get(symbol, from=Object)
    from, symbol = get_parent_const_and_child_sym symbol
    from.const_get(symbol)
  end
  
  def get_parent_const_and_child_sym(symbol, from=Object)
    s = symbol.to_s
    if s.include?("::")
      modules = s.split("::")
      symbol = modules.pop.to_sym
      modules.each do |mod|
        from = from.const_get(mod.to_sym)
      end
    end
    [from, symbol]
  end
end
