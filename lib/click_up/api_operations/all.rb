# frozen_string_literal: true

module ClickUp
  module APIOperations
    module All
      def all(params={})
        execute_request(:get, index_path(params), formatted_params(params))
      end
    end
  end
end