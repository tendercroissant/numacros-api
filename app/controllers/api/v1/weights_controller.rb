module Api
  module V1
    class WeightsController < ApplicationController
      before_action :set_weight, only: [:show, :destroy]

      def index
        page = params[:page] || 1
        per_page = [params[:per_page]&.to_i || 50, 100].min # Max 100 per page
        
        weights = @current_user.weights
                              .recent_first
                              .limit(per_page)
                              .offset((page.to_i - 1) * per_page)

        total_count = @current_user.weights.count
        
        render json: {
          weights: weights.map { |w| weight_json(w) },
          pagination: {
            current_page: page.to_i,
            per_page: per_page,
            total_count: total_count,
            total_pages: (total_count.to_f / per_page).ceil
          }
        }
      end

      def show
        render json: weight_json(@weight)
      end

      def create
        # Default recorded_at to current time if not provided
        weight_params_with_defaults = weight_params
        weight_params_with_defaults[:recorded_at] ||= Time.current
        
        @weight = @current_user.weights.build(weight_params_with_defaults)

        if @weight.save
          render json: weight_json(@weight), status: :created
        else
          render json: { errors: @weight.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @weight.destroy
        head :no_content
      end

      def latest
        latest_weight = @current_user.weights.recent_first.first
        
        if latest_weight
          render json: weight_json(latest_weight)
        else
          render json: { error: 'No weight entries found' }, status: :not_found
        end
      end

      def trend
        days = [params[:days]&.to_i || 30, 365].min # Max 1 year
        
        trend_data = Weight.trend_for_user(@current_user, days: days)
        
        # Get weight entries for the period for charting
        weights_in_period = @current_user.weights
                                        .where(recorded_at: days.days.ago..Time.current)
                                        .oldest_first

        # Calculate additional statistics
        stats = calculate_weight_statistics(weights_in_period)
        
        render json: {
          trend_kg_per_week: trend_data,
          period_days: days,
          statistics: stats,
          weights: weights_in_period.map { |w| weight_json(w) }
        }
      end

      private

      def set_weight
        @weight = @current_user.weights.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Weight entry not found' }, status: :not_found
      end

      def weight_params
        params.require(:weight).permit(:weight_kg, :recorded_at)
      end

      def weight_json(weight)
        {
          id: weight.id,
          weight_kg: weight.weight_kg,
          recorded_at: weight.recorded_at,
          weight_change_from_previous: weight.weight_change_from_previous,
          days_since_previous: weight.days_since_previous,
          created_at: weight.created_at,
          updated_at: weight.updated_at
        }
      end

      def calculate_weight_statistics(weights)
        return {} if weights.empty?

        weights_array = weights.pluck(:weight_kg)
        
        {
          count: weights.count,
          min_weight: weights_array.min,
          max_weight: weights_array.max,
          avg_weight: (weights_array.sum / weights_array.count).round(1),
          first_weight: weights.first&.weight_kg,
          last_weight: weights.last&.weight_kg,
          total_change: weights.last&.weight_kg && weights.first&.weight_kg ? 
                       (weights.last.weight_kg - weights.first.weight_kg).round(1) : nil,
          date_range: {
            start: weights.first&.recorded_at,
            end: weights.last&.recorded_at
          }
        }
      end
    end
  end
end