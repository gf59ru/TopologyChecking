module ErrorsHelper

  def not_found(resource, id, wordform=nil)
    raise ActionController::RoutingError.new(t 'errors.resource_not_exists', :resource => resource, :id => id)
  end

end
