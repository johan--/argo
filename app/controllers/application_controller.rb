class ApplicationController < ActionController::Base
  before_filter :fedora_setup
  
  include Rack::Webauth::Helpers

  attr_reader :help
  
  def initialize(*args)
    super
    
    klass_chain = self.class.name.sub(/Controller$/,'Helper').split(/::/)
    klass = Module.const_get(klass_chain.shift)
    while klass_chain.length > 0
      klass = klass.const_get(klass_chain.shift)
    end
    @help = Class.new {
      include klass
      include ApplicationHelper
    }.new
    self
  end
  
  protected
  def munge_parameters
    case request.content_type
    when 'application/xml','text/xml'
      help.merge_params(Hash.from_xml(request.body.read))
    when 'application/json','text/json'
      help.merge_params(JSON.parse(request.body.read))
    end
  end

  def fedora_setup
    Dor::Config.fedora.post_config
  end
  
end
