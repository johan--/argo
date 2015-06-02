class User < ActiveRecord::Base
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User

  attr_accessor :webauth

  def self.find_or_create_by_webauth(webauth)
    result = self.find_or_create_by(:sunetid => webauth.login)
    result.webauth = webauth
    result
  end

  def self.find_or_create_by_remoteuser username
    self.find_or_create_by(:sunetid => username)
  end

  def to_s
    if webauth
      webauth.attributes['DISPLAYNAME'] || webauth.login
    else
      sunetid
    end
  end

  @role_cache={}
  def roles pid
    @role_cache ||= {}
    return @role_cache[pid] if @role_cache[pid]

    resp = Dor::SearchService.query('id:"'+ pid+ '"')['response']['docs'].first || {}
    toret=[]
    #search for group based roles
    #(1) for User by sunet id
    #(2) groups actually contains the sunetid, so it is just looking at different solr fields
    #includes legacy roles that have to be translated
    ["apo_role_group_manager_t","apo_role_person_manager_t"].each do |key|
      toret << 'dor-apo-manager' if (resp[key] && (resp[key] & groups).length > 0)
    end

    known_roles.each do |role|
      ["apo_role_#{role}_t","apo_role_person_#{role}_t"].each do |key|
        toret << role if (resp[key] && (resp[key] & groups).length > 0)
      end
    end
    #store this for now, there may be several role related calls
    @role_cache[pid]=toret
    toret
  end

  #array of apos the user is allowed to view
  def known_roles
    ['dor-administrator', 'sdr-administrator', 'dor-viewer', 'sdr-viewer', 'dor-apo-creator', 'dor-apo-manager', 'dor-apo-depositor', 'dor-apo-reviewer', 'dor-apo-metadata', 'dor-apo-viewer']
  end

  def permitted_apos
    query = groups.map{|g| g.gsub(':','\:')}.join(' OR ')
    q = 'apo_role_group_manager_t:('+ query + ') OR apo_role_person_manager_t:(' + query + ')'
    known_roles.each do |role|
      q += ' OR apo_role_'+role+'_t:('+query+')'
    end
    q = 'objectType_ssim:adminPolicy' if is_admin
    resp = Dor::SearchService.query(q, {:rows => 1000, :fl => 'id', :fq => '!project_tag_ssim:"Hydrus"'})['response']['docs']
    resp.map{|doc| doc['id']}
  end

  def permitted_collections
    q = 'objectType_ssim:collection AND !project_tag_ssim:"Hydrus" '
    q+= permitted_apos.map {|pid| 'is_governed_by_ssim:"info:fedora/'+pid+'"'}.join(" OR ") unless is_admin
    result= Blacklight.solr.find({:q => q, :rows => 1000, :fl => 'id,tag_ssim,dc_title_t'}).docs

    #result = Dor::SearchService.query(q, :rows => 1000, :fl => 'id,tag_ssim,dc_title_t').docs
    result.sort! do |a,b|
      a['dc_title_t'].to_s <=> b['dc_title_t'].to_s
    end
    #puts 'qry '+result.first['dc_title_t'].encoding.inspect
    res=[['None', '']]
    res+=result.collect do |doc|
      [Array(doc['dc_title_t']).first+ ' (' + doc['id'].to_s + ')',doc['id'].to_s]
    end
    res
  end

  @groups_to_impersonate = nil
  #create a set of groups in a cookie store to allow a repository admin to see the repository as if they had a different set of permissions
  def set_groups_to_impersonate grps
    @groups_to_impersonate = grps
  end

  def groups
    return @groups_to_impersonate if @groups_to_impersonate

    perm_keys = ["sunetid:#{self.login}"]
    if webauth and webauth.privgroup.present?
      perm_keys += webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
    end

    return perm_keys
  end

  def belongs_to_listed_group? group_list
    group_list.each do |group|
      return true if self.groups.include? group
    end
    return false
  end

  #is the user a repository wide administrator
  def is_admin
    return belongs_to_listed_group? ADMIN_GROUPS
  end

  #is the user a repository wide viewer
  def is_viewer
    return belongs_to_listed_group? VIEWER_GROUPS
  end

  #is the user a repo wide manager
  def is_manager
    return belongs_to_listed_group? MANAGER_GROUPS
  end

  # The convention is for boolean is_XYZ methods to be interrogative (end in "?")
  alias_method :is_admin?,   :is_admin
  alias_method :is_viewer?,  :is_viewer
  alias_method :is_manager?, :is_manager

  def login
    if webauth
      webauth.login
    else
      sunetid
    end
  end
end
