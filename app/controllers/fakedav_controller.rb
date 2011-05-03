# -*- coding:utf-8 -*-

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
	xmlobj = xml.D(:multistatus, "xmlns:D" => "DAV:") do
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
	xmlobj = xml.D(:multistatus, "xmlns:D" => "DAV:") do
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
	is_directory = true

	data = [{:href => '/fakedav/', :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => 'fakedav', :resourcetype => true, :supportedlock => ''}}]
	Category.all.each do |c|
	  data << {:href => "/fakedav/#{c.readname}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => c.readname, :resourcetype => true, :supportedlock => ''}}
	end
	
    if request.request_method == "GET"
	  headers.delete('DAV') #DAV属性は付けない
	  if is_directory
	    headers['Content-Type'] = "text/html;charset=utf-8"
	    @name = 'fakedav'
	    @datas = data[1, data.length]
	    render :template => 'fakedav/list_directory', :status => :ok
	  else
	    mime = MIME::Types.type_for(abspath)[0].to_s
	    headers['Content-Type'] = "#{mime}"
	    #send_file(abspath, :type => mime, :disposition => 'inline')
	    send_file(abspath, :disposition => 'inline')
	  end 
    else #propfind
      headers['DAV'] = "1"
	  headers['Content-Type'] = "application/xml;charset=utf-8"
	  case request.headers['HTTP_DEPTH']
	  when "0" then data = [data.first]
	  when "1" then data = data
	  when "infinity" then render(:nothing => true, :status => :forbidden) and return
	  end

	  params['propfind'].each_pair do |k,v|
        case k
	    when 'allprop' then render(:xml => self.generate_allprop(data), :status => :multi_status) and return
		when 'propname' then render(:xml => self.generate_propname(data), :status => :multi_status) and return
        when 'prop' then render(:xml => self.generate_prop(data, v.keys), :status => :multi_status) and return
		end
	  end
	  render :nothing => true, :status => :forbidden
    end
  end
  
  def catprop
	params[:catname] = params[:catname].force_encoding("UTF-8-MAC").encode("UTF-8") #for macosx-client support

	is_directory = true
    category = Category.find(:first, :conditions => {:readname => params[:catname]})
	
	data = [{:href => "/fakedav/#{category.readname}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => category.readname, :resourcetype => true, :supportedlock => ''}}]
	data << {:href => "/fakedav/#{category.readname}/#{StrAttributeSearch}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => StrAttributeSearch, :resourcetype => true, :supportedlock => ''}}
	data << {:href => "/fakedav/#{category.readname}/#{StrListResults}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => StrListResults, :resourcetype => true, :supportedlock => ''}}

    if category.nil?
	  render :text => '', status => :notfound
	  return
	end
    if request.request_method == "GET"
	  headers.delete('DAV') #DAV属性は付けない
	  if is_directory
	    headers['Content-Type'] = "text/html;charset=utf-8"
	    @name = category.readname
	    @datas = data[1, data.length]
	    render :template => 'fakedav/list_directory', :status => :ok
	  else
	    mime = MIME::Types.type_for(abspath)[0].to_s
	    headers['Content-Type'] = "#{mime}"
	    #send_file(abspath, :type => mime, :disposition => 'inline')
	    send_file(abspath, :disposition => 'inline')
	  end 
    else #propfind
	  headers['DAV'] = "1"
	  headers['Content-Type'] = "application/xml;charset=utf-8"
      case request.headers['HTTP_DEPTH']
	  when "0" then data = [data.first]
	  when "1" then data = data
	  when "infinity" then render(:text => '', :status => :forbidden) and return
	  end

	  params['propfind'].each_pair do |k,v|
        case k
	    when 'allprop' then render(:xml => self.generate_allprop(data), :status => :multi_status) and return
	    when 'propname' then render(:xml => self.generate_propname(data), :status => :multi_status) and return
	    when 'prop' then render(:xml => self.generate_prop(data, v.keys), :status => :multi_status) and return 
	    end
	  end
	  render :nothing => true, :status => :forbidden
    end

  end
  
  def attrretrieve
	params[:catname] = params[:catname].force_encoding("UTF-8-MAC").encode("UTF-8") #for macosx-client support
	params[:conds] = params[:conds].force_encoding("UTF-8-MAC").encode("UTF-8") #for macosx-client support

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
	  logger.info "Category '#{params[:catname]}' not found"
	  render :nothing => true, :status => :not_found
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
	  logger.info "Flag = #{flag.to_s}"
	    case flag
	    when 0
		  data = [{:href => "#{dav_path}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => cond_array.last, :resourcetype => true, :supportedlock => ''}}]
	      data << {:href => "#{dav_path}/#{StrAttributeSearch}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => StrAttributeSearch, :resourcetype => true, :supportedlock => ""}}
	      data << {:href => "#{dav_path}/#{StrListResults}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => StrListResults, :resourcetype => true, :supportedlock => ""}}
	    when 1
	      data = [{:href => "#{dav_path}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => cond_array.last, :resourcetype => true, :supportedlock => ''}}]
		  category.attribs.each do |attr|
		    data << {:href => "#{dav_path}/#{attr.readname}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => attr.readname, :resourcetype => true, :supportedlock => ""}} unless condit.key?(attr.readname)
		  end
		when 2
		  attr = Attrib.find(:first, :conditions => {:readname => enable_cond})
		  if attr.nil?
			render :nothing => true, :status => :not_found
		    return
		  end
		  
	      data = [{:href => "#{dav_path}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => cond_array.last, :resourcetype => true, :supportedlock => ''}}]
		  DocAttrib.find(:all, :select => "distinct(value), value", :conditions => ['attrib_id = ? and value not in (?)', attr.id, condit.keys.join(',')]).each do |dattr|
		    data << {:href => "#{dav_path}/#{dattr.value}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => dattr.value, :resourcetype => true, :supportedlock => ''}} unless condit.key?(attr.readname)
		  end
		when 10
		  data = [{:href => "#{dav_path}/", :prop => {:creationdate => DefaultDate.xmlschema, :getlastmodified => DefaultDate.httpdate, :displayname => cond_array.last, :resourcetype => true, :supportedlock => ''}}]
		  category.documents.each do |doc|
		    flag = true
		    condit.each_pair do |k,v|
              flag = false if doc.doc_attrib.find(:first, :conditions => ["attribs.readname = ? and doc_attribs.value = ?", k, v], :include => :attrib).nil?
			end
			if flag
			  if doc.isdir
		        data << {:href => "#{dav_path}/#{doc.idname}/", 
				  :prop => {
				    :creationdate => File.ctime(doc.path).xmlschema, 
					:getlastmodified => File.mtime(doc.path).httpdate,
				    :displayname => doc.idname, 
				    :resourcetype => true, :supportedlock => ''
				  }
				}
			  else
		        data << {:href => "#{dav_path}/#{doc.idname}", 
				  :prop => {
				    :creationdate => File.ctime(doc.path).xmlschema, 
					:getlastmodified => File.mtime(doc.path).httpdate,
					:displayname => doc.idname, 
					:resourcetype => false, 
					:supportedlock => "", 
					:getcontentlength => File.size(doc.path).to_s, 
					:getcontenttype => MIME::Types.type_for(doc.path)[0].to_s
				  }
				}
			  end
			end
		  end
		when 11
		  logger.info "doc_name = #{doc_name}, #{doc_name.encoding}"
		  doc = Document.find(:first, :conditions => {:idname => doc_name})
		  if doc.nil?
			render :nothing => true, :status => :not_found
		    return
		  end
		  
		  abspath = "#{doc.path}#{'/' unless rel_path.empty?}#{rel_path.join('/')}"
		  logger.info "target path = #{abspath}"
		  unless File.exist?(abspath)
			logger.info "target not found"
            render :nothing => true, :status => :not_found
		    return
		  end
		  
          if File.directory?(abspath)
			logger.info "target is directory"
		    data = [{:href => "#{dav_path}/", :prop => {:creationdate => File.ctime(abspath).xmlschema, :getlastmodified => File.mtime(abspath).httpdate, :displayname => cond_array.last, :resourcetype => true, :supportedlock => ''}}]
  	        Dir.entries(abspath).each do |ent|
  		    unless ent == "." or ent == ".."
  		        if File.directory?("#{abspath}/#{ent}")
			      data << {
				    :href => "#{dav_path}/#{ent}/", 
					:prop => {
					  :creationdate => File.ctime("#{abspath}/#{ent}").xmlschema, 
					  :getlastmodified => File.mtime("#{abspath}/#{ent}").httpdate, 
					  :displayname => ent, 
					  :resourcetype => true, 
					  :supportedlock => ''
					}
				  }
			    else
			      data << {
				    :href => "#{dav_path}/#{ent}", 
					:prop => {
					  :creationdate => File.ctime("#{abspath}/#{ent}").xmlschema, 
					  :getlastmodified => File.mtime("#{abspath}/#{ent}").httpdate, 
					  :displayname => ent, 
					  :resourcetype => false, 
					  :supportedlock => "", 
					  :getcontentlength => File.size("#{abspath}/#{ent}").to_s, 
					  :getcontenttype => MIME::Types.type_for("#{abspath}/#{ent}")[0].to_s
					}
				  }
		        end
		      end
	        end
	      else
			logger.info "target is file"
	        is_directory = false
            data = [{:href => dav_path, :prop => {:creationdate => File.ctime(abspath).xmlschema, :getlastmodified => File.mtime(abspath).httpdate, :displayname => cond_array.last, :resourcetype => false, :supportedlock => '', :getcontentlength => File.size(abspath).to_s, :getcontenttype => MIME::Types.type_for(abspath)[0].to_s}}]
          end
		else 
          render :nothing => true, :status => :not_found
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
		headers['DAV'] = "1"
		headers['Content-Type'] = "application/xml;charset=utf-8"
	    case request.headers['HTTP_DEPTH']
		when "0" then data = [data.first]
		when "1" then data = data
		when "infinity" then render(:nothing => true, :status => :forbidden) and return
		end

		params['propfind'].each_pair do |k,v|
		  case k
		  when 'allprop' then render(:xml => self.generate_allprop(data), :status => :multi_status) and return
		  when 'propname' then render(:xml => self.generate_propname(data), :status => :multi_status) and return
		  when 'prop' then render(:xml => self.generate_prop(data, v.keys), :status => :multi_status) and return
	  	  end
		end
	    render :nothing => true, :status => :forbidden
	  end
	end
  end
  
  def option
    headers['DAV'] = "1"
    headers['Content-Type'] = "application/xml;charset=utf-8"
	render :nothing => true, :status => :ok
  end
end
