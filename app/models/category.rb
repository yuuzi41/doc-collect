class Category < ActiveRecord::Base
  has_many :attribs
  has_many :documents
end
