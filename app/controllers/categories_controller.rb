class CategoriesController < ApplicationController
  def index
    @categories = Category.all(:order => "id")
  end

  def new
  end

  def show
    @cat = Category.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @todo }
    end
  end

  def create
    @cat = Category.new(params[:category])

    respond_to do |format|
      if @cat.save
        format.html { redirect_to(@cat, :notice => 'Todo was successfully created.') }
        format.xml  { render :xml => @cat, :status => :created, :location => @cat }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cat.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /todos/1
  # PUT /todos/1.xml
  def update
    @todo = Todo.find(params[:id])

    respond_to do |format|
      if @todo.update_attributes(params[:todo])
        format.html { redirect_to(@todo, :notice => 'Todo was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @todo.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /todos/1
  # DELETE /todos/1.xml
  def destroy
    @todo = Todo.find(params[:id])
    @todo.destroy

    respond_to do |format|
      format.html { redirect_to(todos_url) }
      format.xml  { head :ok }
    end
  end
end
