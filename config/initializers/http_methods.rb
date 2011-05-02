ActionController::Request::HTTP_METHODS << 'propfind'
ActionController::Request::HTTP_METHODS << 'options'
ActionController::Request::HTTP_METHOD_LOOKUP = ActionController::Request::HTTP_METHODS.inject({}) { |h, m| h[m] = h[m.upcase] = m.to_sym; h }
