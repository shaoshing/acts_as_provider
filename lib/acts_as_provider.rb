
module ActsAsProvider
  
  def self.included o
    o.class_eval do
      extend ClassMethods
      include InstanceMethods
    end
  end
  
  module ClassMethods
    def provider 
      @aap_provider ||= Provider.new
    end
    def acts_as_provider &block
      provider.describe &block
    end
  end
  
  module InstanceMethods
    def provide fields
      self.class.provider.provide( self, (fields || []) )
    end
  end
  
  class Provider
    attr_accessor :sources
    
    def initialize
      @sources = []
    end
    
    def provide target, fields
      result = {}
      fields.each do |field|
        found = false
        @sources.each do |source|
          begin
            if field =~ source[:matcher] && eval("target.#{source[:append_str]}respond_to? :#{$'}")
              result[field] = eval("target.#{source[:append_str]}#{$'}")
              found = true
              break
            end
          rescue Exception => e
            raise Error.new("#{target.class} can not provide [#{field}] !\n Exception : #{e.message}。\n Provider info：#{target.inspect}。")
          end
        end
        raise Error.new("#{target.class} can not provide [#{field}], provider info：#{target.inspect} ") unless found
      end
      result
    end
    
    def describe &block
      self.instance_eval &block
      add_previous_source
    end
        
    def add
      add_previous_source
      @str = ""
      self
    end
    
    # matcher 用于匹配 field 是否满足条件
    # append_str 用于生成调用相应函数的代码
    #   具体使用参考 Provider.provide
    def add_previous_source
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