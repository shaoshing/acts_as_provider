
module ActsAsProvider
  
  def self.included o
    o.class_eval do
      def self.provider ; @@aap_provider ; end
      @@aap_provider = Provider.new
      extend ClassMethods
    end
  end
  
  module ClassMethods
    def acts_as_provider &block
      self.provider.describe &block
      include InstanceMethods
    end
  end
  
  module InstanceMethods
    def provide fields
      self.class.provider.provide self, (fields || [])
    end
  end
  
  class Provider
    
    attr_accessor :sources
    
    def initialize
      @sources = []
      @count = 0
    end
    
    def provide target, fields
      result = {}
      fields.each do |field|
        found = false
        @sources.each do |source|
          if field =~ source[:matcher] && eval("target.#{source[:append_str]}respond_to? :#{$'}")
            result[field] = eval("target.#{source[:append_str]}#{$'}")
            found = true
            break
          end
        end
        raise Error.new("#{target.class} can not provide [#{field}], provider info：#{target.inspect} ") unless found
      end
      result
    rescue NoMethodError
      raise Error.new("#{target.class} can not provide [#{field}], provider info：#{target.inspect} ")
    end
    
    def describe &block
      self.instance_eval &block
      add_source
    end
    
    def add
      add_source
      @str = ""
      self
    end
    
    # matcher 用于匹配 field 是否满足条件
    # append_str 用于生成调用相应函数的代码
    #   具体使用参考 Provider.provide
    def add_source
      return unless @str
      @sources << { 
        :matcher => /^#{ @str == "self." ? "" : @str.gsub(".","_")}/, 
        :append_str => "#{ @str== "self." ? "" : @str}" 
      }
    end
    
    def type ; method_missing "type" ; end  # 针对source为type的情况

    def method_missing source
      @str += "#{source}."
      self
    end
  end
  
  class Error < Exception
  end
end