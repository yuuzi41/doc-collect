class DocAttrib < ActiveRecord::Base
  belongs_to :attrib
  belongs_to :document
end
