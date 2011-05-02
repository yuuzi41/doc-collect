class DocumentsController < ApplicationController
  def index
    @documents = Category.find(params[:category_id]).documents
  end

  def new
  end

  def create
    idname = params[:document][:idname]
    path = params[:document][:path]
    isdir = FileTest.directory?(path)
    category_id = params[:document][:category_id]
    @doc = Document.create(:idname => idname, :path => path, :isdir => isdir, :category_id => category_id)

    trs_flag = ActiveRecord::Base.transaction do
	  @doc.save!
      params[:document][:attrs].each_pair do |k,v|
        @attr = DocAttrib.create(:attrib_id => k, :document_id => @doc.id, :value => v);
		@attr.save!
      end
    end

    respond_to do |format|
      if trs_flag
#        format.html { redirect_to(@att, :notice => 'Attribute was successfully created.') }
        format.html { redirect_to :controller => 'documents', :action => 'show', :id => @doc.id }
        format.xml  { render :xml => @att, :status => :created, :location => @att }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cat.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def show
    @doc = Document.find(params[:id])
  end

#  def edit
#    @doc = Document.find(params[:id])
#  end

  # PUT /todos/1
  # PUT /todos/1.xml
  def update
    @doc = Document.find(params[:id])

    idname = params[:document][:idname]
    path = params[:document][:path]
    isdir = FileTest.directory?(path)
    category_id = params[:document][:category_id]

    trs_flag = ActiveRecord::Base.transaction do
	  @doc.update_attributes(:idname => idname, :path => path, :isdir => isdir, :category_id => category_id)
      params[:document][:attrs].each_pair do |k,v|
	    if DocAttrib.exists?(:attrib_id => k, :document_id => @doc.id)
		  @attr = DocAttrib.find(:first, :conditions => ["attrib_id = ? AND document_id = ?", k, @doc.id])
		  @attr.update_attributes(:value => v)
		else
          @attr = DocAttrib.create(:attrib_id => k, :document_id => @doc.id, :value => v);
          @attr.save!
		end
      end
    end
	
    respond_to do |format|
      if @doc.update_attributes(params[:todo])
        format.html { redirect_to :controller => 'documents', :action => 'show', :id => @doc.id }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @doc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /todos/1
  # DELETE /todos/1.xml
  def destroy
    @doc = Document.find(params[:id])
    @doc.destroy

    respond_to do |format|
      format.html { redirect_to(docs_url) }
      format.xml  { head :ok }
    end
  end
end
