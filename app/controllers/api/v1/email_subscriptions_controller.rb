module Api
  module V1
    class EmailSubscriptionsController < ApplicationController
      include AdminAuthenticatable
      skip_before_action :authenticate_user
      skip_before_action :authenticate_admin!, only: [:create]

      def index
        @subscriptions = EmailSubscription.all
        render json: @subscriptions
      end

      def create
        @subscription = EmailSubscription.new(email_subscription_params)

        if @subscription.save
          render json: { message: 'Successfully subscribed to email updates' }, status: :created
        else
          render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @subscription = EmailSubscription.find(params[:id])
        @subscription.destroy
        head :no_content
      rescue ActiveRecord::RecordNotFound
        head :not_found
      end

      private

      def email_subscription_params
        params.require(:email_subscription).permit(:email)
      end
    end
  end
end
