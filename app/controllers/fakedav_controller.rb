require 'builder'
require 'mime/types'
require 'uri'

# charactor reference -hack
class String
  def to_xs
    ERB::Util.html_escape(self)
  end
  def join(delim)
    self
  end
end


class FakedavController < ApplicationController
  before_filter :set_charset, :set_dav
  
  #########
#around_filter :profiler, :only => [:attrretrieve], :if => lambda{Rails.env.profiler?}
around_filter :profiler, :only => [:attrretrieve], :if => lambda{Rails.env.development?}

def profiler
  ::RubyProf.start
  yield
  result = ::RubyProf.stop
  printer = ::RubyProf::CallTreePrinter.new(result)

  path = Rails.root.join("tmp/process_time.tree")
  File.open(path, 'w') do |f|
    printer.print(f, :min_percent => 0, :print_file => true)
  end
end
  #####
  
  DefaultDate = Time.utc(2011, 4, 1)
  StrAttributeSearch = '属性絞り込み'
  StrListResults = '一覧'
  
  def set_charset
    headers['Content-Type'] = "application/xml;charset=utf-8"
  end
  def set_dav
    headers['DAV'] = "1"
  end
  
  def generate_allprop(data)
    #xml = Builder::XmlMarkup.new(:indent => 2)
    xml = Builder::XmlMarkup.new
    
	xml.instruct!
	xmlobj = xml.D(:multistatus, "xmlns:D" => "DAV:") do
	  data.each do |resps|
	    xml.D :response do
          xml.D :href, URI.escape(resps[:href])
		  xml.D :propstat do
		    xml.D :prop do
			  resps[:prop].each_pair do |k,v|
			    xml.tag!("D:#{k}") do
				  xml.text! v if v.instance_of?(String)
				  xml.tag!("D:collection") if v == true
				end
			  end
			end
			xml.D :status, "HTTP/1.1 200 OK"
		  end
	    end
	  end
	end
	xmlobj
  end
  
  def generate_propname(data)
    #xml = Builder::XmlMarkup.new(:indent => 2)
    xml = Builder::XmlMarkup.new
    
	xml.instruct!
	xmlobj = xml.multistatus("xmlns:D" => "DAV:") do
	  data.each do |resps|
	    xml.response do
          xml.D :href, URI.escape(resps[:href])
		  xml.propstat do
		    xml.prop do
			  resps[:prop].each_pair {|k,v| xml.tag!(k) }
			end
			xml.D :status, "HTTP/1.1 200 OK"
		  end
	    end
	  end
	end
	xmlobj
  end

  def generate_prop(data,querys)
    #xml = Builder::XmlMarkup.new(:indent => 2)
    xml = Builder::XmlMarkup.new
    
	xml.instruct!
	xmlobj = xml.D (:multistatus, "xmlns:D" => "DAV:") do
	  data.each do |resps|
	    xml.D :response do
          xml.D :href, URI.escape(resps[:href])
		  xml.D :propstat do
		    xml.D :prop do
			  querys.each do |k|
			    if resps[:prop].key?(k.to_sym)
				  v = resps[:prop][k.to_sym]
  			      xml.tag!("#{k}") do
				    xml.text! v if v.instance_of?(String)
				    xml.tag!("D:collection") if v == true
				  end
				end
			  end
			end
			xml.D :status, "HTTP/1.1 200 OK"
		  end
		  xml.D :propstat do
		    xml.D :prop do
			  querys.each do |k|
			    xml.tag!("#{k}") unless resps[:prop].key?(k.to_sym)
			  end
			end
			xml.D :status, "HTTP/1.1 404 Not Found"
		  end
	    end
	  end
	end
	xmlobj
  end
  
  def prop
    rendered = false

	data = [{:href => '/fakedav/', :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => 'fakedav', :resourcetype => true, :supportedlock => ''}}]
	if request.headers['HTTP_DEPTH'] == "1" then
	  Category.all.each {|c| data << {:href => "/fakedav/#{c.readname}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => c.readname, :resourcetype => true, :supportedlock => ''}}}
	end
	
	params['propfind'].each_pair do |k,v|
      case k
	  when 'allprop'
        render :xml => self.generate_allprop(data), :status => :multi_status
		rendered = true
      when 'propname'
        render :xml => self.generate_propname(data), :status => :multi_status
		rendered = true
	  when 'prop'
		render :xml => self.generate_prop(data, v.keys), :status => :multi_status
		rendered = true
	  end
	end
	render :text => '', :status => :forbidden unless rendered
  end
  
  def catprop
    rendered = false
    category = Category.find(:first, :conditions => {:readname => params[:catname]})
	
	data = [{:href => "/fakedav/#{category.readname}", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => category.readname, :resourcetype => true, :supportedlock => ''}}]
	if request.headers['HTTP_DEPTH'] == "1" then
	  data << {:href => "/fakedav/#{category.readname}/#{StrAttributeSearch}", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => StrAttributeSearch, :resourcetype => true, :supportedlock => ""}}
	  data << {:href => "/fakedav/#{category.readname}/#{StrListResults}", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => StrListResults, :resourcetype => true, :supportedlock => ""}}
	end
	
	if category.nil?
	  render :text => '', :status => :not_found
	else
      params['propfind'].each_pair do |k,v|
        case k
	    when 'allprop'
          render :xml => self.generate_allprop(data), :status => :multi_status
		  rendered = true
        when 'propname'
          render :xml => self.generate_propname(data), :status => :multi_status
		  rendered = true
	    when 'prop'
		  render :xml => self.generate_prop(data, v.keys), :status => :multi_status
		  rendered = true
	    end
	  end
      render :text => '', :status => :forbidden unless rendered
	end
  end
  
  def attrretrieve
    rendered = false
    flag = 0
    category = Category.find(:first, :conditions => {:readname => params[:catname]})
	enable_cond = ""
	condit = {}
	doc_name = ""
	abspath = ""
	rel_path = []
	dav_path = "/fakedav/#{category.readname}"
	cond_array = params[:conds].split('/')
	is_directory = true
	
	if category.nil?
	  render :text => '', :status => :not_found
	else
	  cond_array.each do |itm|
	    case flag
	    when 0
          flag = 1 if itm == StrAttributeSearch
		  flag = 10 if itm == StrListResults
	    when 1
	  	  enable_cond = itm
		  flag = 2
		when 2
	      condit[enable_cond] = itm
  		  flag = 0
	    when 10
	      doc_name = itm
		  flag = 11
	    when 11
		  itm = "" if itm == ".." ##traversal 対策
	      rel_path << itm
	  	  flag = 11
	    end
	  end
	  dav_path = "#{dav_path}/#{cond_array.join('/')}"
	  data = [{:href => dav_path, :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => cond_array.last, :resourcetype => true, :supportedlock => ''}}]
	    case flag
	    when 0
	      data << {:href => "#{dav_path}/#{StrAttributeSearch}", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => StrAttributeSearch, :resourcetype => true, :supportedlock => ""}}
	      data << {:href => "#{dav_path}/#{StrListResults}", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => StrListResults, :resourcetype => true, :supportedlock => ""}}
	    when 1
		  category.attribs.each do |attr|
		    data << {:href => "#{dav_path}/#{attr.readname}", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => attr.readname, :resourcetype => true, :supportedlock => ""}} unless condit.key?(attr.readname)
		  end
		when 2
		  attr = Attrib.find(:first, :conditions => {:readname => enable_cond})
		  if attr.nil?
			render :text => '', :status => :not_found
		    return
		  end
		  
		  DocAttrib.find(:all, :select => "distinct(value), value", :conditions => ['attrib_id = ? and value not in (?)', attr.id, condit.keys.join(',')]).each do |dattr|
		    data << {:href => "#{dav_path}/#{dattr.value}", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => dattr.value, :resourcetype => true, :supportedlock => ""}} unless condit.key?(attr.readname)
		  end
		when 10
		  category.documents.each do |doc|
		    flag = true
		    condit.each_pair do |k,v|
              flag = false if doc.doc_attrib.find(:first, :conditions => ["attribs.readname = ? and doc_attribs.value = ?", k, v], :include => :attrib).nil?
			end
			if flag
			  if doc.isdir
		        data << {:href => "#{dav_path}/#{doc.idname}", 
				  :prop => {
				    :creationdate => DefaultDate.xmlschema, 
				    :getlastmodified => DefaultDate.httpdate, 
				    :displayname => doc.idname, 
				    :resourcetype => true, :supportedlock => ""
				  }
				}
			  else
		        data << {:href => "#{dav_path}/#{doc.idname}", 
				  :prop => {
				    :creationdate => DefaultDate.xmlschema, 
					:getlastmodified => DefaultDate.httpdate,
					:displayname => doc.idname, 
					:resourcetype => false, 
					:supportedlock => "", 
					:getcontentlength => File.size("#{abspath}/#{ent}").to_s, 
					:getcontenttype => MIME::Types.type_for("#{abspath}/#{ent}")[0].to_s
				  }
				}
			  end
			end
		  end
		when 11
		  doc = Document.find(:first, :conditions => {:idname => doc_name})
		  if doc.nil?
			render :text => '', :status => :not_found
		    return
		  end
		  
		  abspath = doc.path
		  abspath = "#{abspath}/#{rel_path.join('/')}" unless rel_path.empty?
		  unless File.exist?(abspath)
            render :text => '', :status => :not_found
		    return
		  end
		  
          if File.directory?(abspath)
  	        Dir.entries(abspath).each do |ent|
  		    unless ent == "." or ent == ".."
  		        if File.directory?("#{abspath}/#{ent}")
			      data << {:href => "#{dav_path}/#{ent}", :prop => {:creationdate => File.ctime("#{abspath}/#{ent}").xmlschema, :getlastmodified => File.mtime("#{abspath}/#{ent}").httpdate, :displayname => ent, :resourcetype => true, :supportedlock => ""}}
			    else
			      data << {:href => "#{dav_path}/#{ent}", :prop => {:creationdate => File.ctime("#{abspath}/#{ent}").xmlschema, :getlastmodified => File.mtime("#{abspath}/#{ent}").httpdate, :displayname => ent, :resourcetype => false, :supportedlock => "", :getcontentlength => File.size("#{abspath}/#{ent}").to_s, :getcontenttype => MIME::Types.type_for("#{abspath}/#{ent}")[0].to_s}}
		        end
		      end
	        end
	      else
	        is_directory = false
            data = [{:href => dav_path, :prop => {:creationdate => File.ctime(abspath).xmlschema, :getlastmodified => File.mtime(abspath).httpdate, :displayname => cond_array.last, :resourcetype => false, :supportedlock => '', :getcontentlength => File.size(abspath).to_s, :getcontenttype => MIME::Types.type_for(abspath)[0].to_s}}]
          end
		else 
          render :text => '', :status => :not_found
		  return
		end

	  if request.request_method == "GET"
        headers.delete('DAV') #DAV属性は付けない
		if is_directory
          headers['Content-Type'] = "text/html;charset=utf-8"
		  @name = cond_array.last
		  @datas = data[1, data.length]
	      render :template => 'fakedav/list_directory', :status => :ok
		else
		  mime = MIME::Types.type_for(abspath)[0].to_s
          headers['Content-Type'] = "#{mime}"
		  #send_file(abspath, :type => mime, :disposition => 'inline')
		  send_file(abspath, :disposition => 'inline')
		end 
	  else #propfind
		data = [data.first] unless request.headers['HTTP_DEPTH'] == "1"

		params['propfind'].each_pair do |k,v|
		  case k
		  when 'allprop'
		    render :xml => self.generate_allprop(data), :status => :multi_status
			rendered = true
		  when 'propname'
		    render :xml => self.generate_propname(data), :status => :multi_status
		    rendered = true
		  when 'prop'
		    render :xml => self.generate_prop(data, v.keys), :status => :multi_status
		    rendered = true
	  	  end
		end
	    render :text => '', :status => :forbidden unless rendered
	  end
	end
  end
  
  def option
	render :text => ''
  end
end
