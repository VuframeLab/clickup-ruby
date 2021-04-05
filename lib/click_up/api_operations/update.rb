# frozen_string_literal: true

module ClickUp
  module APIOperations
    module Update
      def update(id = nil, **opts)
        params = opts.clone
        unless params.has_key?(:id) || id
          raise ParamRequiredError, "id is a required parameter.", "id"
        end
        params[:id] = id || params[:id]
        execute_request(:put, resource_path(params), formatted_params(params))
      end
    end
  end
end