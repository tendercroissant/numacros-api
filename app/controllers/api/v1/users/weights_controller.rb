class Api::V1::Users::WeightsController < ApplicationController
  include Authenticatable
  
  before_action :authenticate_user!
  before_action :set_weight, only: [:destroy]

  def index
    weights = current_user.weights.order(created_at: :desc)
    
    weights_data = weights.map do |weight|
      {
        id: weight.id,
        weight_kg: weight.weight_kg,
        recorded_at: weight.recorded_at,
        created_at: weight.created_at,
        updated_at: weight.updated_at
      }
    end

    render json: {
      message: 'Weights retrieved successfully',
      weights: weights_data,
      count: weights.count
    }, status: :ok
  end

  def create
    weight = current_user.weights.build(weight_params)
    
    if weight.save
      weight_data = {
        id: weight.id,
        weight_kg: weight.weight_kg,
        recorded_at: weight.recorded_at,
        created_at: weight.created_at,
        updated_at: weight.updated_at
      }
      
      render json: {
        message: 'Weight entry created successfully',
        weight: weight_data
      }, status: :created
    else
      render json: {
        message: 'Failed to create weight entry',
        errors: weight.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @weight.destroy
      render json: {
        message: 'Weight entry deleted successfully'
      }, status: :ok
    else
      render json: {
        message: 'Failed to delete weight entry',
        errors: @weight.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def current
    current_weight = current_user.weights.order(created_at: :desc).first
    
    if current_weight
      weight_data = {
        id: current_weight.id,
        weight_kg: current_weight.weight_kg,
        recorded_at: current_weight.recorded_at,
        created_at: current_weight.created_at,
        updated_at: current_weight.updated_at
      }
      
      render json: {
        message: 'Current weight retrieved successfully',
        weight: weight_data
      }, status: :ok
    else
      render json: {
        message: 'No weight entries found'
      }, status: :not_found
    end
  end

  private

  def set_weight
    @weight = current_user.weights.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      message: 'Weight entry not found'
    }, status: :not_found
  end

  def weight_params
    params.require(:weight).permit(:weight_kg, :recorded_at)
  end
end 