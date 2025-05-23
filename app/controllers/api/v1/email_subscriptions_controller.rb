module Api
  module V1
    class EmailSubscriptionsController < ApplicationController
      def create
        @subscription = EmailSubscription.new(email_subscription_params)

        if @subscription.save
          render json: { message: 'Successfully subscribed to email updates' }, status: :created
        else
          render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def email_subscription_params
        params.require(:email_subscription).permit(:email, :name)
      end
    end
  end
end
