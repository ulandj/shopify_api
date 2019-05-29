module ShopifyAPI
  class Connection < ActiveResource::Connection
    attr_reader :response

    module ResponseCapture
      def handle_response(response)
        @response = super
      end
    end

    include ResponseCapture

    module RequestNotification
      def request(method, path, *arguments)
        super.tap do |response|
          notify_about_request(response, arguments)
        end
      rescue => e
        notify_about_request(e.response, arguments) if e.respond_to?(:response)
        raise
      end

      def notify_about_request(response, arguments)
        ActiveSupport::Notifications.instrument("request.active_resource_detailed") do |payload|
          payload[:response] = response
          payload[:data]     = arguments
        end
      end
    end

    include RequestNotification

    module RedoIfTemporaryError
      def request(*args)
        binding.pry
        super
      rescue ActiveResource::ClientError, ActiveResource::ServerError => e
        if should_retry? && e.response.class.in?([Net::HTTPTooManyRequests, Net::HTTPInternalServerError])
          if e.response.class.in?([Net::HTTPTooManyRequests])
            wait
            request *args
          else
            sleep 30
            increase_server_error_counter
            raise if server_error_counter == 10
            request *args
          end
        else
          raise
        end
      end

      def wait
        sleep 0.5
      end

      def should_retry?
        [true, nil].include? Thread.current[:retry_temporary_errors]
      end

      def increase_server_error_counter
        @server_error_counter = server_error_counter + 1
      end

      def server_error_counter
        @server_error_counter ||= 0
      end
    end

    include RedoIfTemporaryError
  end
end
