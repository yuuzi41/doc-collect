class AttribsController < ApplicationController
  def new
  end

  def create
    @att = Attrib.create(params[:attrib])
    respond_to do |format|
      if @att.save
#        format.html { redirect_to(@att, :notice => 'Attribute was successfully created.') }
        format.html { redirect_to :controller => 'categories', :action => 'show', :id => params[:category_id] }
        format.xml  { render :xml => @att, :status => :created, :location => @att }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cat.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
  end
end
